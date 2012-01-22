
#!/bin/bash
#
# mris_decimate.bash
#
# Copyright 2012 Rudolph Pienaar
# Children's Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

declare -i Gi_verbose=0
declare -i Gb_forceStage=1
declare -i Gb_skipPreviouslyCompleted=0

G_LOGDIR="-x"
G_OUTSUFFIX=""
G_DIRSUFFIX=""
G_DICOMINPUTDIR="-x"
G_TOCFILE="toc.txt"
G_DECIMATELEVEL="-x"

G_STAGES="01234"


G_SYNOPSIS="

 NAME

	mris_decimate.bash

 SYNOPSIS

	mris_decimate.bash      [-v <verbosity>]			\\
                                [-t <stages>]                           \\
                                -d <decimateLevel>                      \\
                                <SUBJ1> <SUBJ2> ... <SUBJn>

 DESCRIPTION

	'mris_decimate.bash' decimates the smoothwm surface on each <SUBJ>
        for both hemispheres. It then regenerates the inflated and spherical
        surfaces, as well as calculating relevant mris_curvature_stats 
        overlays.


 ARGUMENTS

	-v <level> (optional)
	Verbosity level.

        -d <decimateLevel>
        The fractional amount of surface decimation. A level of 0.9 implies
        output surface has 90% of original mesh count; a level of 0.1 implies
        10% of original mesh count.

        <SUBJ1> <SUBJ2> ... <SUBJn>
        Subjects to process. Assumes valid FREESURFER SUBJECTS_DIR

 STAGES

        0. Backup existing 'surf' dir
        1. Decimate
        2. Generate new inflated
        3. Generate new sphere
        4. Calculate new curvatures

        Note that each stage depends somewhat on its previous stage.

 OUTPUT

        The original 'surf' directory is backed up and a new 'surf'
        directory created, containing the new data structures.

 PRECONDITIONS
	
	o A FreeSurfer 'std' or 'dev' environment.

 POSTCONDITIONS

        o surf -> surf.org
        o new surf with new data structures

 HISTORY

	20 January 2012
	o Design and coding based off 'track_meta.bash' core.
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///

# Actions
A_fileCheck="checking for a required file dependency"
A_metaLog="checking the mri_info_batch.bash.log file"
A_badLogDir="checking on the log directory"
A_badTOCFile="checking on the Table-Of-Contents file"
A_noSubjectsDirVar="checking environment"
A_noSubjectsDir="checking environment"
A_noSubjectBase="checking base subject dir"
A_noDicomDirArg="checking on -D <dicomInputDir> directory"
A_noDicomDir="checking on input DICOM directory"
A_mri_info="running 'mri_info'"
A_noMrisStats="checking on the 'mris_curvature_stats' binary"
A_mrisStatsprocess="running the 'mris_curvature_stats' binary"
A_decimationLevel="checking the decimation level"

# Error messages
EM_fileCheck="it seems that a dependency is missing."
EM_metaLog="it seems as though this stage has already run.\n\tYou can force execution with a '-f'"
EM_badLogDir="I couldn't access the <logDir>. Does it exist?"
EM_badTOCFile="I couldn't access the Table-Of-Contents file. Does it exist?"
EM_noSubjectsDirVar="it seems that the SUBJECTS_DIR environment var is not set."
EM_noSubjectsDir="it seems that the SUBJECTS_DIR refers to an invalid directory."
EM_noDicomDirArg="You must specify a -D <dicomInputDir>."
EM_noSubjectBase="I couldn't find a subject base directory."
EM_noDicomDir="I couldn't access the input DICOM dir. Does it exist?"
EM_mri_info="some error occurred in the spawned process."
EM_noMrisStats="I can't find the file on your current path."
EM_mrisStatsprocess="the program died unexpectedly."
EM_decimationLevel="no decimation leve was specified! Valid: [0.0 ... 1.0]."

# Error codes
EC_fileCheck=1
EC_dependencyStage=2
EC_metaLog=80
EC_badLogDir=20
EC_badTOCFile=21
EC_noSubjectsDirVar=100
EC_noSubjectsDir=101
EC_noSubjectBase=102
EC_noDicomDir=50
EC_noDicomDirArg=51
EC_mri_info=60
EC_noMrisStats=90
EC_mrisStatsprocess=100
EC_decimationLevel=101

# Defaults
D_whatever=

###\\\
# Function definitions
###///


###\\\
# Process command options
###///

while getopts v:t:d:t: option ; do
	case "$option"
	in
		v) 	Gi_verbose=$OPTARG		        ;;
                t)      G_STAGES=$OPTARG                        ;;
                d)      G_DECIMATELEVEL=$OPTARG                 ;;
                t)      G_STAGES=$OPTARG                        ;;
		\?) synopsis_show 
		    exit 0;;
	esac
done

verbosity_check
topDir=$(pwd)
echo ""
cprint  "hostname"      "[ $(hostname) ]"

statusPrint     "Checking decimation level"
[[ $G_DECIMATELEVEL == "-x" ]] && fatal decimationLevel 
rprint "[ $G_DECIMATELEVEL ]"

statusPrint	"Checking for SUBJECTS_DIR env variable"
b_subjectsDir=$(set | grep SUBJECTS_DIR | wc -l)
if (( !b_subjectsDir )) ; then
        fatal noSubjectsDirVar
fi
ret_check $?

REQUIREDFILES="common.bash mris_decimate mris_inflate mris_sphere mris_curvature_stats"
for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file"
        file_checkOnPath $file || fatal fileCheck
done

if [[ $G_LOGDIR == "-x" ]] ; then G_LOGDIR=$(pwd) ; fi

STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($topDir) $G_SELF $*" $STAMPLOG

ALLARGS=$*
shift $(($OPTIND - 1))
SUBJECTLIST=$*
b_SUBJECTLIST=$(echo $SUBJECTLIST| wc -w)
if (( b_SUBJECTLIST )) ; then
        SUBJECTS=$SUBJECTLIST
fi

statusPrint     "Checking which stages to process"
barr_stage=([0]=0 [1]=0 [2]=0 [3]=0 [4]=0 [5]=0 [6]=0 [7]=0 [8]=0 [9]=0 [10]=0 [11]=0 [12]=0)
for i in $(seq 0 4) ; do
        b_test=$(expr index $G_STAGES "$i")
        if (( b_test )) ; then b_flag="1" ; else b_flag="0" ; fi
        barr_stage[$i]=$b_flag
done
ret_check $?

statusPrint     "Checking <subjectList> in SUBJECTS_DIR" "\n"
for SUBJ in $SUBJECTS ; do
        statusPrint "$SUBJ"
        dirExist_check ${SUBJECTS_DIR}/$SUBJ/ || fatal noSubjectBase
done

DATE=$(date)
cprint     "date"  "[ $DATE ]"

for SUBJ in $SUBJECTS ; do

    if (( ${barr_stage[0]} )) ; then
        G_LOGDIR=$(pwd)
        statusPrint "$(date) | Processing STAGE 0 - backup $SUBJ/surf | START" "\n"
        if [[ -d ${SUBJECTS_DIR}/${SUBJ}/surf.bak ]] ; then
            mv ${SUBECTS_DIR}/${SUBJ}/surf.bak ${SUBJECTS_DIR}/${SUBJ}/surf.bak-${G_PID}
        fi
        mv ${SUBJECTS_DIR}/${SUBJ}/surf ${SUBJECTS_DIR}/${SUBJ}/surf.bak
        mkdir ${SUBJECTS_DIR}/${SUBJ}/surf
        statusPrint "$(date) | Processing STAGE 0 - backup $SUBJ/surf | END" "\n"
    fi

    STAGE1PROC=mris_decimate
    if (( ${barr_stage[1]} )) ; then
        cd ${SUBJECTS_DIR}/${SUBJ}
        G_LOGDIR=$(pwd)/surf
        statusPrint "$(date) | Processing STAGE 1 - mris_decimate | START" "\n"
        STAGE=1-$STAGE1PROC
        for HEMI in lh rh ; do
            STAGECMD="$STAGE1PROC -d $G_DECIMATELEVEL surf.bak/${HEMI}.smoothwm surf/${HEMI}.smoothwm"
            STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
            statusPrint "Processing $HEMI..." "\n"
            stage_run "$STAGE" "$STAGECMD" 			\
                    "${G_LOGDIR}/${STAGE1PROC}-$HEMI-$SUBJ.std"	\
                    "${G_LOGDIR}/${STAGE1PROC}-$HEMI-$SUBJ.err"	\
                    "NOECHO"				        \
                    || beware $STAGE1PROC
        done
        statusPrint "$(date) | Processing STAGE 1 - mri_info | END" "\n"
        cd $topDir
    fi

    STAGE2PROC=mris_inflate
    if (( ${barr_stage[2]} )) ; then
        cd ${SUBJECTS_DIR}/${SUBJ}
        statusPrint "$(date) | Processing STAGE 2 - mris_inflate | START" "\n"
        STAGE=2-$STAGE2PROC
        for HEMI in lh rh ; do
            STAGECMD="$STAGE2PROC surf/${HEMI}.smoothwm surf/${HEMI}.inflated"
            STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
            statusPrint "Processing $HEMI..." "\n"
            stage_run "$STAGE" "$STAGECMD"                      \
                    "${G_LOGDIR}/${STAGE2PROC}-$HEMI-$SUBJ.std" \
                    "${G_LOGDIR}/${STAGE2PROC}-$HEMI-$SUBJ.err" \
                    "NOECHO"                                    \
                    || beware $STAGE2PROC
        done
        statusPrint "$(date) | Processing STAGE 2 - mris_inflate | END" "\n"
        cd $topDir
    fi

    STAGE3PROC=mris_sphere
    if (( ${barr_stage[3]} )) ; then
        cd ${SUBJECTS_DIR}/${SUBJ}
        G_LOGDIR=$(pwd)/surf
        statusPrint "$(date) | Processing STAGE 3 - mris_sphere | START" "\n"
        STAGE=3-$STAGE3PROC
        for HEMI in lh rh ; do
            STAGECMD="$STAGE3PROC surf/${HEMI}.inflated surf/${HEMI}.sphere"
            STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
            statusPrint "Processing $HEMI..." "\n"
            stage_run "$STAGE" "$STAGECMD"                      \
                    "${G_LOGDIR}/${STAGE3PROC}-$HEMI-$SUBJ.std" \
                    "${G_LOGDIR}/${STAGE3PROC}-$HEMI-$SUBJ.err" \
                    "NOECHO"                                    \
                    || beware $STAGE3PROC
        done
        statusPrint "$(date) | Processing STAGE 3 - mris_sphere | END" "\n"
        cd $topDir
    fi

    STAGE4PROC=mris_curvature_stats
    if (( ${barr_stage[4]} )) ; then
        cd ${SUBJECTS_DIR}/${SUBJ}
        G_LOGDIR=$(pwd)/surf
        statusPrint "$(date) | Processing STAGE 4 - mris_curvature_stats | START" "\n"
        STAGE=4-$STAGE4PROC
        for HEMI in lh rh ; do
          for SURF in smoothwm inflated ; do
            STAGECMD="$STAGE4PROC -F $SURF -G --writeCurvatureFiles $SUBJ $HEMI"
            STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
            statusPrint "Processing $HEMI $SURF..." "\n"
            stage_run "$STAGE" "$STAGECMD"                      \
                    "${G_LOGDIR}/${STAGE4PROC}-$HEMI-$SURF-$SUBJ.std" \
                    "${G_LOGDIR}/${STAGE4PROC}-$HEMI-$SURF-$SUBJ.err" \
                    "NOECHO"                                    \
                    || beware $STAGE4PROC
          done
        done
        statusPrint "$(date) | Processing STAGE 4 - mris_curvature_stats | END" "\n"
        cd $topDir
    fi

done

shut_down 0

