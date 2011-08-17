#!/bin/bash
#
# connectome_meta.bash
#
# Copyright 2010 Dan Ginsburg, Rudolph Pienaar
# Children's Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash
source getoptx.bash
source chris_env.bash

declare -i Gi_verbose=0
declare -i Gb_useExpertOptions=1
declare -i Gb_useOverrideOut=0
declare -i Gb_forceStage=0

declare -i Gb_mailAll=0
declare -i Gb_mailStd=0
declare -i Gb_mailErr=0
declare -i Gb_mailLog=0

declare -i Gb_runCluster=0

declare -i Gb_useLowerThreshold1=0
declare -i Gb_useUpperThreshold1=0
declare -i Gb_useLowerThreshold2=0
declare -i Gb_useUpperThreshold2=0
declare -i Gb_useMask1=0
declare -i Gb_useMask2=0
declare -i Gb_useAngleThreshold=0
declare -i Gi_bValue=1000
declare -i Gb_bValueOverride=0
declare -i Gb_b0override=0
declare -i Gi_b0vols=1
declare -i Gb_Siemens=0
declare -i Gb_GE=0
declare -i Gb_forceGradientFile=0
declare -i Gb_skipEddyCurrentCorrection=0
declare -i Gb_GEGradientInlineFix=1
declare -i Gb_useDiffUnpack=1


G_LOGDIR="-x"
G_OUTDIR="$CHRIS_POSTPROC"
G_OUTSUFFIX=""
G_DIRSUFFIX=""
G_DICOMINPUTDIR="-x"
G_DICOMDTIINPUTFILE="-x"
G_DICOMT1INPUTFILE="-x"
G_GRADIENTFILE="-x"
G_MIGRATEANALYSISDIR="-x"

G_IMAGEMODEL="DTI"
G_RECONALG="fact"
G_LOWERTHRESHOLD1="-x"
G_UPPERTHRESHOLD1="-x"
G_MASKIMAGE1="-x"
G_LOWERTHRESHOLD2="-x"
G_UPPERTHRESHOLD2="-x"
G_MASKIMAGE2="-x"
G_ANGLETHRESHOLD="-x"
G_RECONALLARGS=""


G_CLUSTERNAME="$CHRIS_CLUSTER"
G_CLUSTERDIR="$CHRIS_CLUSTERDIR"
G_SCHEDULELOG="schedule.log"
G_MAILTO="$CHRIS_ADMINUSERS"

G_STAGES="123"
G_TRACT_META_STAGES="12"

G_CLUSTERUSER=""

# Possibly multiply xyz columns of gradient table with -1
G_iX=""
G_iY=""
G_iZ=""

G_SYNOPSIS="

 NAME

        connectome_meta.bash

 SYNOPSIS

        connectome_meta.bash    -D <dicomInputDir>                      \\
                                -d <diffusionDicomSeriesFile>]          \\
                                -1 <t1DicomSeriesFile>]                \\
                                [-g <gradientTableFile>] [-G]           \\
                                [-B <b0vols>]                           \\
                                [-A <reconAlg>] [-I <imageModel>]       \\
                                [--m1 <maskImage1>]                     \\
                                [--m2 <maskImage2>]                     \\
                                [--m1-lower-threshold <lth>]            \\
                                [--m2-lower-threshold <lth>]            \\
                                [--m1-upper-threshold <uth>]            \\
                                [--m2-upper-threshold <uth>]            \\
                                [--angle-threshold <angle>]             \\                               
                                [-u <uth>]                              \\
                                [-L <logDir>]                           \\
                                [-v <verbosity>]                        \\
                                [-O <outputDir>] [-o <suffix>]          \\
                                [-R <DIRsuffix>]                        \\
                                [-E] [-F <recon-all-args>]              \\
                                [-k] [-U] [-b <bFieldVal>]              \\
                                [-t <stage>] [-f]                       \\
                                [-c] [-C <clusterDir>]                  \\
                                [-X] [-Y] [-Z]                          \\
                                [-M | -m <mailReportsTo>]               \\
                                [-n <clusterUserName>]                  \\
                                [--tract-meta-stages <stages>]          \\
                                [--migrate-analysis <migrateDir>]       \\

 DESCRIPTION

        'connectome_meta.bash' is the meta shell controller for an automated
        connectivity matrix generation stream.
        
 ARGUMENTS

        -v <level> (Optional)
        Verbosity level. A value of '10' is a good choice here.

        -D <dicomInputDir>
        The directory to be scanned for specific diffusion sequences. This
        script will automatically target specific data within this directory
        and start a processing pipeline.
        
        -d <diffusionDicomSeriesFile>
        The filename of the first DICOM file in the diffusion sequence. This
        filename is relative to the <dicomInputDir>.
        
        -1 <t1DicomSeriesFile>
        The filename of the first DICOM file in the T1 sequence.  This 
        filename is relative to the <dicomInputDir>

        -U (Optional)
        If specified, do NOT use 'diff_unpack' to convert from original
        DICOM data to nifti format. By default, the script will attempt
        to create a final trackvis trk file using the same components as
        the front end diffusion toolkit. In some cases better dcm to nifti
        conversion is possible using 'mri_convert' (for Siemens) or 
        'dcm2nii'(for GE). To use these alternatives, specifiy a '-U'.

        -b <bFieldVal> (Optional: Default $Gi_bValue)
        The b field value, passed through to 'dcm2trk'.       

        [-B <b0vols>] (Optional)
        This option should only be used with care and overrides the internal
        detection of the number of b0 volumes, forcing this to be <b0vols>.

        [-A <reconAlg>] [-I <imageModel>] (Optional: Default 'fact'/'DTI')
        Specifies the reconstruction algorithm and model to use. The default
        algorithm is 'fact', and the default model is DTI.
        
        [--m1 <maskImage1>] (Optional: Default 'dwi')
        [--m2 <maskImage2>] (Optional: Default 'none')
        Selects which volume to use as a mask image 1 or 2.  Acceptable values are 'dwi',
        'fa', and 'adc'.  If specified, the lower threshold for the mask is
        given by the '-mN-lower-threshold' option.
                
        [--m1-lower-threshold <lth>] (Optional: Default '0.0')
        [--m2-lower-threshold <lth>] (Optional: Default '0.0')
        Use the <lth> as a lower cutoff threshold on mask image 1 or 2. To use the entire 
        volume, use '0.0'.  The mask image that is used depends on what is
        specified for the '-mN' option.  This option only has an effect if the
        mask is not 'dwi'.

        [--m1-upper-threshold <uth>] (Optional: Default '1.0')
        [--m2-upper-threshold <uth>] (Optional: Default '1.0')      
        Use the <uth> as an upper cutoff threshold on the mask image 1 or 2. To use 
        the entire volume, use '1.0'.  The mask image that is used depends on what is
        specified for the '-mN' option.  This option only has an effect if the
        mask is not 'dwi'.
        
        [--angle-threshold <angle>] (Optional: Default $G_ANGLETHRESHOLD)
        Use the <angle> as the threshold angle for tracking.
        
        -g <gradientTableFile> (Optional)
        By default, 'tract_meta.bash' will attempt to determine the correct
        gradient file for the tract reconstruction step. Occassionally, this
        determination might fail; by using the -g flag, a <gradientTableFile>
        can be explicitly sent to the reconstruction process. Currently, for
        Siemens data, 'tract_meta.bash' can by default gradient tables of
        minimum 13 directions. Smaller directions will necessitate supplying
        a <gradientTableFile>.

        -G (Optional: default $Gb_GEGradientInlineFix)
        GE sequences require some additional tweaking with their gradient
        gradient tables. By default, the pipeline will perform an inline
        fixing of parsed gradient tables, which typically entails toggling
        the sign on the Z direction, and in some cases swapping X and Y 
        columns.

        To TURN OFF this default, specify this flag.

        Has no effect on Siemens sequences.

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
       
        [-t <stages>] (Optional: $G_STAGES)
        The stages to process. See STAGES section for more detail.

        [-f] (Optional: $Gb_forceStage)
        If true, force re-running a stage that has already been processed.

        [-k] (Optional: $Gb_skipEddyCurrentCorrection)
        If true, skip eddy current correction when creating the track
        volume.

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
        
        [-X] [-Y] [-Z] (Optional)
        Specifying any of the above multiplies the corresponding column
        in the gradient file with -1.

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
        
        [-F <recon-all-args>] (Optional)
        If specified, insert <recon-all-args> directly into the command
        line string for the recon-all process call. Useful to more directly
        control the recon-all process.
        
        [--tract-meta-stages <stages>] (Optional)
        If specified, these stages of the tract_meta.bash pipeline will
        be run.  By default, stages 1 and 2 run.  Please consult the 
        tract_meta.bash '-t' documentation for a list of stages in
        tract_meta.bash.
        
        [--migrate-analysis <migrateDir>] (Optional)
        This option allows the specification of an alternative directory
        to <outputDir> where the processing occurs.  Basically what will
        happen is the input scans are copied to <migrateDir>, processing
        is done, and the files are then moved over back to the <outDir>
        when finished.  The purpose of this is to allow for use of
        cluster storage for doing processing automatically.        

STAGES

        'connectome_meta.bash' offers the following stages:

        1 - dicom_seriesCollect.bash
                Collect T1 DICOM series from a given directory.
        2 - tract_meta.bash
                Compute tractography using the Diffusion Toolkit.
        3 - cmt
                Run the LTS Connectome Mapping Toolkit

 OUTPUT
        Each processing stage has its own set of inputs and outputs. Typically
        the outputs from one stage become the inputs to a subsequent stage.

        As a whole, this processing pipelie has two main classes of output:

        1. A trackvis format *.trk file that can be visualized by TrackVis
        2. A processed freesurfer subject directory
        3. A connectivity matrix

 PRECONDITIONS
        
        o A FreeSurfer 'std' or 'dev' environment.
        o Individual pipeline components have their own PRECONDITIONS.


 POSTCONDITIONS

        o Each stage (and substages) including intermediary data
          is housed in its own directory, called 'stage-X-<stageName>'

        o For the case of the full pipeline, the remote DICOM server
          will have a new 'study' containing flat DICOM images of the
          reconstructed tractography.

 SEE ALSO

        o tract_meta.bash -- functionally similar pipeline geared for
          tractography processing.

 HISTORY
        17 August 2011
        o Corrected '-F notalairach' handling.

        3 December 2010
        o Connect to the cmt pipeline

        27 September 2010
        o Initial design and coding.
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///cat

# Actions-
A_fileCheck="checking for a required file dependency"
A_metaLog="checking the tract_meta.bash.log file"
A_badLogDir="checking on the log directory"
A_badLogFile="checking on the log file"
A_dependencyStage="checking for a required dependency from an earlier stage"
A_stageRun="running a stage in the processing pipeline"
A_mri_info="running 'mri_info'"
A_noGradientFile="checking on the gradient file"
A_noMatlab="checking for MatLAB"
A_noDicomDir="checking on input DICOM directory"
A_noDicomFile="checking on input DICOM directory / file"
A_noDicomDirArg="checking on -d <dicomInputDir> argument"
A_unknownManufacturer="checking on the diffusion data"
A_ge_diffusionProcess="running ge_diffusionProcess.bash"
A_siemens_diffusionProcess="running siemens_diffusionProcess.bash"
A_reconAlg="checking on the reconstruction algorithm"
A_imageModel="checking on the image model"
A_fa="checking on the FA argument "
A_noDtiDicomFileArg="checking on input DTI DICOM file"
A_noT1DicomFileArg="checking on input DTI DICOM file"
A_badMigrateDir="checking on --migrate-analysis <migrateDir>"


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
EM_unknownManufacturer="the manufacturer field for the DICOM data is unknown."
EM_ge_diffusionProcess="some internal error occurred."
EM_siemens_diffusionProcess="some internal error occurred."
EM_reconAlg="must be either 'fact' or 'rk2'."
EM_imageModel="must be either 'hardi' or 'dti'."
EM_fa="No <lth> has been specified."
EM_noDtiDicomFileArg="it seems as though you didn't specify a -d <dicomDTIInputFile>"
EM_noT1DicomFileArg="it seems as though you didn't specify a -t1 <dicomT1InputFile>"
EM_badMigrateDir="I couldn't access <migrateDir>"



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
EC_unknownManufacturer=60
EC_ge_diffusionProcess=61
EC_siemens_diffusionProcess=62
EC_reconAlg=70
EC_imageModel=71
EC_fa=80
EC_noDtiDicomFileArg=81
EC_noT1DicomFileArg=82
EC_badMigrateDir=83


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
    MRID=$(echo $G_DCM_MKINDX | grep Patient | awk '{print $3}')
    cd $here >/dev/null
    echo $MRID
}



###\\\
# Process command options
###///

while getoptex "v: D: d: B: A: I: k E F: L: O: R: o: f \
                X Y Z t: c C: g: G U b: n: M: m: \
                m1: m2: \
                m1-lower-threshold: \
                m2-lower-threshold: \
                m1-upper-threshold: \
                m2-upper-threshold: 1: h \
                tract-meta-stages: \
                migrate-analysis: \
                angle-threshold: " "$@" ; do
        case "$OPTOPT"
        in
            v)      Gi_verbose=$OPTARG              ;;
            D)      G_DICOMINPUTDIR=$OPTARG         ;;
            d)      G_DICOMDTIINPUTFILE=$OPTARG     ;;
            1)      G_DICOMT1INPUTFILE=$OPTARG      ;;
            E)      Gb_useExpertOptions=1           ;;
            F)      G_RECONALLARGS=$OPTARG          ;;
            k)      Gb_skipEddyCurrentCorrection=1  ;;
            L)      G_LOGDIR=$OPTARG                ;;
            O)      Gb_useOverrideOut=1     
                    G_OUTDIR=$OPTARG                ;;
            R)      G_DIRSUFFIX=$OPTARG             ;;
            o)      G_OUTSUFFIX=$OPTARG             ;;
            g)      Gb_forceGradientFile=1  
                    G_GRADIENTFILE=$OPTARG          ;;
            B)      Gb_b0override=1
                    Gi_b0vols=$OPTARG               ;;
            I)      G_IMAGEMODEL=$OPTARG            ;;
            A)      G_RECONALG=$OPTARG              ;;
            u)      Gb_useUpperThreshold=1
                    G_UPPERTHRESHOLD=$OPTARG        ;;
            m1)     Gb_useMask1=1
                    G_MASKIMAGE1=$OPTARG            ;;
            m1-lower-threshold)
                    Gb_useLowerThreshold1=1
                    G_LOWERTHRESHOLD1=$OPTARG       ;;        
            m1-upper-threshold)
                    Gb_useUpperThreshold1=1                            
                    G_UPPERTHRESHOLD1=$OPTARG       ;;                                       
            m2)     Gb_useMask2=1
                    G_MASKIMAGE2=$OPTARG            ;;           
            m2-lower-threshold)
                    Gb_useLowerThreshold2=1                            
                    G_LOWERTHRESHOLD2=$OPTARG       ;;                    
            m2-upper-threshold)
                    Gb_useUpperThreshold2=1                            
                    G_UPPERTHRESHOLD2=$OPTARG       ;;
            angle-threshold) 
                    Gb_useAngleThreshold=1
                    G_ANGLETHRESHOLD=$OPTARG        ;;                    
            G)      Gb_GEGradientInlineFix=0        ;;
            f)      Gb_forceStage=1                 ;;
            t)      G_STAGES=$OPTARG                ;;
            c)      Gb_runCluster=1                 ;;
            C)      G_CLUSTERDIR=$OPTARG            ;;
            U)      Gb_useDiffUnpack=0              ;;
            b)      Gb_bValueOverride=1
                    Gi_bValue=$OPTARG               ;;
            X)      G_iX="-X"                       ;;
            Y)      G_iY="-Y"                       ;;
            Z)      G_iZ="-Z"                       ;;
            M)      Gb_mailStd=1
                    Gb_mailErr=1
                    G_MAILTO=$OPTARG                ;;
            m)      Gb_mailStd=1
                    Gb_mailErr=0
                    G_MAILTO=$OPTARG                ;;
            n)      G_CLUSTERUSER=$OPTARG           ;;
            tract-meta-stages)
                    G_TRACT_META_STAGES=$OPTARG     ;;
            migrate-analysis)
                    G_MIGRATEANALYSISDIR=$OPTARG    ;;
            h)      synopsis_show 
                    exit 0;;
        esac
done

verbosity_check
topDir=$(pwd)
echo ""
cprint  "hostname"      "[ $(hostname) ]"

## Check on script preconditions
REQUIREDFILES="common.bash tract_meta.bash fs_meta.bash dcm_coreg.bash \
               dicom_seriesCollect.bash Slicer3 dcm_mkIndx.bash \
               pipeline_status_cmd.py"
for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file"
        file_checkOnPath $file || fatal fileCheck
done

## Check on input directory and files
statusPrint     "Checking -D <dicomInputDir>"
if [[ "$G_DICOMINPUTDIR" == "-x" ]] ; then fatal noDicomDirArg ; fi
ret_check $?

statusPrint     "Checking -d <diffusionDicomSeriesFile>"
if [[ "$G_DICOMDTIINPUTFILE" == "-x" ]] ; then fatal noDtiDicomFileArg ; fi
ret_check $?

statusPrint     "Checking -t1 <t1DicomSeriesFile>"
if [[ "$G_DICOMT1INPUTFILE" == "-x" ]] ; then fatal noT1DicomFileArg ; fi
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
statusPrint     "Querying <dicomInputDir> for sequences"
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
    dirExist_check $G_OUTDIR || mkdir -p "$G_OUTDIR" || fatal badOutDir
    cd $G_OUTDIR >/dev/null
    G_OUTDIR=$(pwd)
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
    G_ORIG_OUTDIR=${G_OUTDIR}
    # Now, map the output directory to the migrate analysis directory
    G_OUTDIR=$G_MIGRATEANALYSISDIR
fi

topDir=$G_OUTDIR
cd $topDir


## Main processing start
STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($topDir) $G_SELF $*" $STAMPLOG

## Check on cluster access
if (( Gb_runCluster )) ; then
  statusPrint   "Checking on <clusterDir>"
  dirExist_check $G_CLUSTERDIR || mkdir $G_CLUSTERDIR || fatal badClusterDir
  cluster_schedule "$*" "connectome"
  G_STAGES=0
  STAGE="Cluster re-spawn termination"
  stage_stamp "$STAGE" $STAMPLOG
  shut_down 0
fi

## Check which stages to process
statusPrint     "Checking which stages to process"
barr_stage=([0]=0 [1]=0 [2]=0 [3]=0 [4]=0 [5]=0 [6]=0)
for i in $(seq 1 6) ; do
        b_test=$(expr index $G_STAGES "$i")
        if (( b_test )) ; then b_flag="1" ; else b_flag="0" ; fi
        barr_stage[$i]=$b_flag
done
ret_check $?

DATE=$(date)
        
# Create pipeline status file
pipelineStatus_create "connectome_meta.bash"            \
                        "dicom_seriesCollect.bash       \
                        tract_meta.bash                 \
                        cmt"
                                                
# Stage 1
STAGE1PROC=dicom_seriesCollect.bash
pipelineStatus_addInput ${STAGE1PROC} ${G_DICOMINPUTDIR} $G_DICOMT1INPUTFILE "dcm"    
if (( ${barr_stage[1]} )) ; then
    statusPrint "$(date) | Processing STAGE 1 - Collecting T1 DICOM | START" "\n"        
    STAGE=1-$STAGE1PROC
    EXOPTS=$(eval expertOpts_parse $STAGE1PROC)
    if (( Gb_useOverrideOut )) ;  then
                EXOPTS="$EXOPTS -R \"$G_OUTDIR\""
    fi
    
    
    TARGETSPEC="-d $G_DICOMT1INPUTFILE"
    if [[ "$G_MIGRATEANALYSISDIR" == "-x" ]] ; then
        TARGETSPEC="$TARGETSPEC -l"
    fi
    
    
    STAGECMD="dicom_seriesCollect.bash                  \
                -v $Gi_verbose -D "$G_DICOMINPUTDIR"    \
                $TARGETSPEC                             \
                -m $G_DIRSUFFIX                         \
                -L $G_LOGDIR -A                         \
                $EXOPTS"                                
    STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE1PROC}.std"         \
                "${G_LOGDIR}/${STAGE1PROC}.err"         \
         || fatal stageRun
    statusPrint "$(date) | Processing STAGE 1 - Collecting T1 DICOM | END" "\n"
fi

# Check on the stage 1 logs to determine the actual output directory
LOGFILE=${G_LOGDIR}/dicom_seriesCollect.bash.log
statusPrint "Checking if stage 1 output log exists"
fileExist_check $LOGFILE || fatal badLogFile
STAGE1DIR=$(cat $LOGFILE | grep Collection | tail -n 1  |\
        awk -F \| '{print $4}'                          |\
        sed 's/^[ \t]*//;s/[ \t]*$//')

if (( ! ${#STAGE1DIR} )) ; then fatal dependencyStage; fi
STAGE1OUT=$STAGE1DIR
pipelineStatus_addOutput ${STAGE1PROC} $STAGE1DIR $G_DICOMT1INPUTFILE "dcm"

# Stage 2
STAGE2PROC=tract_meta.bash
pipelineStatus_addInput ${STAGE2PROC} ${G_DICOMINPUTDIR} $G_DICOMDTIINPUTFILE "dti"
if (( ${barr_stage[2]} )) ; then
    
    pipelineStatus_canRun ${STAGE2PROC} || fatal dependencyStage
    
    statusPrint "$(date) | Processing STAGE 2 - Tractography | START" "\n"
    STAGE=2-$STAGE2PROC
    EXOPTS=$(eval expertOpts_parse $STAGE2PROC)
    
    # Add the trivial-to-parse arguments
    TRACTARGS="-v $Gi_verbose                       \
               -D $G_DICOMINPUTDIR                  \
               -d $G_DICOMDTIINPUTFILE              \
               -L $G_LOGDIR                         \
               -R $G_DIRSUFFIX                      \
               -I $G_IMAGEMODEL                     \
               -A $G_RECONALG                       \
               $G_iX $G_iY $G_iZ                    \
               -f                                   \
               -t $G_TRACT_META_STAGES"

    if [[ "$G_OUTSUFFIX" != "" ]] ; then
        TRACTARGS="$TRACTARGS -o $G_OUTSUFFIX"
    fi
                              
    # Add the individual arguments
    if (( Gb_useExpertOptions )) ; then
        TRACTARGS="$TRACTARGS -E"
    fi
    
    if (( Gb_skipEddyCurrentCorrection )) ; then
        TRACTARGS="$TRACTARGS -k"
    fi
    
    if (( Gb_useOverrideOut )) ; then
        TRACTARGS="$TRACTARGS -O $G_OUTDIR"
    fi
    
    if (( Gb_forceGradientFile )) ; then
        TRACTARGS="$TRACTARGS -g $G_GRADIENTFILE"
    fi
    
    if (( Gb_b0override )) ; then
        TRACTARGS="$TRACTARGS -b $Gi_b0vols"
    fi
        
    if (( Gb_useMask1 )) ; then
        TRACTARGS="$TRACTARGS --m1 $G_MASKIMAGE1"
    fi
    
    if (( Gb_useLowerThreshold1 )) ; then
        TRACTARGS="$TRACTARGS --m1-lower-threshold $G_LOWERTHRESHOLD1"
    fi
    
    if (( Gb_useUpperThreshold1 )) ; then
        TRACTARGS="$TRACTARGS --m1-upper-threshold $G_LOWERTHRESHOLD1"
    fi    
        
    if (( Gb_useMask2 )) ; then
        TRACTARGS="$TRACTARGS --m2 $G_MASKIMAGE2"
    fi
    
    if (( Gb_useLowerThreshold2 )) ; then
        TRACTARGS="$TRACTARGS --m2-lower-threshold $G_LOWERTHRESHOLD2"
    fi
    
    if (( Gb_useUpperThreshold2 )) ; then
        TRACTARGS="$TRACTARGS --m2-upper-threshold $G_LOWERTHRESHOLD2"
    fi
    
    if (( Gb_useAngleThreshold )) ; then
        TRACTARGS="$TRACTARGS --angle-threshold $G_ANGLETHRESHOLD"
    fi
        
    if (( !Gb_GEGradientInlineFix )) ; then
       TRACTARGS="$TRACTARGS -G"
    fi
    
    if (( !Gb_useDiffUnpack )) ; then
        TRACTARGS="$TRACTARGS -U"
    fi
    
    if (( Gb_bValueOverride )) ; then
        TRACTARGS="$TRACTARGS -b $Gi_bValue"
    fi
    
    STAGECMD="tract_meta.bash $TRACTARGS $EXOPTS"
    echo $STAGECMD
    STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE2PROC}.std"         \
                "${G_LOGDIR}/${STAGE2PROC}.err"         \
         || fatal stageRun
    
    
    statusPrint "$(date) | Processing STAGE 2 - Tractography | END" "\n"
fi

# Set the output directory to the same place that tract_meta.bash is going to
# for the remaining stages
G_OUTDIR=${G_OUTDIR}/${MRID}${G_OUTSUFFIX}

# Find the B0 volume from the tractography processing
DCM2TRKLOG=$(find $G_OUTDIR -name dcm2trk.bash.log)
fileExist_check $DCM2TRKLOG || fatal badLogFile

DIFFRECONBASE=$(cat $DCM2TRKLOG | grep " dti_recon" | tail -1 | awk -F \| '{print $3}' | awk '{print $5}')
GRADMATRIX=$(cat $DCM2TRKLOG | grep " dti_recon" | tail -1 | awk -F \| '{print $3}' | \
            grep -oh "\-gm .*" | awk '{print $2}')
BVALUE=$(cat $DCM2TRKLOG | grep " dti_recon" | tail -1 | awk -F \| '{print $3}' | \
         grep -oh "\-b .*" | awk '{print $2}')
B0VOLS=$(cat $DCM2TRKLOG | grep " dti_recon" | tail -1 | awk -F \| '{print $3}' | \
         grep -oh "\-b0 .*" | awk '{print $2}')                
DIFFBASEOUTDIR=$(dirname $(dirname $DIFFRECONBASE))
DIFFB0VOLUME=${DIFFRECONBASE}_b0.nii
DIFFDCMDIR=$(dirname $(cat $DCM2TRKLOG | grep diff_unpack | tail -2 | head -n 1 | \
            awk -F \| '{print $3}' | awk '{print $4}'))
printf "%40s"   "Checking for $DIFFB0VOLUME"
fileExist_check $DIFFB0VOLUME || fatal dependencyStage
pipelineStatus_addOutput ${STAGE2PROC} ${DIFFBASEOUTDIR}/final-trackvis "*.trk" "trk"
pipelineStatus_addOutput ${STAGE2PROC} $(dirname ${DIFFB0VOLUME}) $(basename ${DIFFB0VOLUME}) "b0"


# Stage 3
STAGE3PROC=cmt
pipelineStatus_addInput ${STAGE3PROC} $(dirname ${DIFFB0VOLUME}) $(basename ${DIFFB0VOLUME}) "b0"
pipelineStatus_addInput ${STAGE3PROC} $STAGE1OUT $G_DICOMT1INPUTFILE "t1"

if (( ${barr_stage[3]} )) ; then
    
    pipelineStatus_canRun ${STAGE3PROC} || fatal dependencyStage
    
    statusPrint "$(date) | Processing STAGE 3 - cmt | START" "\n"
    STAGE=3-$STAGE3PROC
    EXOPTS=$(eval expertOpts_parse $STAGE3PROC)
        
    statusPrint "Checking on stage 3 output directory"
    dirExist_check $G_OUTDIR/$STAGE || mkdir "$G_OUTDIR/$STAGE" || fatal badOutDir
    
    
    # Due to an issue with enthought traits, currently the cmt pipeline
    # requires that there be an X server present to run.  This should
    # be fixed in enthought traits 3.4+, but for now invoke Xvfb as a
    # workaround
    
    # Find a free server, this code came from the standard xvfb-run script
    i=99
    while [ -f /tmp/.X$i-lock ]; do
        i=$(($i + 1))
    done
    G_XVFB_SERVERNUM=$i
    
    export DISPLAY=:${G_XVFB_SERVERNUM}
    cprint "Setting Xvfb display"	"[ $G_XVFB_SERVERNUM ]"
    XVFBCMD="Xvfb :${G_XVFB_SERVERNUM} -screen 1 1600x1200x24 2>/dev/null"
    echo "$XVFBCMD &" | sh

    CMTNOTAL=""
    if [[ $G_RECONALLARGS == "-notalairach" ]] ; then
        CMTNOTAL="--notalairach"
    fi

    CMTARGS="-p ${MRID}${G_OUTSUFFIX}           \
             -d ${G_OUTDIR}/${STAGE}            \
             --b0=${B0VOLS}                     \
             --bValue=${BVALUE}                 \
             --gm=${GRADMATRIX}                 \
             --dtiDir=${DIFFDCMDIR}             \
             --t1Dir=${STAGE1OUT} $CMTNOTAL"              
    CMTPKLARGS="${CMTARGS}"
    if [[ "$G_MIGRATEANALYSISDIR" != "-x" ]] ; then
	CMTPKLARGS=$(echo "${CMTPKLARGS}" | sed "s|${G_MIGRATEANALYSISDIR}|${G_ORIG_OUTDIR}|g")
    fi
    CMTPKLARGS="${CMTPKLARGS} --writePickle=${G_OUTDIR}/cmp_gui.pkl"
    
    # First write out the pickle so that if needed, the user can use
    # the CMP GUI to pick up working on the data after it is finished
    # processing automatically
    STAGECMD="connectome_web.py $CMTPKLARGS"
    STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE3PROC}.std"         \
                "${G_LOGDIR}/${STAGE3PROC}.err"         \
          || fatal stageRun
             
    # First convert input T1 to NII format
    STAGECMD="connectome_web.py $CMTARGS"
    STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE3PROC}.std"         \
                "${G_LOGDIR}/${STAGE3PROC}.err"         \
          || fatal stageRun
          
    statusPrint	"Shutting down Xvfb"
	ps -Af  | grep "Xvfb :${G_XVFB_SERVERNUM}" | grep -v $G_SELF | grep -v grep | awk '{print "kill -9 " $2}' | sh 2>/dev/null >/dev/null
	ret_check $?          
           
    statusPrint "$(date) | Processing STAGE 3 - cmt | END" "\n"
fi

# TODO: Check for output of cmt pipeline, although its status file
# already defines all of its outputs so I'm not really sure we need
# to check here.
#STAGE3OUT="$G_OUTDIR/3-$STAGE3PROC/T1_to_B0.nii"
#printf "%40s"   "Checking for $STAGE3OUT"
#fileExist_check  $STAGE3OUT || fatal dependencyStage

#pipelineStatus_addOutput ${STAGE3PROC} $(dirname ${STAGE3OUT}) $(basename ${STAGE3OUT}) "T1_to_B0"

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

mail_reports "$G_MAILTO" "$Gb_mailStd" "$Gb_mailErr"
shut_down 0

