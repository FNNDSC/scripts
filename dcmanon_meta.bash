#!/bin/bash
#
# dcmanon_meta.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

declare -i Gi_verbose=0
declare -i Gb_useExpertOptions=0
declare -i Gb_useOverrideOut=0
declare -i Gb_forceStage=1
declare -i Gb_partialAnonymize=0
declare -i Gb_overrideMRN=0

G_LOGDIR="-x"
G_OUTDIR="$CHRIS_POSTPROC"
G_SSLCERTIFICATE="${CHRIS_DICOMROOT}/anonymize_key/CA_cert.pem"
G_OUTPREFIX="-x"
G_DIRSUFFIX=""
G_OUTPREFIX="anon-"
G_DICOMINPUTDIR="-x"
G_STAGES="1"
G_SUBJECTNAME="anonymized"
G_MRN="anonymized"

G_SYNOPSIS="

 NAME

	dcmanon_meta.bash

 SYNOPSIS

	dcmanon_meta.bash        -D <dicomInputDir>                     \\
                                [-d <dicomSeriesFile>]                  \\
                                [-v <verbosity>]                        \\
                                [-O <experimentTopDir>]                 \\
                                [-o <outputSuffix>]                     \\
                                [-p <outputPrefix>]                     \\
                                [-K <SSLCertificate>]                   \\
                                [-N <subjectName>]                      \\
                                [-M <MRN>]                              \\
                                [-P]

 DESCRIPTION

	'dcmanon_meta.bash' accepts an input directory containing DICOM
	files and anonymizes all files in the directory. Several of its
        arguments are added only for compatability with 'pl_batch.bash'.
        
        Output directory is the standard postproc stream.

 ARGUMENTS

        -v <level> (optional)
        Verbosity level.

        -D <dicomInputDir>
        The directory containing DICOM files for a particular study.

        -d <dicomSeriesFile> (Optional)
        (Ignored in dcmanon_meta.bash and used for compatability with pl_batch)

        -O <experimentTopDir> (optional) (Default: $G_OUTDIR)
        The root directory node that contains the outputs of a particular
        anonymization run. Each run is stored in its own directory.
	
        If this is specified on the command line, then output from the 
        anonymization will be written to this directory.

        -o <suffix> (Optional) 
        (Ignored in dcmanon_meta.bash and used for compatability with pl_batch)
        
        -K <SSLCertificate> (optional, default = $G_SSLCERTIFICATE)
        The anonymization process ('gdcmanon') requires an SSL certificate.  
        If requesting anonymization, the process to generate an SSL certificate 
        is described at: http://gdcm.sourceforge.net/html/gdcmanon.html
        
        -R <DIRsuffix> (Optional)
        Appends <DIRsuffix> to the postproc/<MRID> as well as <logDir>. Since
        multiple studies on the same patient can in principle have the same
        MRID, interference can result in some of the log files and source
        data. By adding this <DIRsuffix>, different analyses on the same MRID
        can be cleanly separated.

        -p <outputPrefix> (Optional)
        If specified, prefix all generated output files with <outputPrefix>.
        
        -P (Optional)
        If specified, do a partial anonymization of the data (rather than 
        doing a full DICOM-compliant anonymize, only anonymizes some of the 
        fields).

        -N <SubjName>
        In conjunction with -P, specifies the subject name field to inject
        into the anonymized DICOMS. Otherwise reverts to 'anonymous'.

        -M <MRN>
        In conjunction with -P, specifies the MRN field to inject into the
        anonymized DICOMS. Otherwise, anon MRN is a md5 hash of original MRN.

 PRECONDITIONS
	
	o FreeSurfer env -- in particular mri_probedicom 

 POSTCONDITIONS

	o Output anonymized volumes are stored in:

              <experimentTopDir>/<outputRunDir><DIRsuffix>

          and each file is prefixed by 'anon-'. If an <experimentTopDir>
	  has been explicitly set, then output files are stored directly in
	  <experimentTopDir>.

 HISTORY

	24 March 2009
	o Initial design and coding.

	08 December 2011
	o An update in output format of openssl library necessitated a
	  sed post-filter.

	03 August 2012
	o Updated help: removed mention of MatLAB since this is no longer
	  used.

    29 Jan 2014
    o Added subject override spec for anonymization.

"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///
G_SELF=`basename $0`
G_PID=$$

# Actions
A_fileCheck="checking for a required file dependency"
A_noDicomDir="checking on input DICOM directory"
A_noOutRunDir="checking on output run directory"
A_noDicomDirArg="checking on -d <dicomInputDir> argument"
A_noExpDir="checking on the output root directory"
A_metaLog="checking the meta log file"
A_dependencyStage="checking for a required dependency from an earlier stage"
A_stageRun="running a stage in the processing pipeline"

# Error messages
EM_fileCheck="it seems that a dependency is missing."
EM_noDicomDir="I couldn't access the input DICOM dir. Does it exist?"
EM_noOutRunDir="I couldn't access the output run dir. Does it exist?"
EM_noDicomDirArg="it seems as though you didn't specify a -D <dicomInputDir>."
EM_noExpDir="I couldn't find the <expDir>."
EM_metaLog="it seems as though this stage has already run.\n\tYou can force execution with a '-F'"
EM_dependencyStage="it seems that a stage dependency is missing."
EM_stageRun="I encountered an error processing this stage."

# Error codes
EC_fileCheck=1
EC_dependencyStage=2
EC_stageRun=30
EC_noDicomDir=50
EC_noOutRunDir=54
EC_noDicomDirArg=51
EC_noExpDir=23
EC_metaLog=80

# Defaults
D_whatever=

###\\\
# Function definitions
###///


###\\\
# Process command options
###///

while getopts D:Ev:O:o:p:t:R:d:K:PM:N: option ; do 
	case "$option"
	in
                D)      G_DICOMINPUTDIR=$OPTARG         ;;
                E)      Gb_useExpertOptions=1           ;;
                v)      let Gi_verbose=$OPTARG          ;;
                O)      Gb_useOverrideOut=1
                        G_OUTDIR=$OPTARG                ;;
                o)      G_OUTSUFFIX="$OPTARG"           ;;
                p)      G_OUTPREFIX="$OPTARG"           ;;
                R)      G_DIRSUFFIX=$OPTARG             ;;
                K)      G_SSLCERTIFICATE=$OPTARG        ;;
                t)      G_STAGES="$OPTARG"              ;;
                P)      Gb_partialAnonymize=1           ;;
                M)      G_MRN=$OPTARG
                        Gb_overrideMRN=1                ;;
                N)      G_SUBJECTNAME="$OPTARG"         ;;
                d)      NOP                             ;;
		\?)     synopsis_show 
                        exit 0;;
	esac
done

verbosity_check
topDir=$(pwd)

cprint  "hostname"      "[ $(hostname) ]"

## Check on script preconditions
REQUIREDFILES="gdcmanon mri_probedicom"
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

cd ${G_DICOMINPUTDIR}
statusPrint     "Scanning <dicomInputDir>"
ret_check $?
SCANTABLE=$(dcm_mkIndx.bash -t '_' 2>/dev/null)
cd $topDir

if [[ $G_OUTPREFIX == "-x" ]] ; then
  G_OUTPREFIX="$INPUTSCAN-To-$REFSCAN"
fi

statusPrint     "Checking on <outputRunDir>"
if (( !Gb_useOverrideOut )) ; then
  MRID=$(echo "$SCANTABLE" | grep ID | awk '{print $3}')
  G_OUTRUNDIR=${MRID}${G_DIRSUFFIX}/anonymized
fi
dirExist_check ${G_OUTDIR}/$G_OUTRUNDIR "not found - creating"  \
              || mkdir -p ${G_OUTDIR}/$G_OUTRUNDIR              \
              || fatal noOutRunDir
cd ${G_OUTDIR}/$G_OUTRUNDIR >/dev/null
OUTDIR=$(pwd)
lprint "Anonymized directory" 
rprint "[ $OUTDIR ]"
cd $topDir

## Check which stages to process
statusPrint     "Checking which stages to process"
barr_stage=([0]=0 [1]=0 [2]=0 [3]=0 [4]=0 [5]=0)
for i in $(seq 1 1) ; do
        b_test=$(expr index $G_STAGES "$i")
        if (( b_test )) ; then b_flag="1" ; else b_flag="0" ; fi
        barr_stage[$i]=$b_flag
done
ret_check $?

G_LOGDIR=$OUTDIR
STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($(pwd)) $G_SELF $*" $STAMPLOG

STAGENUM="1"
STAGEPROC=gdcmanon
STAGE=${STAGENUM}-${STAGEPROC}
STAGE1RELDIR=${G_OUTRUNDIR}
STAGE1FULLDIR=${OUTDIR}
statusPrint     "Checking stage 1 output dir"
dirExist_check ${STAGE1FULLDIR} "not found - creating"        \
            || mkdir -p ${STAGE1FULLDIR}                      \
            || fatal noOutRunDir
if (( ${barr_stage[1]} )) ; then
    cd $STAGE1FULLDIR
    statusPrint "$(date) | Processing STAGE 1 - anonymizing DICOM dir | START" "\n"

    # If partial anonymize was requested, just substitute some essential tags
    # such as PatientsName, birthday, etc.
    if ((Gb_partialAnonymize)) ; then
        for FILE in $G_DICOMINPUTDIR/*.dcm ; do
            FILEBASE=$(basename $FILE)
            TAG=$(mri_probedicom --i $FILE --t 0010 0020)
            if (( Gb_overrideMRN )) ; then
                MD5=$G_MRN
            else
                MD5=$(echo $TAG | openssl md5 | sed 's/^.*= *//' | sed 's/[ \t]*$//')
            fi
            printf "$TAG --> %s\n" "$MD5"
            STAGECMD="echo $MD5 |                                             \
                      xargs -i% $STAGEPROC                                    \
                            --dumb                                            \
                            --replace 0010,0010,$G_SUBJECTNAME                \
                            --replace 0010,0020,%                             \
                            --replace 0010,0030,19000101                      \
                            --replace 0008,1030,anonymized                    \
                            --replace 0032,1030,anonymized                    \
                            --replace 0032,1060,anonymized                    \
                            -i $FILE -o $STAGE1FULLDIR/$FILEBASE"
            stage_run "$STAGE-$FILEBASE"  "$STAGECMD"               \
                  "${STAGE1FULLDIR}/${STAGEPROC}.std"               \
                  "${STAGE1FULLDIR}/${STAGEPROC}.err"               \
                  "SILENT"                                          \
                  || fatal stageRun
    	done    
    # Do a full DICOM-compliant anonymize
    else
        STAGECMD="$STAGEPROC -c $G_SSLCERTIFICATE -i $G_DICOMINPUTDIR -o $STAGE1FULLDIR --continue"
        stage_run "$STAGE"  "$STAGECMD"                             \
                  "${STAGE1FULLDIR}/${STAGEPROC}.std"               \
                  "${STAGE1FULLDIR}/${STAGEPROC}.err"               \
                  "SILENT"                                          \
                  || fatal stageRun
	    
    fi
        	
    
    statusPrint "$(date) | Processing STAGE 1 - anonymizing DICOM dir | END" "\n"
fi

cd $topDir
verbosity_check
shut_down 0
