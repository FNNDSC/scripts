#!/bin/bash
#
# dcmsend_meta.bash
#
# Copyright 2010 Rudolph Pienaar
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
declare -i Gb_customStorescu=0
declare -i Gb_anonymize=0
declare -i Gb_partialAnonymize=0

declare -i Gb_mailAll=0
declare -i Gb_mailStd=0
declare -i Gb_mailErr=0
declare -i Gb_mailLog=0

declare -i Gb_runCluster=0

declare -i Gb_useDICOMFile=0

G_LOGDIR="-x"
G_OUTDIR=$CHRIS_POSTPROC
G_OUTSUFFIX=""
G_DIRSUFFIX=""
G_DICOMINPUTDIR="-x"
G_DICOMINPUTFILE="-x"
G_DICOMSERIESLIST="*"
G_SSLCERTIFICATE="${CHRIS_DICOMROOT}/CA_cert.pem"
G_MIGRATEANALYSISDIR="-x"

G_STORESCU="storescu"
G_FILEEXT=""
G_HOST=localhost
G_AETITLE=$CHRIS_AETITLE
G_LISTENPORT=11112

G_CLUSTERNAME=$CHRIS_CLUSTER
G_CLUSTERDIR=$CHRIS_CLUSTERDIR
G_SCHEDULELOG="schedule.log"
G_MAILTO=$CHRIS_ADMINUSERS
G_DCM_MKINDX="dcm_mkIndx.bash"

G_STAGES="12"

G_CLUSTERUSER=""

G_SYNOPSIS="

 NAME

        dcmsend_meta.bash

 SYNOPSIS

        dcmsend_meta.bash       -D <dicomInputDir>                      \\
                                [-S <dicomSeriesList>]                  \\
                                [-d <dicomSeriesFile>]                  \\
                                [-a <aetitle>]                          \\
                                [-h <dicomHost>]                        \\
                                [-p <listenPort>]                       \\
                                [-s <storescu>]                         \\
                                [-K <SSLCertificate>]                   \\
                                [-A]                                    \\
                                [-P]                                    \\
                                [-L <logDir>]                           \\
                                [-v <verbosity>]                        \\
                                [-O <outputDir>] [-o <suffix>]          \\
                                [-R <DIRsuffix>]                        \\
                                [-t <stage>] [-f]                       \\
                                [-c] [-C <clusterDir>]                  \\
                                [-M | -m <mailReportsTo>]               \\
                                [-n <clusterUserName>]                  \\
                                [--migrate-analysis <migrateDir>]       \\

 DESCRIPTION

        'dcmsend_meta.bash' is the meta shell controller for a wrapper 
        that recursively sends a group of directories containing DICOM 
        images to a remote PACS server.

PRECONDITIONS

        o common.bash script source.        

 ARGUMENTS

        -v <level> (Optional)
        Verbosity level. A value of '10' is a good choice here.

        -D <dicomInputDir>
        The directory to be scanned for DICOM files.
        
        -A (Optional)
        If specified, anonymize data before transmission.
        
        -P (Optional)
        If specified, do a partial anonymization of the data (similar to -A,
        but rather than doing a full DICOM-compliant anonymize, only anonymizes
        some of the fields).
        
        -E <fileExt> (Optional)
        If specified, only transmit files ending in *.<fileExt>, otherwise
        transmit all files in the target directory. Specifying the 
        <fileExt> is useful, since the transmission program will
        fail if attempting to transmit non-dicom files.

        -a <aetitle> (optional, default = $G_AETITLE)
        The aetitle of the PACS process to receive the data.
        
        -h <remoteHost> (optional, default = $G_HOST)
        The host running the PACS process, i.e. the hostname of the DICOM
        peer.

        -p <listenPort> (optional, default = $G_LISTENPORT)
        The port number on which the PACS process is listening.
        
        -K <SSLCertificate> (optional, default = $G_SSLCERTIFICATE)
        The anonymization process ('gdcmanon') requires an SSL certificate.  
        If requesting anonymization, the process to generate an SSL certificate 
        is described at: http://gdcm.sourceforge.net/html/gdcmanon.html
        
        -s <storescu> (optional, default = $G_STORESCU)
        Use this option to specify a <storescu> binary, typically used
        if <storescu> is not on the standard PATH. The basename of
        <storescu> is assumed to also contain any necessary libraries.        
        
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
        
        [--migrate-analysis <migrateDir>] (Optional)
        This option allows the specification of an alternative directory
        to <outputDir> where the processing occurs.  Basically what will
        happen is the input scans are copied to <migrateDir>, processing
        is done, and the files are then moved over back to the <outDir>
        when finished.  The purpose of this is to allow for use of
        cluster storage for doing processing automatically.        

STAGES

        'dcmsend_meta.bash' offers the following stages:

        1 - dicom_seriesCollect.bash
                Collect the files that need to be sent
        2 - dicom_dirSend.bash
                Send DICOM series to remote host
        
 HISTORY

        10 March 2010
        o Initial design and coding.

        14 March 2012
        o Updates and re-testing.
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///

# Actions
A_fileCheck="checking for a required file dependency"
A_metaLog="checking the tract_meta.bash.log file"
A_badLogDir="checking on the log directory"
A_badLogFile="checking on the log file"
A_dependencyStage="checking for a required dependency from an earlier stage"
A_stageRun="running a stage in the processing pipeline"
A_noDicomDir="checking on input DICOM directory"
A_noDicomFile="checking on input DICOM directory / file"
A_noDicomDirArg="checking on -d <dicomInputDir> argument"
A_badMigrateDir="checking on --migrate-analysis <migrateDir>"

# Error messages
EM_fileCheck="it seems that a dependency is missing."
EM_metaLog="it seems as though this stage has already run.\n\tYou can force execution with a '-f'"
EM_badLogDir="I couldn't access the <logDir>. Does it exist?"
EM_badLogFile="I couldn't access a specific log file. Does it exist?"
EM_dependencyStage="it seems that a stage dependency is missing."
EM_stageRun="I encountered an error processing this stage."
EM_noDicomDir="I couldn't access the input DICOM dir. Does it exist?"
EM_noDicomFile="I couldn't find any DICOM *dcm files. Do any exist?"
EM_noDicomDirArg="it seems as though you didn't specify a -D <dicomInputDir>."
EM_badMigrateDir="I couldn't access <migrateDir>"

# Error codes
EC_fileCheck=1
EC_dependencyStage=2
EC_metaLog=80
EC_badLogDir=20
EC_badLogFile=21
EC_stageRun=30
EC_noDicomDir=50
EC_noDicomDirArg=51
EC_noDicomFile=52
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
    MRID=$(eval $G_DCM_MKINDX | grep "Patient ID" | awk '{print $3}')
    cd $here >/dev/null
    echo $MRID
}


###\\\
# Process command options
###///

while getoptex "v: D: d: A P L: O: R: o: f S: t: c C: \
                n: M: m: a: h: p: K: x                \
                migrate-analysis:" "$@" ; do
        case "$OPTOPT"
        in
            v)      Gi_verbose=$OPTARG              ;;
            a)      G_AETITLE=$OPTARG               ;;
            h)      G_HOST=$OPTARG                  ;;
            p)      G_LISTENPORT=$OPTARG            ;;
            K)      G_SSLCERTIFICATE=$OPTARG        ;;
            D)      G_DICOMINPUTDIR=$OPTARG         ;;
            d)      Gb_useDICOMFile=1               
                    G_DICOMINPUTFILE=$OPTARG        ;;
            L)      G_LOGDIR=$OPTARG                ;;
            O)      Gb_useOverrideOut=1     
                    G_OUTDIR=$OPTARG                ;;
            R)      G_DIRSUFFIX=$OPTARG             ;;
            o)      G_OUTSUFFIX=$OPTARG             ;;
            A)      Gb_anonymize=1                  ;;
            P)      Gb_partialAnonymize=1           ;;
            S)      G_DICOMSERIESLIST=$OPTARG       ;;
            f)      Gb_forceStage=1                 ;;
            t)      G_STAGES=$OPTARG                ;;
            c)      Gb_runCluster=1                 ;;
            C)      G_CLUSTERDIR=$OPTARG            ;;
            M)      Gb_mailStd=1
                    Gb_mailErr=1
                    G_MAILTO=$OPTARG                ;;
            m)      Gb_mailStd=1
                    Gb_mailErr=0
                    G_MAILTO=$OPTARG                ;;
            n)      G_CLUSTERUSER=$OPTARG           ;;
            migrate-analysis)
                    G_MIGRATEANALYSISDIR=$OPTARG    ;;                    
            x|\?)   synopsis_show 
                    exit 0;;
        esac
done

verbosity_check
topDir=$(pwd)
echo ""
cprint  "hostname"      "[ $(hostname) ]"

## Check on script preconditions
REQUIREDFILES="common.bash dicom_seriesCollect.bash dicom_dirSend.bash"
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
MRID=$(MRID_find $G_DICOMINPUTDIR)
cprint "MRID" "[ $MRID ]"
statusPrint     "Checking on <dicomInputDir>/<dcm> file"
DICOMTOPFILE=$(ls -1 ${G_DICOMINPUTDIR}/*.dcm 2>/dev/null | head -n 1)
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
  cluster_schedule "$*" "dcmsend"
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
    EXOPTS=""
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
        awk -F \| '{print $4}'                          |\
        sed 's/^[ \t]*//;s/[ \t]*$//')

if (( ! ${#STAGE1DIR} )) ; then fatal dependencyStage; fi

G_OUTDIR=$(dirname $STAGE1DIR)
STAGE1OUT=$STAGE1DIR

# Stage 2
STAGE2IN=$STAGE1OUT
STAGE2PROC=dicom_dirSend.bash
STAGE=2-$STAGE2PROC
STAGE2DIR="${G_OUTDIR}/dcmsend_meta-stage-$STAGE"
if (( ${barr_stage[2]} )) ; then
    statusPrint "$(date) | Processing STAGE 2 - DICOM Send | START" "\n"
    statusPrint "Checking previous stage dependencies"
    
    statusPrint "Checking stage output root directory"
    dirExist_check $STAGE2DIR "created" || mkdir $STAGE2DIR
    ANONFLAGS=""
    if (( Gb_partialAnonymize )) ; then
        ANONFLAGS=" -P -K $G_SSLCERTIFICATE"
    elif (( Gb_anonymize )) ; then
        ANONFLAGS=" -A -K $G_SSLCERTIFICATE"
    fi
    
    STAGECMD="$STAGE2PROC                               \
                -v 10                                   \
                -a $G_AETITLE                           \
                -h $G_HOST                              \
                -p $G_LISTENPORT                        \
                $ANONFLAGS                              \
                -E dcm                                  \
                $STAGE2IN"
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE2PROC}.std"         \
                "${G_LOGDIR}/${STAGE2PROC}.err"         \
         || fatal stageRun
                  
    statusPrint "$(date) | Processing STAGE 2 - DICOM Send | END" "\n"
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

mail_reports "$G_MAILTO" "$Gb_mailStd" "$Gb_mailErr"
shut_down 0

