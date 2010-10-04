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
G_OUTDIR="/space/kaos/5/users/dicom/postproc"
G_OUTSUFFIX=""
G_DIRSUFFIX=""
G_DICOMINPUTDIR="-x"
G_DICOMDTIINPUTFILE="-x"
G_DICOMT1INPUTFILE="-x"
G_GRADIENTFILE="-x"

G_IMAGEMODEL="DTI"
G_RECONALG="fact"
G_LOWERTHRESHOLD1="-x"
G_UPPERTHRESHOLD1="-x"
G_MASKIMAGE1="-x"
G_LOWERTHRESHOLD2="-x"
G_UPPERTHRESHOLD2="-x"
G_MASKIMAGE2="-x"


G_CLUSTERNAME=seychelles
G_CLUSTERDIR=${G_OUTDIR}/${G_CLUSTERNAME}
G_SCHEDULELOG="schedule.log"
G_MAILTO="rudolph.pienaar@childrens.harvard.edu,daniel.ginsburg@childrens.harvard.edu"

G_STAGES="123456"

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
                                -t1 <t1DicomSeriesFile>]                \\
                                [-g <gradientTableFile>] [-G]           \\
                                [-B <b0vols>]                           \\
                                [-A <reconAlg>] [-I <imageModel>]       \\
                                [-m1 <maskImage1>]                      \\
                                [-m2 <maskImage2>]                      \\
                                [-m1-lower-threshold <lth>]             \\
                                [-m2-lower-threshold <lth>]             \\
                                [-m1-upper-threshold <uth>]             \\
                                [-m2-upper-threshold <uth>]             \\
                                [-u <uth>]                              \\
                                [-L <logDir>]                           \\
                                [-v <verbosity>]                        \\
                                [-O <outputDir>] [-o <suffix>]          \\
                                [-R <DIRsuffix>]                        \\
                                [-E]                                    \\
                                [-k] [-U] [-b <bFieldVal>]              \\
                                [-t <stage>] [-f]                       \\
                                [-c] [-C <clusterDir>]                  \\
                                [-X] [-Y] [-Z]                          \\
                                [-M | -m <mailReportsTo>]               \\
                                [-n <clusterUserName>]

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
        
        [-m1 <maskImage1>] (Optional: Default 'dwi')
        [-m2 <maskImage2>] (Optional: Default 'none')
        Selects which volume to use as a mask image 1 or 2.  Acceptable values are 'dwi',
        'fa', and 'adc'.  If specified, the lower threshold for the mask is
        given by the '-mN-lower-threshold' option.
                
        [-m1-lower-threshold <lth>] (Optional: Default '0.0')
        [-m2-lower-threshold <lth>] (Optional: Default '0.0')
        Use the <lth> as a lower cutoff threshold on mask image 1 or 2. To use the entire 
        volume, use '0.0'.  The mask image that is used depends on what is
        specified for the '-mN' option.  This option only has an effect if the
        mask is not 'dwi'.

        [-m1-upper-threshold <uth>] (Optional: Default '1.0')
        [-m2-upper-threshold <uth>] (Optional: Default '1.0')      
        Use the <uth> as an upper cutoff threshold on the mask image 1 or 2. To use 
        the entire volume, use '1.0'.  The mask image that is used depends on what is
        specified for the '-mN' option.  This option only has an effect if the
        mask is not 'dwi'.
        
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

STAGES

        'connectome_meta.bash' offers the following stages:

        1 - dicom_seriesCollect.bash-dti
                Collect DTI DICOM series from a given directory.
        2 - dicom_seriesCollect.bash-t1
                Collect T1 DICOM series from a given directory.
        3 - tract_meta.bash
                Compute tractography using the Diffusion Toolkit.
        4 - dcm_coreg.bash
                Register T1 -> B0 diffusion volume                        
        5 - fs_meta.bash
                Run freesurfer on registered volume
        6 - parcellate.bash
                Parcellate freesurfer surface using ROI atlases
        7 - compute_connectivity.bash
                Generate connectivity matrix for parcellated 
                surfaces and tratography.

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

        o fs_meta.bash -- functionally similar pipeline geared for
          FreeSurfer processing.

 HISTORY

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


# Defaults
D_whatever=

###\\\
# Function definitions
###///


###\\\
# Process command options
###///

while getoptex "v: D: d: B: A: I: k E L: O: R: o: f \
                X Y Z t: c C: g: G U b: n: M: m: \
                m1: m2: \
                m1-lower-threshold: \
                m2-lower-threshold: \
                m1-upper-threshold: \
                m2-upper-threshold: 1: h" "$@" ; do
        case "$OPTOPT"
        in
            v)      Gi_verbose=$OPTARG              ;;
            D)      G_DICOMINPUTDIR=$OPTARG         ;;
            d)      G_DICOMDTIINPUTFILE=$OPTARG     ;;
            1)      G_DICOMT1INPUTFILE=$OPTARG      ;;
            E)      Gb_useExpertOptions=1           ;;
            k)      Gb_skipEddyCurrentCorrection=1  ;;
            L)      G_LOGDIR=$OPTARG                ;;
            O)      Gb_useOverrideOut=1     
                    G_OUTDIR=$OPTARG  
                    G_CLUSTERDIR=${G_OUTDIR}/${G_CLUSTERNAME}        ;;
            R)      G_DIRSUFFIX=$OPTARG             ;;
            o)      G_OUTSUFFIX=$OPTARG             ;;
            g)      Gb_forceGradientFile=1  
                    G_GRADIENTFILE=$OPTARG          ;;
            B)      Gb_b0override=1
                    Gi_b0vols=$OPTARG               ;;
            I)      G_IMAGEMODEL=$OPTARG            ;;
            A)      G_RECONALG=$OPTARG              ;;
            F)      Gb_useLowerThreshold=1
                    G_LOWERTHRESHOLD=$OPTARG        ;;
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
            G)      Gb_GEGradientInlineFix=0        ;;
            f)      Gb_forceStage=1                 ;;
            t)      G_STAGES=$OPTARG                ;;
            c)      Gb_runCluster=1                 ;;
            C)      G_CLUSTERNAME=$OPTARG
                    G_CLUSTERDIR=${G_OUTDIR}/${G_CLUSTERNAME}       ;;
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
               dicom_seriesCollect.bash Slicer3"
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
  statusPrint   "Checking on <clusterDir>"
  dirExist_check $G_CLUSTERDIR || mkdir $G_CLUSTERDIR || fatal badClusterDir
  cluster_schedule "$*" "tract"
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

# Stage 1        
STAGE1PROC=dicom_seriesCollect.bash-dti
if (( ${barr_stage[1]} )) ; then
    statusPrint "$(date) | Processing STAGE 1 - Collecting diffusion DICOM | START" "\n"
    STAGE=1-$STAGE1PROC
    EXOPTS=$(eval expertOpts_parse $STAGE1PROC)
    if (( Gb_useOverrideOut )) ;  then
                EXOPTS="$EXOPTS -O \"$G_OUTDIR/raw_diffusion\""
    fi
    
    TARGETSPEC="-d $G_DICOMDTIINPUTFILE"
                
    STAGECMD="dicom_seriesCollect.bash                  \
                -v $Gi_verbose -D "$G_DICOMINPUTDIR"             \
                $TARGETSPEC                             \
                -m $G_DIRSUFFIX                         \
                -L $G_LOGDIR -A -l                      \
                $EXOPTS"
    STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE1PROC}.std"         \
                "${G_LOGDIR}/${STAGE1PROC}.err"         \
         || fatal stageRun
    statusPrint "$(date) | Processing STAGE 1 - Collecting diffusion DICOM | END" "\n"
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

# Stage 2
STAGE2PROC=dicom_seriesCollect.bash-T1
if (( ${barr_stage[2]} )) ; then
    statusPrint "$(date) | Processing STAGE 2 - Collecting T1 DICOM | START" "\n"
    STAGE=2-$STAGE2PROC
    EXOPTS=$(eval expertOpts_parse $STAGE2PROC)
    if (( Gb_useOverrideOut )) ;  then
                EXOPTS="$EXOPTS -O \"$G_OUTDIR/raw_T1\""
    fi
    
    TARGETSPEC="-d $G_DICOMT1INPUTFILE"
                
    STAGECMD="dicom_seriesCollect.bash                  \
                -v $Gi_verbose -D "$G_DICOMINPUTDIR"             \
                $TARGETSPEC                             \
                -m $G_DIRSUFFIX                         \
                -L $G_LOGDIR -A -l                      \
                $EXOPTS"                                
    STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE2PROC}.std"         \
                "${G_LOGDIR}/${STAGE2PROC}.err"         \
         || fatal stageRun
    statusPrint "$(date) | Processing STAGE 2 - Collecting T1 DICOM | END" "\n"
fi

# Check on the stage 2 logs to determine the actual output directory
LOGFILE=${G_LOGDIR}/dicom_seriesCollect.bash.log
statusPrint "Checking if stage 2 output log exists"
fileExist_check $LOGFILE || fatal badLogFile
STAGE2DIR=$(cat $LOGFILE | grep Collection | tail -n 1  |\
        awk -F \| '{print $4}'                          |\
        sed 's/^[ \t]*//;s/[ \t]*$//')

if (( ! ${#STAGE2DIR} )) ; then fatal dependencyStage; fi
STAGE2OUT=$STAGE2DIR

# Stage 3
STAGE3PROC=tract_meta.bash
if (( ${barr_stage[3]} )) ; then
    statusPrint "$(date) | Processing STAGE 3 - Tractography | START" "\n"
    STAGE=3-$STAGE3PROC
    EXOPTS=$(eval expertOpts_parse $STAGE3PROC)
    
    # Add the trivial-to-parse arguments
    #  NOTE: At the moment I am just forcing stage 1/2, if we
    #        want we can customize that further so that this
    #        meta script takes an argument to specify which
    #        tract stages to run.  We'll see if it's needed...
    TRACTARGS="-v $Gi_verbose                       \
               -D $G_DICOMINPUTDIR                  \
               -d $G_DICOMDTIINPUTFILE              \
               -L $G_LOGDIR                         \
               -R $G_DIRSUFFIX                      \
               -I $G_IMAGEMODEL                     \
               -A $G_RECONALG                       \
               $G_iX $G_iY $G_iZ                    \
               -f                                   \
               -t 12"

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
    
    if (( Gb_useLowerThreshold )) ; then
        TRACTARGS="$TRACTARGS -F $G_LOWERTHRESHOLD"
    fi
    
    if (( Gb_useUpperThreshold )) ; then
        TRACTARGS="$TRACTARGS -u $G_UPPERTHRESHOLD"
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
                "${G_LOGDIR}/${STAGE3PROC}.std"         \
                "${G_LOGDIR}/${STAGE3PROC}.err"         \
         || fatal stageRun
    
    
    statusPrint "$(date) | Processing STAGE 3 - Tractography | END" "\n"
fi

# Find the B0 volume from the tractography processing
DCM2TRKLOG=$(find $G_OUTDIR -name dcm2trk.bash.log)
DIFFRECONBASE=$(cat $DCM2TRKLOG | grep _recon | tail -1 | awk -F \| '{print $3}' | awk '{print $4}')
DIFFB0VOLUME=${DIFFRECONBASE}_b0.nii
printf "%40s"   "Checking for $DIFFB0VOLUME"
fileExist_check $DIFFB0VOLUME || fatal dependencyStage

# Stage 4
STAGE4PROC=register
if (( ${barr_stage[4]} )) ; then
    statusPrint "$(date) | Processing STAGE 4 - Registration | START" "\n"
    STAGE=4-$STAGE4PROC
    EXOPTS=$(eval expertOpts_parse $STAGE4PROC)
        
    statusPrint "Checking on stage 4 output directory"
    dirExist_check $G_OUTDIR/$STAGE || mkdir "$G_OUTDIR/$STAGE" || fatal badOutDir
    
    # First convert input T1 to NII format
    STAGECMD="mri_convert -it dicom -ot nii $STAGE2OUT/$G_DICOMT1INPUTFILE $G_OUTDIR/$STAGE/T1.nii"
    STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE4PROC}.std"         \
                "${G_LOGDIR}/${STAGE4PROC}.err"         \
          || fatal stageRun
          
    # Now use Slicer3 RegisterImage module to compute registration matrix
    STAGECMD="Slicer3 --launch RegisterImages                                   \
                            --registration Rigid                                \
                            --saveTransform $G_OUTDIR/$STAGE/T1_B0.tfm          \
                            $DIFFB0VOLUME                                       \
                            $G_OUTDIR/$STAGE/T1.nii"
    STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE4PROC}.std"         \
                "${G_LOGDIR}/${STAGE4PROC}.err"         \
          || fatal stageRun
    
    # Finally use Slice3 ResampleVolume2 to apply the transform, keeping
    # the voxel size/spacing the same
    STAGECMD="Slicer3 --launch                                                  \
                 ResampleVolume2 -f $G_OUTDIR/$STAGE/T1_B0.tfm                  \
                            $G_OUTDIR/$STAGE/T1.nii                             \
                            $G_OUTDIR/$STAGE/T1_to_B0.nii"
    STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE4PROC}.std"         \
                "${G_LOGDIR}/${STAGE4PROC}.err"         \
          || fatal stageRun
        

    # The below did not always produce good registrations         
    # First convert input T1 to NII format
    # STAGECMD="mri_convert -it dicom -ot nii $STAGE2OUT/$G_DICOMT1INPUTFILE $G_OUTDIR/$STAGE/T1.nii"
    # STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    # stage_run "$STAGE" "$STAGECMD"                      \
                # "${G_LOGDIR}/${STAGE4PROC}.std"         \
                # "${G_LOGDIR}/${STAGE4PROC}.err"         \
         # || fatal stageRun   

    # Use fsl_rigid_register to generate the transformation matrix
    # STAGECMD="fsl_rigid_register -r $DIFFB0VOLUME           \
                   # -i $G_OUTDIR/$STAGE/T1.nii               \
                   # -o $G_OUTDIR/$STAGE/temp.nii             \
                   # -cost normmi                             \
                   # -xfmmat $G_OUTDIR/$STAGE/T1_B0.xfm"
    # STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    # stage_run "$STAGE" "$STAGECMD"                      \
                # "${G_LOGDIR}/${STAGE4PROC}.std"         \
                # "${G_LOGDIR}/${STAGE4PROC}.err"         \
         # || fatal stageRun
             # 
    # # Apply the transformation matrix to the T1 scan          
    # STAGECMD="mri_convert -it nii -ot nii               \
                    # -at $G_OUTDIR/$STAGE/T1_B0.xfm      \
                    # $G_OUTDIR/$STAGE/T1.nii             \
                    # $G_OUTDIR/$STAGE/T1_to_B0.nii"                                        
    # STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    # stage_run "$STAGE" "$STAGECMD"                      \
                # "${G_LOGDIR}/${STAGE4PROC}.std"         \
                # "${G_LOGDIR}/${STAGE4PROC}.err"         \
         # || fatal stageRun
    
    
    # First compute the registration matrix.  This will also compute
    # a new volume resampled to the resolution of the B0.  We do not
    # want this, we want to keep the T1 volume at its original volume
    # otherwise there is a large information loss since it is usually
    # higher resolution than the diffusion.  So we will use the matrix
    # output from this in the next step of this stage.
    # DCMREGARGS="-v $Gi_verbose                       \
                # -D $G_DICOMINPUTDIR                  \
                # -d $G_DICOMT1INPUTFILE               \
                # -r $G_DICOMDTIINPUTFILE              \
                # -p register_T1_to_B0                 \
                # -o register_T1_to_B0"          
# 
    # if (( Gb_useOverrideOut )) ; then
        # DCMREGARGS="$DCMREGARGS -O $G_OUTDIR"
    # fi
                      # 
    # STAGECMD="dcm_coreg.bash $DCMREGARGS $EXOPTS"
    # STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    # #stage_run "$STAGE" "$STAGECMD"                      \
    # #            "${G_LOGDIR}/${STAGE4PROC}.std"         \
    # #            "${G_LOGDIR}/${STAGE4PROC}.err"         \
    # #     || fatal stageRun
         # 
    # # Now run again, this time applying the previously generated matrix
    # # to the volume, but don't resample the size.
    # STAGECMD="flirt -applyxfm                                                            \
                    # -init $G_OUTDIR/register_T1_to_B0/register_T1_to_B0-registered.mat   \
                    # -usesqform                                                           \
                    # -noresample                                                          \
                    # -in   $G_OUTDIR/register_T1_to_B0/register_T1_to_B0-input.nii        \
                    # -ref  $G_OUTDIR/register_T1_to_B0/register_T1_to_B0-ref.nii          \
                    # -out  $G_OUTDIR/register_T1_to_B0/register_T1_to_B0-registered.nii.gz"                                           
    # STAGECMD=$(echo $STAGECMD | sed 's/\^/"/g')
    # stage_run "$STAGE" "$STAGECMD"                      \
                # "${G_LOGDIR}/${STAGE4PROC}.std"         \
                # "${G_LOGDIR}/${STAGE4PROC}.err"         \
         # || fatal stageRun   
    
    statusPrint "$(date) | Processing STAGE 4 - Registration | END" "\n"
fi
STAGE4OUT="$G_OUTDIR/4-$STAGE4PROC/T1_to_B0.nii"
printf "%40s"   "Checking for $STAGE4OUT"
fileExist_check  $STAGE4OUT || fatal dependencyStage

# Stage 5

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

