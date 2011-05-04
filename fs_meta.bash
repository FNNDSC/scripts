#!/bin/bash
#
# fs_meta.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# GPL v2
#

# "include" the set of common script functions
source common.bash
source getoptx.bash

declare -i Gi_verbose=0
declare -i Gb_useExpertOptions=0
declare -i Gb_useOverrideOut=0
declare -i Gb_forceStage=0

declare -i Gb_mailAll=0
declare -i Gb_mailStd=0
declare -i Gb_mailErr=0
declare -i Gb_mailLog=0

declare -i Gb_runCluster=0

declare -i Gb_useDICOMSeries=0
declare -i Gb_useDICOMFile=0

G_LOGDIR="-x"
G_OUTDIR="/space/kaos/5/users/dicom/postproc"
G_OUTSUFFIX=""
G_DIRSUFFIX=""
G_DICOMINPUTDIR="-x"
G_DICOMINPUTFILE="-x"
G_DICOMSERIESLIST="3D SPGR;MPRAGE;t1_mpr_ns_sag_1mm_iso"
G_RECONALLARGS=""
G_CLUSTERUSER=""
G_CLUSTERNAME=seychelles
G_CLUSTERDIR=${G_OUTDIR}/${G_CLUSTERNAME}
G_SCHEDULELOG="schedule.log"
G_MIGRATEANALYSISDIR="-x"
G_MAILTO="rudolph.pienaar@childrens.harvard.edu,daniel.ginsburg@childrens.harvard.edu"

G_STAGES="123"

G_DCM_MKINDX="dcm_mkIndx.bash"

G_SYNOPSIS="

 NAME

	fs_meta.bash

 SYNOPSIS

	fs_meta.bash		-D <dicomInputDir>			\\
				[-S <dicomSeriesList>]			\\
				[-d <dicomSeriesFile>]			\\
				[-L <logDir>]				\\
				[-v <verbosity>]			\\
				[-O <outputDir>] [-o <suffix>]		\\
				[-R <DIRsuffix>]			\\
                                [-E] [-F <recon-all-args>]              \\
				[-t <stage>] [-f]			\\
				[-c] [-C <clusterName>		        \\
                                [-M | -m <mailReportsTo>]               \\
                                [-n <clusterUserName>]                  \\
                                [--migrate-analysis <migrateDir>]       \\

 DESCRIPTION

	'fs_meta.bash' is the meta shell controller/dipatcher for batch
	running of FreeSurfer processes.

	Simply stated, the script is called with a target directory containing
	DICOM files. These files are scanned for any series of specific 
	structural sequences. If any such sequences are found, the script
	copies these to a working area, and initializes a FreeSurfer
	'recon-all' stream, in a two-stage process.

	The first stage is the parsing of the <dicomInputDir> and selection
	of relevant FreeSurfer type sequences.

	The second stage is a FreeSurfer setup, and the third stage is the
	actual FreeSurfer 'recon-all'.

	Each of these 'stages' is parcelled out to a separate sub process,
	and since each of these sub processes has its own set of controlling
	scripts/options, it is not practical for this script to provide direct
	ability to set specific options on these subprocesses. Rather, 
	subprocesses can be finely controlled using the expert options flag,
	'-E'. See the EXPERT section. 

	Often times, the script is called automatically as part of a callback
	type architecture. In such cases, the input dicom directory will most
	likely also be updated with the output of this pipeline. In order to
	avoid a situation where callbacks are triggered repeatedly on the
	same dataset, this script attempts to make some provision for detecting
	when a specific DICOM sequence has already been processed.

 ARGUMENTS

	-v <level> (optional)
	Verbosity level.

	-D <dicomInputDir>
	The directory to be scanned for specific diffusion sequences. This
	script will automatically target specific data within this directory
	and start a processing pipeline.

	-d <dicomSeriesFile> (Optional)
	If specified, override the automatic sequence detection and run the
	pipeline seeded on the series containinig <dicomSeriesFile>. This
	filename is relative to the <dicomInputDir>.

	-L <logDir> (Optional: Default <dicomInputDir>/log)
	The directory to contain output log files from each stage of the
	pipeline, as well containing any expert option files. This will default
	to the <dicomInputDir>/log if not explicitly specified. In this case,
	once the pipeline has completed, this log directory will be copied to
	the output directory.

	-O <outputDir> (Optional: Default determined by stage 1)
	Directory to contain pipeline output. Usually this is self-determined
	from the logs of stage 1. However, specifying it here forces an
	override. Note that this directory will be used as the root
	for the outputs of each underlying stage.

	-o <suffix> (Optional)
	Several different datasets can map to the same MRID. By specifying
	an optional output <suffix>, a user can differentiate between 
	different processing runs on the same core MRID. For example 
	'-o _noECC' would append the text '_noECC' to each file created
	in the processing stream.
	
	-R <DIRsuffix> (Optional)
	Appends <DIRsuffix> to the postproc/<MRID> as well as <logDir>. Since
	multiple studies on the same patient can in principle have the same
	MRID, interference can result in some of the log files and source
	data. By adding this <DIRsuffix>, different analyses on the same MRID
	can be cleanly separated.

	-S <dicomSeriesList> (Optional: Default $G_DICOMSERIESLIST)
	By default, this scripe will scan for any sequences in the
	<dicomInputDir> that match any of the sequences in the series list.
	This series list is an internal default, but can be overriden
	with this flag. In the case of the FreeSurfer stream, each substring
	match in the <dicomSeriesList> found in the <dicomInputDir> is
	collected.

	[-t <stages>] (Optional: $G_STAGES)
	The stages to process. See STAGES section for more detail.

	[-f] (Optional: $Gb_forceStage)
	If true, force re-running a stage that has already been processed.

	[-E] (Optional)
	Use expert options. This script pipeline relies upon a number
	of underlying processes. Each of these processes accepts its
	own set of control options. Many of these options are not exposed
	by 'fs_meta.bash', but can be specified by passing this -E flag.
        Currently, 'dcm2trk.bash', 'track_slice.bash', 'dicom_dirSend.bash',
	and dicom_seriesCollect.bash understand the -E flag.

	To pass expert options, create (in the <logDir>) a text file of 
        the form <processName>.opt that contains additional options for
        <processName>. If found, the contents are read and also passed 
        to the <processName> as 'fs_meta.bash' executes it.

	For example, to specify a different dicom sequence to process,
	create a 'dicom_seriesCollect.bash.opt' file containing:

		-S \"3D SPGR AX-30 DEGREE\"

	Indicating that the collection stage should find and copy all
	data pertaining to the given sequence.

        [-F <recon-all-args>] (Optional)
        If specified, insert <recon-all-args> directly into the command
        line string for the recon-all process call. Useful to more directly
        control the recon-all process.

	-c 		(Optional: bool default $Gb_runCluster)
	-C <clusterName> (Optional: cluster scheduling directory)
	The '-c' indicates that the actual recon should be run on a compute
	cluster, with scheduling files stored in <outputDir>/<clusterName>
        
        The cluster file is 'schedule.log', formatted in the standard 
        stage-stamp manner. This schedule.log file is polled by a 'filewatch' 
        process running on the cluster head node, and parsed by 'pbsubdiff.sh'.

        -M | -m <mailReportsTo>
        Email the output of each sub-stage to <mailReportsTo>. Useful if
        running on a cluster and no output monitoring easily available.
        Use the small '-m' to only email the output from stdout logs; use
        capital '-M' to email stdout, stderr, and log file.
        
        -n <clusterUserName> (Optional)
        If specified, this option specified the name of the user that
        submitted the job to the cluster.  This name is added to the
        schedule.log file output for the cluster.  If not specified,
        it will be left blank.
        
        [--migrate-analysis <migrateDir>] (Optional)
        This option allows the specification of an alternative directory
        to <outputDir> where the processing occurs.  Basically what will
        happen is the input scans are copied to <migrateDir>, processing
        is done, and the files are then moved over back to the <outDir>
        when finished.  The purpose of this is to allow for use of
        cluster storage for doing processing automatically.        
        

 STAGES

        'fs_meta.bash' offers the following stages:

        1 - dicom_seriesCollect.bash
	    Collect a DICOM series from a given directory.
        2 - recon-all
	    Create/initialize directories and data.
        3 - recon-all
	    Run the recon-all stream

 OUTPUT

    	The output directory is found by parsing the log file from
	stage 1 of the pipeline. If there is no stage 1 log file, the
	output defaults to $G_OUTDIR (which can be specified by the
	user).

	In most cases, specifying an output directory is not required.
	If set, the parent directory is set as the SUBJECTS_DIR and the
	output directory becomes the specific subject. If not set, the
	postprocessing root directory becomes the SUBJECTS_DIR, and 
	the tree housing the dicoms collected becomes the subject.

 PRECONDITIONS
	
	o A FreeSurfer 'std' or 'dev' environment.
        o Individual pipeline components have their own PRECONDITIONS.


 POSTCONDITIONS

        o A FreeSurfer reconstruction is performed in the relevant
	  subject directory.

 HISTORY

	07 May 2008
	o Design and coding based off 'track_meta.bash' core.
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///

# Actions
A_fileCheck="checking for a required file dependency"
A_metaLog="checking the fs_meta.bash.log file"
A_badLogDir="checking on the log directory"
A_badLogFile="checking on the log file"
A_badClusterDir="checking on the cluster directory"
A_dependencyStage="checking for a required dependency from an earlier stage"
A_stageRun="running a stage in the processing pipeline"
A_noSubjectsDirVar="checking environment"
A_noSubjectsDir="checking environment"
A_noSubjectBase="checking base subject dir"
A_noDicomDir="checking on input DICOM directory"
A_noDicomDirArg="checking on -d <dicomInputDir> argument"
A_badMigrateDir="checking on --migrate-analysis <migrateDir>"

# Error messages
EM_fileCheck="it seems that a dependency is missing."
EM_metaLog="it seems as though this stage has already run.\n\tYou can force execution with a '-f'"
EM_badLogDir="I couldn't access the <logDir>. Does it exist?"
EM_badLogFile="I couldn't access a specific log file. Does it exist?"
EM_badLogDir="I couldn't access the <clusterDir>. Does it exist?"
EM_dependencyStage="it seems that a stage dependency is missing."
EM_stageRun="I encountered an error processing this stage."
EM_noSubjectsDirVar="it seems that the SUBJECTS_DIR environment var is not set."
EM_noSubjectsDir="it seems that the SUBJECTS_DIR refers to an invalid directory."
EM_noSubjectBase="I couldn't find a subject base directory."
EM_noDicomDir="I couldn't access the input DICOM dir. Does it exist?"
EM_noDicomDirArg="it seems as though you didn't specify a -D <dicomInputDir>."
EM_badMigrateDir="I couldn't access <migrateDir>"

# Error codes
EC_fileCheck=1
EC_dependencyStage=2
EC_metaLog=80
EC_badLogDir=20
EC_badLogFile=21
EC_badClusterDir=22
EC_stageRun=30
EC_noSubjectsDirVar=100
EC_noSubjectsDir=101
EC_noSubjectBase=102
EC_noDicomDir=50
EC_noDicomDirArg=51
EC_badMigrateDir=83

# Defaults
D_whatever=

###\\\
# Function definitions
###///

# function expertOpts_parse
# {
#     # ARGS
#     # $1                        process name
#     #
#     # DESC
#     # Checks for <processName>.opt in $G_LOGDIR.
#     # If exists, read contents and return, else
#     # return empty string.
#     #
# 
#     local processName=$1
#     local optsFile=""
#     OPTS=""
# 
#     optsFile=${G_LOGDIR}/${processName}.opt
#     if (( $Gb_useExpertOptions )) ; then
#         if [[ -f  $optsFile ]] ; then
#             OPTS=$(cat $optsFile)
#         fi
#     fi
#     OPTS=$(printf " %s " $OPTS)
#     echo "$OPTS"
# }

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

while getoptex "v: D: d: E F: L: O: R: o: f t: S: c C:  \
                n: M: m: migrate-analysis:" "$@" ; do 
	case "$OPTOPT"
	in
		v) 	Gi_verbose=$OPTARG		        ;;
		D)	G_DICOMINPUTDIR=$OPTARG		        ;;
		d)	Gb_useDICOMFile=1		
			G_DICOMINPUTFILE=$OPTARG	        ;;
		E) 	Gb_useExpertOptions=1		        ;;
                F)      G_RECONALLARGS=$OPTARG                  ;;
		L)	G_LOGDIR=$OPTARG		        ;;
		O) 	Gb_useOverrideOut=1	
		        G_OUTDIR=$OPTARG                        ;;  			
		R)      G_DIRSUFFIX=$OPTARG                     ;;
		o)	G_OUTSUFFIX=$OPTARG		        ;;
		S)	Gb_useDICOMSeries=1
			G_DICOMSERIESLIST=$OPTARG	        ;;
		f) 	Gb_forceStage=1			        ;;
		t)	G_STAGES=$OPTARG		        ;;
		c)	Gb_runCluster=1			        ;;
		C)	G_CLUSTERDIR=$OPTARG                    ;;			
                M)      Gb_mailStd=1
                        Gb_mailErr=1
                        G_MAILTO=$OPTARG                        ;;
                m)      Gb_mailStd=1
                        Gb_mailErr=0
                        G_MAILTO=$OPTARG                        ;;
                n)      G_CLUSTERUSER=$OPTARG			;;
                migrate-analysis)
                        G_MIGRATEANALYSISDIR=$OPTARG            ;;
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

statusPrint	"Checking on <logDir>"
if [[ "$G_LOGDIR" == "-x" ]] ; then
    G_LOGDIR=${G_DICOMINPUTDIR}/log${G_DIRSUFFIX}
fi
dirExist_check $G_LOGDIR "created" || mkdir $G_LOGDIR || fatal badLogDir
G_LOGDIR=$(echo $G_LOGDIR | sed 's|/local_mount||g')

if (( Gb_runCluster )) ; then
  statusPrint	"Checking on <clusterDir>"
  dirExist_check $G_CLUSTERDIR || mkdir $G_CLUSTERDIR || fatal badClusterDir
fi

if (( Gb_useOverrideOut )) ; then
    statusPrint	"Checking on <outputOverride>"
    G_OUTDIR=$(echo "$G_OUTDIR" | tr ' ' '-' | tr -d '"')
    dirExist_check $G_OUTDIR "created" || mkdir -p "$G_OUTDIR" || fatal badOutDir
    cd $G_OUTDIR >/dev/null
    G_OUTDIR=$(pwd)
    cd $topDir
fi


# If --migrate-analysis is set, then do the processing in an intermediate
# directory
if [[ "$G_MIGRATEANALYSISDIR" != "-x" ]] ; then
    statusPrint "Checking on <migrateDir>"
    G_MIGRATEANALYSISDIR=$(echo "$G_MIGRATEANALYSISDIR" | tr ' ' '-' | tr -d '"')
    dirExist_check $G_MIGRATEANALYSISDIR || mkdir "$G_MIGRATEANALYSISDIR" \
                    || fatal badMigrateDir
    cd $G_MIGRATEANALYSISDIR >/dev/null
    G_MIGRATEANALYSISDIR=$(pwd)
    migrateAnalysis_enable ${G_MIGRATEANALYSISDIR}/${MRID}${G_OUTSUFFIX} \
                           ${G_OUTDIR}/${MRID}${G_OUTSUFFIX} 
                   
    # Now, map the output directory to the migrate analysis directory
    G_OUTDIR=$G_MIGRATEANALYSISDIR
fi

statusPrint	"Checking for SUBJECTS_DIR env variable"
b_subjectsDir=$(set | grep SUBJECTS_DIR | wc -l)
if (( !b_subjectsDir )) ; then
        fatal noSubjectsDirVar
fi
ret_check $?


REQUIREDFILES="common.bash dicom_seriesCollect.bash"
for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file..."
        file_checkOnPath $file || fatal fileCheck
done

STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($topDir) $G_SELF $*" $STAMPLOG

## Check on cluster access
if (( Gb_runCluster )) ; then
  statusPrint   "Checking on <clusterDir>"
  dirExist_check $G_CLUSTERDIR || mkdir $G_CLUSTERDIR || fatal badClusterDir
  cluster_schedule "$*" "fs"
  G_STAGES=0
  STAGE="Cluster re-spawn termination"
  stage_stamp "$STAGE" $STAMPLOG
  shut_down 0
fi

statusPrint     "Checking which stages to process"
barr_stage=([0]=0 [1]=0 [2]=0 [3]=0 [4]=0 [5]=0)
for i in $(seq 1 5) ; do
        b_test=$(expr index $G_STAGES "$i")
        if (( b_test )) ; then b_flag="1" ; else b_flag="0" ; fi
        barr_stage[$i]=$b_flag
done
ret_check $?
DATE=$(date)

STAGE1PROC=dicom_seriesCollect.bash
if (( ${barr_stage[1]} )) ; then
    statusPrint "$(date) | Processing STAGE 1 - Collecting input DICOM | START" "\n"
    STAGE=1-$STAGE1PROC
    EXOPTS=$(eval expertOpts_parse $STAGE1PROC)
    if (( Gb_useOverrideOut )) ;  then
		EXOPTS="$EXOPTS -R \"$G_OUTDIR\""
    fi
    if (( Gb_useDICOMFile )) ; then
	TARGETSPEC="-d $G_DICOMINPUTFILE"
    else
	TARGETSPEC="-S ^${G_DICOMSERIESLIST}^"
    fi
    STAGECMD="$STAGE1PROC				\
		-v 10 -D "$G_DICOMINPUTDIR"		\
		$TARGETSPEC				\
                -m $G_DIRSUFFIX                         \
		-L $G_LOGDIR -A	-l			\
		$EXOPTS"
    STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    stage_run "$STAGE" "$STAGECMD" 			\
                "${G_LOGDIR}/${STAGE1PROC}.std"		\
                "${G_LOGDIR}/${STAGE1PROC}.err"		\
		"NOECHO"				\
		|| fatal stageRun
    statusPrint "$(date) | Processing STAGE 1 - Collecting input DICOM | END" "\n"
fi

# Check on the stage 1 logs to determine the actual output directory
LOGFILE=${G_LOGDIR}/${STAGE1PROC}.log
statusPrint "Checking if stage 1 output log exists"
fileExist_check $LOGFILE || fatal badLogFile
STAGE1DIR=$(cat $LOGFILE | grep Collection | tail -n 1 	|\
	awk -F \| '{print $4}'				|\
	sed 's/^[ \t]*//;s/[ \t]*$//')

if (( ! ${#STAGE1DIR} )) ; then fatal dependencyStage; fi

G_OUTDIR=$(dirname $STAGE1DIR)
lprintn "<outputDir>: $G_OUTDIR"
STAGE1OUT=$STAGE1DIR

cd $G_OUTDIR
export SUBJECTS_DIR=$(pwd)
SUBJECT=FREESURFER

# Stage 2
STAGE2PROC=recon-all
STAGE2IN=$STAGE1OUT
STAGE2OUT=${G_OUTDIR}/FREESURFER/mri/orig/001.mgz
if (( ${barr_stage[2]} )) ; then
    statusPrint "$(date) | Processing STAGE 2 - recon-all init | START" "\n"
    statusPrint "Checking stage dependencies"
    dirExist_check $STAGE2IN || fatal dependencyStage
    STAGE="2-$STAGE2PROC-initialize"
    STAGEINPUTS=$(find . -iname "*0001.dcm" 		|\
		 tr '\n' ' ' 				|\
		 awk '{for(i=1; i<=NF; i++)		\
			 {printf("-i %s ", $i);}}')
    EXOPTS=$(eval expertOpts_parse $STAGE2PROC)
    STAGECMD="recon-all $STAGEINPUTS -s $SUBJECT"
    stage_run "$STAGE" "$STAGECMD" 			\
                "${G_LOGDIR}/${STAGE2PROC}-i.std"	\
                "${G_LOGDIR}/${STAGE2PROC}-i.err"	\
		"NOECHO"				\
		|| fatal stageRun
    statusPrint "$(date) | Processing STAGE 2 - recon-all init | END" "\n"
fi

# Stage 3
STAGE3PROC=recon-all
STAGE3IN=${STAGE2OUT}
STAGE3OUT=${G_OUTDIR}/FREESURFER/surf/lh.smoothwm
if (( ${barr_stage[3]} )) ; then
    statusPrint "$(date) | Processing STAGE 3 - recon-all run | START" "\n"
    statusPrint "Checking stage dependencies"
    fileExist_check $STAGE3IN || fatal dependencyStage
    STAGE="3-$STAGE3PROC-run"
    EXOPTS=$(eval expertOpts_parse $STAGE3PROC)
    STDOUT="${G_LOGDIR}/${STAGE2PROC}-autorecon.std"
    STDERR="${G_LOGDIR}/${STAGE2PROC}-autorecon.err"
    STAGECMD="recon-all -autorecon-all $G_RECONALLARGS -s $SUBJECT"
    stage_run "$STAGE" "$STAGECMD" 				\
		$STDOUT						\
		$STDERR						\
		"NOECHO"					\
		|| fatal stageRun
    statusPrint "$(date) | Processing STAGE 3 - recon-all run | END" "\n"
fi

STAGE="Normal termination -- collecting log files"
statusPrint	"Checking final log dir"
FINALLOG=${G_OUTDIR}/log${G_DIRSUFFIX}
dirExist_check  ${G_OUTDIR}/log "created" || mkdir $FINALLOG
for EXT in "log" "err" "std" ; do
    find ${G_OUTDIR} -iname "*.$EXT" -exec cp {} $FINALLOG 2>/dev/null
done
cp ${G_LOGDIR}/* $FINALLOG
stage_stamp "$STAGE" $STAMPLOG

printf "%40s" "Cleaning up"
mail_reports "$G_MAILTO" "$Gb_mailStd" "$Gb_mailErr"
shut_down 0

