#!/bin/bash
#
# fetal_meta.bash
#
# Copyright 2010 Dan Ginsburg
# Children's Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

declare -i Gi_verbose=0
declare -i Gb_useExpertOptions=1
declare -i Gb_useOverrideOut=0
declare -i Gb_forceStage=0
declare -i Gb_runMatlabRemotely=0

declare -i Gb_mailAll=0
declare -i Gb_mailStd=0
declare -i Gb_mailErr=0
declare -i Gb_mailLog=0

declare -i Gb_runCluster=0

declare -i Gb_useDICOMFile=0


G_LOGDIR="-x"
G_OUTDIR="/space/kaos/5/users/dicom/postproc"
G_OUTSUFFIX=""
G_DIRSUFFIX=""
G_DICOMINPUTDIR="-x"
G_DICOMINPUTFILE="-x"
G_DICOMSERIESLIST="DIFFUSION_HighRes;ISO DIFFUSION TRUE AXIAL"
G_GRADIENTFILE="-x"
G_MATLABSERVER="-x"

G_CLUSTERNAME=launchpad
G_CLUSTERDIR=${G_OUTDIR}/${G_CLUSTERNAME}
G_SCHEDULELOG="schedule.log"
G_MAILTO="rudolph.pienaar@childrens.harvard.edu,daniel.ginsburg@childrens.harvard.edu"

G_STAGES="123"

G_SLICE_SELECTION="0.5"
G_MARGIN="5"
G_HEAD_CIRCUMFERENCE="25"

G_CLUSTERUSER=""

G_SYNOPSIS="

 NAME

        fetal_meta.bash

 SYNOPSIS

        fetal_meta.bash         -D <dicomInputDir>                      \\
                                [-S <dicomSeriesList>]                  \\
                                [-d <dicomSeriesFile>]                  \\
                                [-L <logDir>]                           \\
                                [-v <verbosity>]                        \\
                                [-O <outputDir>] [-o <suffix>]          \\
                                [-R <DIRsuffix>]                        \\
                                [-E]                                    \\
                                [-U]                                    \\
                                [-t <stage>]                            \\
                                [-c] [-C <clusterDir>]                  \\
                                [-M | -m <mailReportsTo>]               \\
                                [-n <clusterUserName>]                  \\
                                [-r <matlabServerName>]                 \\
                                [-s <sliceNum>]                         \\
                                [-H <headCircumference>]                \\
                                [-g <margin>]

 DESCRIPTION

        'fetal_meta.bash' is the meta shell controller for a (semi) automated
        fetal brain extraction pipeline.

        Simply stated, the script is called with a target directory containing
        DICOM files. These files are scanned for any series of specific 
        diffusion sequences. If any such sequences are found, the script starts
        a pipeline process that performs a tractography reconstruction, slices 
        the resultant into a set of images, converts these back to DICOM and 
        transmits these to a target server.

        Each of these 'stages' is parcelled out to a separate sub process,
        and since each of these sub processes has its own set of controlling
        scripts/options, it is not practical for this script to provide direct
        ability to set specific options on these subprocesses. Rather, 
        subprocesses can be finely controlled using the expert options flag,
        '-E'. See the EXPERT section. t options files.

        Often times, the script is called automatically as part of a callback
        type architecture. In such cases, the input dicom directory will most
        likely also be updated with the output of this pipeline. In order to
        avoid a situation where callbacks are triggered repeatedly on the
        same dataset, this script attempts to make some provision for detecting
        when a specific DICOM sequence has already been processed.

 ARGUMENTS

        -v <level> (Optional)
        Verbosity level. A value of '10' is a good choice here.

        -D <dicomInputDir>
        The directory to be scanned for specific diffusion sequences. This
        script will automatically target specific data within this directory
        and start a processing pipeline.

        -U (Optional)
        If specified, do NOT use 'diff_unpack' to convert from original
        DICOM data to nifti format. By default, the script will attempt
        to create a final trackvis trk file using the same components as
        the front end diffusion toolkit. In some cases better dcm to nifti
        conversion is possible using 'mri_convert' (for Siemens) or 
        'dcm2nii'(for GE). To use these alternatives, specifiy a '-U'.

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
        with this flag. In the case of the tractography stream, the first 
        substring match in the <dicomSeriesList> found in the <dicomInputDir> 
        is collected.

        [-t <stages>] (Optional: $G_STAGES)
        The stages to process. See STAGES section for more detail.

        [-f] (Optional: $Gb_forceStage)
        If true, force re-running a stage that has already been processed.

        [-E] (Optional)
        Use expert options. This script pipeline relies upon a number
        of underlying processes. Each of these processes accepts its
        own set of control options. Many of these options are not exposed
        by 'tract_meta.bash', but can be specified by passing this -E flag.
        Currently, 'dcm2trk.bash', 'tract_slice.bash', 'dicom_dirSend.bash',
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

        -c              (Optional: bool default $Gb_runCluster)
        -C <clusterDir> (Optional: cluster scheduling directory)
        The '-c' indicates that the actual recon should be run on a compute
        cluster, with scheduling files stored in <clusterDir>. The cluster
        file is 'schedule.log', formatted in the standard stage-stamp manner.
        This schedule.log file is polled by a 'filewatch' process running
        on seychelles, and parsed by 'pbsubdiff.sh'.
        
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
        
        -r <matlabServerName> (Optional)
        If specified, this option specified the name of server to remotely
        run matlab on using ssh.  Note that in order for this to work without 
        stopping to prompt for passwords, seamless logins must be setup using 
        ssh-keygen and authorized_keys.
        
        -s <sliceNum> (Optional)
        If specified, this option specified the slice [0.0, 1.0] to use for
        region extraction.  The default is 0.5, which for example if there were
        50 slices would use the 25th[50*0.5] slice.
        
        -H <headCircumference> (Optional)
        If specified, this option specified the head circumference in (cm).  The
        default is 25 which is the mean for GA 27 weeks.
        
        -g <margin> (Optional)
        If specified, this option provides the margin in voxels around the
        extracted region (default: 5).
        
STAGES

        'fetal_meta.bash' offers the following stages:

        1 - dicom_seriesCollect.bash
                Collect a DICOM series from a given directory.
        2 - mri_convert
                Convert the series to an NiFTi nii file 
        3 - (MatLAB) fetalbrain_extract
                Extract Fetal brain from MRI

 OUTPUT
        Each processing stage has its own set of inputs and outputs. Typically
        the outputs from one stage become the inputs to a subsequent stage.

        As a whole, this processing pipelie has one main of output:

        1. A segmented .hdr/.img file that contains the fetal extracted MRI data

 PRECONDITIONS
        
        o In your MatLAB path, you need to have /chb/matlab, for example add
          to your startup.m:
          	
          	path(path,'/chb/matlab')
            addpath_recurse('/chb/matlab')
            
        o A FreeSurfer 'std' or 'dev' environment.        
        o Individual pipeline components have their own PRECONDITIONS.


 POSTCONDITIONS

        o Each stage (and substages) including intermediary data
          is housed in its own directory, called 'stage-X-<stageName>'

        o For the case of the full pipeline, the remote DICOM server
          will have a new 'study' containing flat DICOM images of the
          reconstructed tractography.

 SEE ALSO

        o fs_meta.bash -- functionally similar pipeline geared for
          FreeSurfer processing.

 HISTORY

        2 March 2010
        o Initial design and coding.
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///

# Actions
A_fileCheck="checking for a required file dependency"
A_metaLog="checking the fetal_meta.bash.log file"
A_badLogDir="checking on the log directory"
A_badLogFile="checking on the log file"
A_dependencyStage="checking for a required dependency from an earlier stage"
A_stageRun="running a stage in the processing pipeline"
A_mri_info="running 'mri_info'"
A_noMatlab="checking for MatLAB"
A_noDicomDir="checking on input DICOM directory"
A_noDicomFile="checking on input DICOM directory / file"
A_noDicomDirArg="checking on -d <dicomInputDir> argument"

# Error messages
EM_fileCheck="it seems that a dependency is missing."
EM_metaLog="it seems as though this stage has already run.\n\tYou can force execution with a '-f'"
EM_badLogDir="I couldn't access the <logDir>. Does it exist?"
EM_badLogFile="I couldn't access a specific log file. Does it exist?"
EM_dependencyStage="it seems that a stage dependency is missing."
EM_stageRun="I encountered an error processing this stage."
EM_mri_info="I encountered an error while running this binary."
EM_noGradientFile="I couldn't access the file. Does it exist? Do you have access rights?"
EM_noMatlab="I couldn't find MatLAB. Only Linux and intel Macs are supported. You might need to edit this script."
EM_noDicomDir="I couldn't access the input DICOM dir. Does it exist?"
EM_noDicomFile="I couldn't find any DICOM *dcm files. Do any exist?"
EM_noDicomDirArg="it seems as though you didn't specify a -D <dicomInputDir>."

# Error codes
EC_fileCheck=1
EC_dependencyStage=2
EC_metaLog=80
EC_badLogDir=20
EC_badLogFile=21
EC_stageRun=30
EC_mri_info=40
EC_noGradientFile=41
EC_noMatlab=42
EC_noDicomDir=50
EC_noDicomDirArg=51
EC_noDicomFile=52

# Defaults
D_whatever=

###\\\
# Function definitions
###///

function mail_reports
{
   # ARGS
   #
   # DESC
   # Depending on the Gb_mail set of "class" variables,
   # email reports to specified user(s).
   #
    
    if (( Gb_mailStd )) ; then
        if [[ -f ${G_LOGDIR}/${G_SELF}.std ]] ; then
            cp ${G_LOGDIR}/${G_SELF}.std ${G_LOGDIR}/${G_SELF}.std.mail
            mail -s "stdout: ${G_SELF}" $G_MAILTO < ${G_LOGDIR}/${G_SELF}.std.mail
        fi
    fi
    if (( Gb_mailErr )) ; then
        if [[ -f ${G_LOGDIR}/${G_SELF}.err ]] ; then
            cp ${G_LOGDIR}/${G_SELF}.err ${G_LOGDIR}/${G_SELF}.err.mail
            mail -s "stderr: ${G_SELF}" $G_MAILTO < ${G_LOGDIR}/${G_SELF}.err.mail
        fi
    fi
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

function cluster_schedule
{
    # ARGS
    # $1                        original script command line args
    #
    # DESC
    # Creates a custom script in the G_LOGDIR that is essentially
    # the original command line. Once scheduled, termination of this
    # script ceases, and it is "re-spawned" on the cluster.
    #
    
    # Setup the command line args (stripping the -c)
    COMARGS=$(echo $1 | sed 's|-c||')
    # Create mini-script to run on cluster and add to schedule.log
    STAGE="0-cluster_schedule"
    STAGECMD="$G_SELF $COMARGS -f                        >\
                    ${G_LOGDIR}/${G_SELF}.std           2>\
                    ${G_LOGDIR}/${G_SELF}.err"
    STAGECMD=$(echo $STAGECMD | sed 's|/local_mount||g')
    CLUSTERSH=${G_LOGDIR}/fetal-cluster.sh
    echo "#!/bin/bash"                                  > $CLUSTERSH
    echo "export PATH=$PATH"                            >> $CLUSTERSH
    echo "source $FREESURFER_HOME/SetUpFreeSurfer.sh" >>$CLUSTERSH
    echo "source $FSL_DIR/etc/fslconf/fsl.sh" >> $CLUSTERSH
    echo "export SUBJECTS_DIR=$SUBJECTS_DIR"            >> $CLUSTERSH    
    echo "$STAGECMD"                                    >> $CLUSTERSH
    chmod 755 $CLUSTERSH
    STAGECMD="${G_LOGDIR}/fetal-cluster.sh"
    STAGECMD=$(echo $STAGECMD | sed 's|/local_mount||g')
    stage_stamp "$STAGECMD" ${G_CLUSTERDIR}/$G_SCHEDULELOG "$G_CLUSTERUSER"
    stage_stamp "$STAGE Schedule for cluster" $STAMPLOG
    stage_stamp "$STAGE" $STAMPLOG
    
    # Also append to output of XML file used by web front end
    LINENUMBER=$(wc -l "${G_CLUSTERDIR}/$G_SCHEDULELOG")
    cluster_genXML.bash -f ${G_CLUSTERDIR}/$G_SCHEDULELOG -l ${LINENUMBER} >> "${G_CLUSTERDIR}/$G_SCHEDULELOG.xml"
}



###\\\
# Process command options
###///

while getopts v:D:d:EL:O:R:o:S:ft:cC:M:m:n:r:s:H:g: option ; do
    case "$option"
        in
        v)      Gi_verbose=$OPTARG              ;;
        D)      G_DICOMINPUTDIR=$OPTARG         ;;
        d)      Gb_useDICOMFile=1
                G_DICOMINPUTFILE=$OPTARG    ;;
        E)      Gb_useExpertOptions=1           ;;
        L)      G_LOGDIR=$OPTARG                ;;
        O)      Gb_useOverrideOut=1
                G_OUTDIR=$OPTARG
                G_CLUSTERDIR=${G_OUTDIR}/${G_CLUSTERNAME}        ;;
        R)  	G_DIRSUFFIX=$OPTARG             ;;
        o)      G_OUTSUFFIX=$OPTARG             ;;
        S)      G_DICOMSERIESLIST=$OPTARG       ;;
        f)      Gb_forceStage=1                 ;;
        t)      G_STAGES=$OPTARG                ;;
        c)      Gb_runCluster=1                 ;;
        C)      G_CLUSTERNAME=$OPTARG
            	G_CLUSTERDIR=${G_OUTDIR}/${G_CLUSTERNAME}       ;;
        M)      Gb_mailStd=1
                Gb_mailErr=1
                G_MAILTO=$OPTARG                ;;
        m)      Gb_mailStd=1
                Gb_mailErr=0
                G_MAILTO=$OPTARG                ;;
        n)      G_CLUSTERUSER=$OPTARG           ;;
        r)      Gb_runMatlabRemotely=1
                G_MATLABSERVER=$OPTARG          ;;
        s)      G_SLICE_SELECTION=$OPTARG       ;;
        g)      G_MARGIN=$OPTARG                ;;
        H)      G_HEAD_CIRCUMFERENCE=$OPTARG    ;;                
        \?)     synopsis_show
                exit 0;;
    esac
done

verbosity_check
topDir=$(pwd)
echo ""
cprint  "hostname"      "[ $(hostname) ]"

      ## Check on script preconditions
REQUIREDFILES="common.bash dcm_mkIndx.bash \
                dicom_seriesCollect.bash mri_convert"       

for file in $REQUIREDFILES ; do
    printf "%40s"   "Checking for $file"
    file_checkOnPath $file || fatal fileCheck
done

## Check on input directory and files
statusPrint     "Checking -D <dicomInputDir>"
if [[ "$G_DICOMINPUTDIR" == "-x" ]] ; then fatal noDicomDirArg ; fi
ret_check $?
statusPrint     "Checking on <dicomInputDir>"
dirExist_check $G_DICOMINPUTDIR || fatal noDicomDir
cd $G_DICOMINPUTDIR >/dev/null
G_DICOMINPUTDIR=$(pwd)
cd $topDir
lprintn "<dicomInputDir>: $G_DICOMINPUTDIR"
statusPrint     "Checking on <dicomInputDir>/<dcm> file"
DICOMTOPFILE=$(ls -1 ${G_DICOMINPUTDIR}/*1.dcm 2>/dev/null | head -n 1)
fileExist_check $DICOMTOPFILE || fatal noDicomFile

## Check on DICOM meta data
statusPrint	"Querying <dicomInputDir> for sequences"
G_DCM_MKINDX=$(dcm_mkIndx.bash -i $DICOMTOPFILE)
ret_check $?

MRID=$(MRID_find $G_DICOMINPUTDIR)
cprint          "MRID"          "[ $MRID ]"


## Log directory
statusPrint     "Checking on <logDir>"
if [[ "$G_LOGDIR" == "-x" ]] ; then
    G_LOGDIR=${G_DICOMINPUTDIR}/log${G_DIRSUFFIX}
fi
dirExist_check $G_LOGDIR "created" || mkdir $G_LOGDIR || fatal badLogDir
G_LOGDIR=$(echo $G_LOGDIR | sed 's|/local_mount||g')

## Any output dir overrides?
if (( Gb_useOverrideOut )) ; then
    statusPrint "Checking on <outputOverride>"
    G_OUTDIR=$(echo "$G_OUTDIR" | tr ' ' '-' | tr -d '"')
    dirExist_check $G_OUTDIR || mkdir "$G_OUTDIR" || fatal badOutDir
    cd $G_OUTDIR >/dev/null
    G_OUTDIR=$(pwd)
fi
topDir=$G_OUTDIR
cd $topDir

## Main processing start
STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($topDir) $G_SELF $*" $STAMPLOG

## Check on cluster access
if (( Gb_runCluster )) ; then
    statusPrint "Checking on <clusterDir>"
    dirExist_check $G_CLUSTERDIR || mkdir $G_CLUSTERDIR || fatal badClusterDir
    cluster_schedule "$*"
    G_STAGES=0
    STAGE="Cluster re-spawn termination"
    stage_stamp "$STAGE" $STAMPLOG
    shut_down 0
fi

## Check which stages to process
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
    TARGETSPEC=""
    if (( Gb_useDICOMFile )) ; then
        TARGETSPEC="-d $G_DICOMINPUTFILE"
    else
        TARGETSPEC="-S ^${G_DICOMSERIESLIST}^"
    fi
    STAGECMD="$STAGE1PROC                               \
                -v 10 -D "$G_DICOMINPUTDIR"             \
                $TARGETSPEC                             \
                -m $G_DIRSUFFIX                         \
                -L $G_LOGDIR -A -l                      \
               $EXOPTS"
    STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    stage_run "$STAGE" "$STAGECMD"                      \
        "${G_LOGDIR}/${STAGE1PROC}.std"         \
        "${G_LOGDIR}/${STAGE1PROC}.err"         \
        || fatal stageRun
    statusPrint "$(date) | Processing STAGE 1 - Collecting input DICOM | END" "\n"
fi

# Check on the stage 1 logs to determine the actual output directory
LOGFILE=${G_LOGDIR}/${STAGE1PROC}.log
statusPrint "Checking if stage 1 output log exists"
fileExist_check $LOGFILE || fatal badLogFile
STAGE1DIR=$(cat $LOGFILE | grep Collection | tail -n 1  |\
               awk -F \| '{print $4}'                           |\
               sed 's/^[ \t]*//;s/[ \t]*$//')

if (( ! ${#STAGE1DIR} )) ; then fatal dependencyStage; fi

G_OUTDIR=$(dirname $STAGE1DIR)
STAGE1OUT=$STAGE1DIR

# Stage 2
STAGE2IN=$STAGE1OUT
STAGE2PROC=mri_convert
STAGE=2-$STAGE2PROC
STAGE2DIR="${G_OUTDIR}/fetal_meta-stage-$STAGE"
STAGE2OUT=${STAGE2DIR}/${MRID}${G_OUTSUFFIX}.nii
if (( ${barr_stage[2]} )) ; then
    statusPrint "$(date) | Processing STAGE 2 - mri_convert | START" "\n"
    statusPrint "Checking previous stage dependencies"    
    dirExist_check $STAGE2IN || fatal dependencyStage
    
    dirExist_check $STAGE2DIR "created" || mkdir $STAGE2DIR
    
    FETALDICOM=$(ls -1 $STAGE2IN | head -n 1)    
    EXOPTS=$(eval expertOpts_parse mri_convert)
    STAGECMD="UNPACK_MGH_DTI=0 mri_convert		\
                -ot nii                         \
                $EXOPTS                         \
                $STAGE2IN/$FETALDICOM           \
                ${STAGE2OUT}"
    stage_run "$STAGE" "$STAGECMD"               \
                "${STAGE2DIR}/${STAGE2PROC}.std" \
                "${STAGE2DIR}/${STAGE2PROC}.err" \
                "NOECHO"                         \
         || fatal stageRun    
fi

# Stage 3
STAGE3IN=$STAGE2OUT
STAGE3PROC=fetal_extract
STAGE=3-$STAGE3PROC
STAGE3DIR="${G_OUTDIR}/fetal_meta-stage-$STAGE"
if (( ${barr_stage[3]} )) ; then
    statusPrint "$(date) | Processing STAGE 3 - fetal_extract | START" "\n"
    statusPrint "Checking previous stage dependencies"
    fileExist_check $STAGE3IN || fatal dependencyStage
       
    dirExist_check $STAGE3DIR "created" || mkdir $STAGE3DIR
    
       
    REMOTESSH_PREFIX=""
    REMOTESSH_POSTFIX=""
    if (( Gb_runMatlabRemotely )) ; then
    	REMOTESSH_PREFIX="ssh ${G_MATLABSERVER} \""
        REMOTESSH_POSTFIX="\""
    fi

    cprint          "Slice Selection"		"[ $G_SLICE_SELECTION ]"
    cprint          "Margin"         		"[ $G_MARGIN ]"
    cprint          "Head Circumference"   	"[ $G_HEAD_CIRCUMFERENCE ]"
    

    STAGECMD="${REMOTESSH_PREFIX}matlab               \
              -r \\\"fetalbrain_extract('${STAGE3IN}',${G_SLICE_SELECTION},${G_MARGIN},${G_HEAD_CIRCUMFERENCE} ) ; \
              exit\\\" -nodisplay ${REMOTESSH_POSTFIX}"

    statusPrint "$(date) | Executing Matlab script" "\n"
    eval "$STAGECMD" || fatal stageRun
fi

STAGE="Normal termination -- collecting log files"
statusPrint     "Checking final log dir"
FINALLOG=${G_OUTDIR}/log${G_DIRSUFFIX}
dirExist_check  ${G_OUTDIR}/log "created" || mkdir $FINALLOG
for EXT in "log" "err" "std" ; do
    find ${G_OUTDIR} -iname "*.$EXT" -exec cp {} $FINALLOG 2>/dev/null
done
cp ${G_LOGDIR}/* $FINALLOG
stage_stamp "$STAGE" $STAMPLOG

printf "%40s" "Cleaning up"

mail_reports
shut_down 0

