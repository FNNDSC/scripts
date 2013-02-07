#!/bin/bash

# "include" the set of common script functions
source common.bash

# Variables that can be set from command line are prefixed with 'G'
declare -i Gi_verbose=1
declare -i Gb_useExpertOptions=1
declare -i Gb_useOverrideOut=0
declare -i Gb_forceStage=1
declare -i Gb_runCluster=0
declare -i b_GE=0
declare -i b_STAGEDONE=0
declare -i Gb_useDICOMFile=0

G_LOGDIR="-x"
G_OUTDIR="/space/kaos/5/users/dicom/postproc"
G_DICOMINPUTDIR="-x"
G_DICOMINPUTFILE="-x"
G_DICOMSERIESLIST="ISO DIFFUSION TRUE AXIAL"

G_STAGES="12"

G_SYNOPSIS="

 NAME

	siemens_diffusionProcess.bash

 SYNOPSIS

       	siemens_diffusionProcess.bash					\\
				[-G]					\\
				[-D <dicomInputDir>]			\\
				[-d <dicomSeriesFile>]			\\
				[-i <bvalDir>]				\\
				[-S <dicomSeriesList>]			\\
				[-L <logDir>]				\\
				[-v <verbosity>]			\\
				[-O <outputDir>]			\\
				[-t <stage>] [-f]			\\	

 DESCRIPTION

        'siemens_diffusionProcess.bash' performs processing on diffusion
	sequences captured on Siemens machines. It's main purpose is to 
	extract a gradient table from the diffusion sequence. This 
	gradient file is saved to the <dicomInputDir> and named
	<MRID>_gradient.txt.

	The script can also be used to provide information about a
	sequence, in particular the number of b0 volumes and size
	of the gradient table.

 STAGES

	The processing is stage based, with later stages relying on
	outputs from previous stages. Some rudimentary condition checking
	is performed.

		1	-	Collect the Siemens diffusion sequence.
		2	-	Used gdcmdump to create a gradient table
		
	The design philosophy of this particular app is to only run
	stages if their preconditions are satisfied. Strictly speaking,
	it should not be necessary to explicitly call certain stages as the
	script will attempt to skip stages that have already been completed.

 EXPERT OPTIONS

	Automatic sequence detection is performed by 'dicom_seriesCollect.bash'
	and can sometimes fail to target the desired sequence. In such cases,
	create in the <logDir> a file called 'dicom_seriesCollect.bash.opt' 
	that contains '-d <sequenceFileName>' where <sequenceFileName> is
	the name of a file in the sequence to process.

 NOTE

 PRECONDITIONS

	o common.bash script source
	o dicom_seriesCollect.bash
	o NMR FreeSurfer dev environment
	o gdcmdump

 ARGUMENTS

        -v (optional)
        Verbose output.

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

	-S <dicomSeriesList> (Optional: Default $G_DICOMSERIESLIST)
	By default, this scripe will scan for any sequences in the
	<dicomInputDir> that match any of the sequences in the series list.
	This series list is an internal default, but can be overriden
	with this flag. 

	[-t <stages>] (Optional: $G_STAGES)
	The stages to process. See STAGES section for more detail.

	[-i <bvalDir>] (Optional)
	Print some output to stdout on the gradient table and b0 volumes.
	This is equivalent to running stage 3, i.e. '-t 3'.

	[-f] (Optional: $Gb_forceStage)
	If true, force re-running a stage that has already been processed.

"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///

# Actions
A_manufacturer="checking on the scanner manufacturer"
A_fileCheck="checking for a required file dependency"
A_metaLog="checking the fs_meta.bash.log file"
A_badLogDir="checking on the log directory"
A_badOutDir="checking on output directory"
A_badLogFile="checking on the log file"
A_badClusterDir="checking on the cluster directory"
A_dependencyStage="checking for a required dependency from an earlier stage"
A_stageRun="running a stage in the processing pipeline"
A_noSubjectsDirVar="checking environment"
A_noSubjectsDir="checking environment"
A_noSubjectBase="checking base subject dir"
A_noDicomDir="checking on input DICOM directory"
A_noDicomFile="checking on input DICOM directory / file"
A_noDicomDirArg="checking on -d <dicomInputDir> argument"
A_bvConvert="checking on bval/bvec tables"
A_noCollection="checking for DIFFUSION sequences"

# Error messages
EM_manufacturer="this doesn't seem to be a Siemens sequence."
EM_fileCheck="it seems that a dependency is missing."
EM_metaLog="it seems as though this stage has already run.\n\tYou can force execution with a '-f'"
EM_badLogDir="I couldn't access the <logDir>. Does it exist?"
EM_badLogFile="I couldn't access a specific log file. Does it exist?"
EM_badLogDir="I couldn't access the <clusterDir>. Does it exist?"
EM_badOutDir="I couldn't create the <outputOverride> dir."
EM_dependencyStage="it seems that a stage dependency is missing."
EM_stageRun="I encountered an error processing this stage."
EM_noSubjectsDirVar="it seems that the SUBJECTS_DIR environment var is not set."
EM_noSubjectsDir="it seems that the SUBJECTS_DIR refers to an invalid directory."
EM_noSubjectBase="I couldn't find a subject base directory."
EM_noDicomDir="I couldn't access the input DICOM dir. Does it exist?"
EM_noDicomFile="I couldn't any DICOM *dcm files. Do any exist?"
EM_noDicomDirArg="it seems as though you didn't specify a -D <dicomInputDir>."
EM_bvConvert="I couldn't find any valid tables. No gradient extraction possible."
EM_noCollection="I couldn't seem to find any valid DIFFUSION sequences."

# Error codes
EC_manufacturer=10
EC_fileCheck=11
EC_dependencyStage=12
EC_metaLog=80
EC_badLogDir=20
EC_badLogFile=21
EC_badClusterDir=22
EC_badOutDir=23
EC_stageRun=30
EC_noSubjectsDirVar=100
EC_noSubjectsDir=101
EC_noSubjectBase=102
EC_noDicomDir=50
EC_noDicomDirArg=51
EC_noDicomFile=52
EC_bvConvert=60
EC_noCollection=70

###\\\
# Function definitions
###///

function expertOpts_parse
{
    # ARGS
    # $1                        process name
    #
    # DESC
    # Checks for <processName>.opt in $G_LOGDIR.
    # If exists, read contents and return, else
    # return empty string.
    #

    local processName=$1
    local optsFile=""
    OPTS=""

    optsFile=${G_LOGDIR}/${processName}.opt
    if (( $Gb_useExpertOptions )) ; then
        if [[ -f  $optsFile ]] ; then
            OPTS=$(cat $optsFile)
        fi
    fi
    OPTS=$(printf " %s " $OPTS)
    echo "$OPTS"
}

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
    MRID=$(echo $G_DCM_MKINDX | grep Patient | awk '{print $3}')
    cd $here >/dev/null
    echo $MRID
}


###\\\
# Process command options
###///

while getopts v:D:EL:O:ft:S:i:d:G option ; do 
	case "$option"
	in
		v) 	Gi_verbose=$OPTARG		;;
		D)	G_DICOMINPUTDIR=$OPTARG		;;
		d)	Gb_useDICOMFile=1		
			G_DICOMINPUTFILE=$OPTARG	;;
		L)	G_LOGDIR=$OPTARG		;;
                O) 	Gb_useOverrideOut=1	
			G_OUTDIR=$OPTARG                ;;
		S)	G_DICOMSERIESLIST=$OPTARG	;;
		f) 	Gb_forceStage=1			;;
		t)	G_STAGES=$OPTARG		;;
		\?) synopsis_show 
		    exit 0;;
	esac
done

verbosity_check
topDir=$(pwd)

echo ""
cprint  "hostname"      "[ $(hostname) ]"

REQUIREDFILES="common.bash dicom_seriesCollect.bash gdcmdump dcm_mkIndx.bash"
for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file..."
        file_checkOnPath $file || fatal fileCheck
done

cprint "In-line gradient table fix"	"[ $Gb_fixGradientTable ]"

statusPrint 	"Checking -D <dicomInputDir>"
if [[ "$G_DICOMINPUTDIR" == "-x" ]] ; then fatal noDicomDirArg ; fi
ret_check $?
statusPrint	"Checking on <dicomInputDir>"
dirExist_check $G_DICOMINPUTDIR|| fatal noDicomDir
cd $G_DICOMINPUTDIR >/dev/null
G_DICOMINPUTDIR=$(pwd)
cd $topDir
statusPrint	"Checking on <dicomInputDir>/<dcm> file"
DICOMTOPFILE=$(ls -1 ${G_DICOMINPUTDIR}/*.dcm 2>/dev/null | head -n 1)
fileExist_check $DICOMTOPFILE || fatal noDicomFile

if (( !Gb_useOverrideOut )) ; then
	G_OUTDIR=$G_DICOMINPUTDIR/SIEMENS_DIFFUSION
else
	G_OUTDIR=$(echo "$G_OUTDIR" | tr ' ' '-' | tr -d '"')
fi

statusPrint	"Querying <dicomInputDir> for sequences"
G_DCM_MKINDX=$(dcm_mkIndx.bash -i $DICOMTOPFILE)
ret_check $?
MANUFACTURER=$(echo "$G_DCM_MKINDX" 	|\
		 grep Manu 		|\
		 awk '{for(i=2; i<=NF; i++) printf("%s ", $i); printf("\n");}')
declare -i b_SIEMENS=0
b_SIEMENS=$(echo "$MANUFACTURER" | grep -i SIEMENS | wc -l)
if (( !b_SIEMENS )) ; then fatal manufacturer ; fi

statusPrint	"Checking on <logDir>"
if [[ "$G_LOGDIR" == "-x" ]] ; then
    G_LOGDIR=${G_DICOMINPUTDIR}/log
fi
dirExist_check $G_LOGDIR "created" || mkdir $G_LOGDIR || fatal badLogDir
G_LOGDIR=$(echo $G_LOGDIR | sed 's|/local_mount||g')

statusPrint	"Checking on <outputDir>"
G_OUTDIR=$(echo "$G_OUTDIR" | tr ' ' '-')
dirExist_check $G_OUTDIR "created" || mkdir $G_OUTDIR || fatal badOutDir
cd $G_OUTDIR >/dev/null
G_OUTDIR=$(pwd)
cd $topDir
topDir=$G_OUTDIR

STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($topDir) $G_SELF $*" $STAMPLOG

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
    if (( Gb_useDICOMFile )) ; then
	TARGETSPEC="-d $G_DICOMINPUTFILE"
    else
	TARGETSPEC="-S ^${G_DICOMSERIESLIST}^"
    fi
    STAGECMD="$STAGE1PROC				\
		-v 10 -D "$G_DICOMINPUTDIR"		\
		$TARGETSPEC				\
		-L $G_LOGDIR -A	-l			\
		-O $G_OUTDIR				\
		$EXOPTS"
    STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE1PROC}.std"         \
                "${G_LOGDIR}/${STAGE1PROC}.err"         \
                "NOECHO"                                \
         || fatal stageRun
    statusPrint "$(date) | Processing STAGE 1 - Collecting input DICOM | END" "\n"
fi

# Check on the stage 1 logs to determine the actual output directory
if (( !Gb_useOverrideOut )) ; then
    LOGFILE=${G_LOGDIR}/${STAGE1PROC}.log
    statusPrint "Checking if stage 1 output log exists"
    fileExist_check $LOGFILE || fatal badLogFile
    STAGE1DIR=$(cat $LOGFILE | grep Collection | tail -n 1 	|\
		awk -F \| '{print $4}'				|\
		sed 's/^[ \t]*//;s/[ \t]*$//')
else
    STAGE1DIR="${G_OUTDIR}"
fi

if (( ! ${#STAGE1DIR} )) ; then fatal noCollection; fi

# G_OUTDIR=$(dirname $STAGE1DIR)
STAGE1OUT=$STAGE1DIR

# Stage 2
cd $G_OUTDIR
MRID=$(MRID_find $G_DICOMINPUTDIR)
STAGE2FILEBASE=${MRID}_diffusion
STAGE2IN=$STAGE1OUT
STAGE2PROC=gdcmdump
STAGE=2-$STAGE2PROC
STAGE2DIR="${G_OUTDIR}"
if (( ${barr_stage[2]} )) ; then
    statusPrint "$(date) | Processing STAGE 2 - gdcmdump | START" "\n"
    statusPrint "Checking previous stage dependencies"
    dirExist_check $STAGE2IN || fatal dependencyStage
    
    # Clear output files
    cat /dev/null >  ${STAGE2FILEBASE}.bvec
    cat /dev/null >  ${STAGE2FILEBASE}.bval
    
    DIFFUSIONDICOMS=$(ls -1 $STAGE2IN/*.dcm)
    for DIFFUSIONDICOM in $DIFFUSIONDICOMS ; do 
    	# Extract the gradient using gdcmdump
    	# !! NOTE: Please note the "-1*$1", this is negating the x-component of the gradient
    	#          that comes out of gdcmdump.  From emperical experience, this appears to
    	#          be necessary, although the reason it is necessary is not clear. !!
    	GRADIENT=$($STAGE2PROC -C $DIFFUSIONDICOM | grep DiffusionGradientDirection | grep -o "Data.*" | tr -d "Data '" | awk -F '\\' '{print -1*$1 " " $2 " " $3 }')
    	BVAL=$($STAGE2PROC -C $DIFFUSIONDICOM | grep alBValue | awk -F '= ' '{print $2}') 
    	if [[ "$GRADIENT" != "0  " && "$GRADIENT" != "-0  " ]] ; then    		
    		echo $GRADIENT >> ${STAGE2FILEBASE}.bvec
    		echo $BVAL >> ${STAGE2FILEBASE}.bval
    	else
    		echo "0 0 0" >> ${STAGE2FILEBASE}.bvec
    		echo "0" >> ${STAGE2FILEBASE}.bval    		
    	fi
    done
       
    BVAL=$(ls -1 ${STAGE2FILEBASE}.bval | head -n 1)
    BVEC=$(ls -1 ${STAGE2FILEBASE}.bvec | head -n 1)    
    if (( ! ${#BVAL}  || ! ${#BVEC} )) ; then fatal bvConvert; fi
    
    statusPrint "$(date) | Processing STAGE 2 - gdcmdump | END" "\n"
fi

STAGE2OUT=${G_OUTDIR}/${STAGE2FILEBASE}.bval
PRUNEDTABLE=${G_OUTDIR}/${MRID}_gradientTable.txt
STAGE2FILEBASE=${G_OUTDIR}/$STAGE2FILEBASE

nB0=$( cat ${STAGE2FILEBASE}.bval | sed 's/^0/X/' | grep X | wc -l)
nDir=$(cat ${STAGE2FILEBASE}.bval | sed 's/^0/X/' | grep -v X | wc -l)
nBVal=$(cat ${STAGE2FILEBASE}.bval | sed 's/^0/X/' | grep -v X | head -1)
cprint	"Gradient nDir"		"$nDir"
if (( !${#nB0} )) ; then nB0="Unknown" ; fi
cprint	"B0 Volumes"		"$nB0"
cprint  "DTI bValue"        "$nBVal"
GRADIENTTABLE=$(cat ${STAGE2FILEBASE}.bvec | tail -n $nDir)
echo "$GRADIENTTABLE" > $PRUNEDTABLE
statusPrint	"GradFile $PRUNEDTABLE" "\n"

STAGE="Normal termination"
stage_stamp "$STAGE" $STAMPLOG

printf "%40s" "Cleaning up"
shut_down 0
