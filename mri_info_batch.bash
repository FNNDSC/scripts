
#!/bin/bash
#
# mri_info_batch.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

declare -i Gi_verbose=0
declare -i Gb_forceStage=1

G_LOGDIR="-x"
G_OUTSUFFIX=""
G_DIRSUFFIX=""
G_DICOMINPUTDIR="-x"
G_TOCFILE="toc.txt"

G_STAGES="1"

G_DCM_MKINDX="dcm_mkIndx.bash"

G_SYNOPSIS="

 NAME

	mri_info_batch.bash

 SYNOPSIS

	mri_info_batch.bash     -D <dicomInputDir>			\\
				[-T <tocFile>]                          \\
				[-L <logDir>]				\\
				[-v <verbosity>]			\\
				[-t <stage>] [-f]			

 DESCRIPTION

	'mri_info_batch.bash' is a thin pipe-line friendly wrapper around
        the FS utility, 'mri_info'. The main purpose of this script is to
        run 'mri_info' on the series files in a <toc.txt> file, and simply
        capturing the ouput in <logDir>.
        
        This script is typically called as a post-script when new DICOM
        data has been received, and its purpose really is to have a set of
        canned 'mri_info' dumps available for quick processing should
        any downstream app require it.


 ARGUMENTS

	-v <level> (optional)
	Verbosity level.

	-D <dicomInputDir>
	The directory containing a set of DICOM received images.

	-T <tocFile> (Optional rename, default toc.txt)
	If specified, override the Table-Of-Contents file from 'toc.txt'.
        This file MUST exist.

	-L <logDir> (Optional: Default <dicomInputDir>/mri_info)
	The directory to contain output log files from each stage of the
	pipeline, as well containing any expert option files. This will default
	to the <dicomInputDir>/log if not explicitly specified. In this case,
	once the pipeline has completed, this log directory will be copied to
	the output directory.
	
	[-t <stages>] (Optional: $G_STAGES)
	The stages to process. See STAGES section for more detail.

	[-f] (Optional: $Gb_forceStage)
	If true, force re-running a stage that has already been processed.

 STAGES

        'mri_info_batch.bash' offers the following stages:

        1 - mri_info
        Run 'mri_info'

 OUTPUT

        This script will run 'mri_info' on each series entry in <toc.txt>, 
        capturing the generated output in <logDir>/<seriesName>.txt

 PRECONDITIONS
	
	o A FreeSurfer 'std' or 'dev' environment.
        o Individual pipeline components have their own PRECONDITIONS.


 POSTCONDITIONS

        o A FreeSurfer reconstruction is performed in the relevant
	  subject directory.

 HISTORY

	12 November 209
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
# Defaults
D_whatever=

###\\\
# Function definitions
###///


function MRID_find
{
    # ARGS
    # $1                        DICOM dir
    #
    # DESC
    # Returns the MRID associated with the DICOM
    # images in the passed DICOM directory
    #

    local dicomDir=$1

    here=$(pwd)
    cd $dicomDir >/dev/null
    MRID=$(eval $G_DCM_MKINDX | grep "Patient ID" | awk '{print $3}')
    cd $here >/dev/null
    echo $MRID
}


###\\\
# Process command options
###///

while getopts v:D:T:L:ft: option ; do
	case "$option"
	in
		v) 	Gi_verbose=$OPTARG		        ;;
		D)	G_DICOMINPUTDIR=$OPTARG		        ;;
                T)      G_TOCFILE=$OPTARG                       ;;
		L)	G_LOGDIR=$OPTARG		        ;;
		f) 	Gb_forceStage=1			        ;;
		t)	G_STAGES=$OPTARG		        ;;
		\?) synopsis_show 
		    exit 0;;
	esac
done

verbosity_check
topDir=$(pwd)
echo ""
cprint  "hostname"      "[ $(hostname) ]"

statusPrint 	"Checking -D <dicomInputDir>"
if [[ "$G_DICOMINPUTDIR" == "-x" ]] ; then fatal noDicomDirArg ; fi
ret_check $?
statusPrint	"Checking on <dicomInputDir>"
dirExist_check $G_DICOMINPUTDIR|| fatal noDicomDir
cd $G_DICOMINPUTDIR >/dev/null
G_DICOMINPUTDIR=$(pwd)
cd $topDir
lprintn "<dicomInputDir>: $G_DICOMINPUTDIR"
MRID=$(MRID_find $G_DICOMINPUTDIR)
cprint "MRID" "[ $MRID ]"

statusPrint     "Checking on <tocFile>"
fileExist_check $G_TOCFILE || fatal badTOCFile

statusPrint	"Checking on <logDir>"
if [[ "$G_LOGDIR" == "-x" ]] ; then
    G_LOGDIR=${G_DICOMINPUTDIR}/mri_info${G_DIRSUFFIX}
fi
dirExist_check $G_LOGDIR "created" || mkdir $G_LOGDIR || fatal badLogDir
#G_LOGDIR=$(echo $G_LOGDIR | sed 's|/local_mount||g')

statusPrint	"Checking for SUBJECTS_DIR env variable"
b_subjectsDir=$(set | grep SUBJECTS_DIR | wc -l)
if (( !b_subjectsDir )) ; then
        fatal noSubjectsDirVar
fi
ret_check $?

REQUIREDFILES="common.bash mri_info"
for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file..."
        file_checkOnPath $file || fatal fileCheck
done

STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($topDir) $G_SELF $*" $STAMPLOG

statusPrint     "Checking which stages to process"
barr_stage=([0]=0 [1]=0 [2]=0 [3]=0 [4]=0 [5]=0)
for i in $(seq 1 1) ; do
        b_test=$(expr index $G_STAGES "$i")
        if (( b_test )) ; then b_flag="1" ; else b_flag="0" ; fi
        barr_stage[$i]=$b_flag
done
ret_check $?

DATE=$(date)

STAGE1PROC=mri_info
if (( ${barr_stage[1]} )) ; then
    statusPrint "$(date) | Processing STAGE 1 - mri_info | START" "\n"
    STAGE=1-$STAGE1PROC
    LST=$(cat $G_TOCFILE | grep \.dcm | awk '{print $2}')
    for SCAN in $LST ; do
        STAGECMD="$STAGE1PROC $SCAN"
        STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
        statusPrint "Processing $SCAN..." "\n"
        stage_run "$STAGE" "$STAGECMD" 			\
                "${G_LOGDIR}/${SCAN}.std"		\
                "${G_LOGDIR}/${SCAN}.err"		\
		"NOECHO"				\
		|| beware mri_info
    done
    statusPrint "$(date) | Processing STAGE 1 - mri_info | END" "\n"
fi

shut_down 0

