#!/bin/bash
#
# asladc_b0_process.bash
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

declare -i Gb_mailAll=0
declare -i Gb_mailStd=0
declare -i Gb_mailErr=0
declare -i Gb_mailLog=0

declare -i Gb_runCluster=0

G_LOGDIR="-x"
G_OUTDIR="/chb/users/dicom/postproc"
G_OUTRUNDIR="-x"
G_OUTPREFIX="-x"
G_DIRSUFFIX=""
G_DICOMINPUTDIR="-x"
G_DICOMINPUTASLFILE="-x"
G_DICOMINPUTADCFILE="-x"
G_DICOMINPUTB0FILE="-x"
G_BETOPT="-x"
G_MATLAB="/chb/pices/arch/x86_64-Linux/bin/matlab"
G_ASLOFFSET="-2.5"
G_ADCOFFSET="-2.5"
G_STAGES="12345"

G_CLUSTERDIR=${G_OUTDIR}/seychelles
G_SCHEDULELOG="schedule.log"
G_MAILTO="rudolph@nmr.mgh.harvard.edu"

G_SYNOPSIS="

 NAME

	asladc_b0_process

 SYNOPSIS

	asladc_b0_process       -D <dicomInputDir>                      \\
                                -S <ASLdicom>                           \\
                                -C <ADCdicom>                           \\
                                -B <B0dicom>                            \\
                                [-s <asloffset>]			\\
                                [-a <adcoffset>]			\\
                                [-t <STAGES>]				\\
                                [-E]                                    \\
                                [-v <verbosity>]  			\\
				[-O <experimentTopDir>]			\\
				[-R <DIRsuffix>				\\
                                [-o <outputRunDir>]			\\
                                [-p <outputPrefix>]			\\
                                [-c] [-C <clusterDir>                   \\
                                [-M | -m <mailReportsTo>]

 DESCRIPTION

	'asladc_b0_process' analyzes ASL and ADC volumes and searches
        for any locational intensity correlation.

        Both ASL and ADC volumes are first co-registered to a B0 volume,
        which is then masked to remove the brain. This mask is applied
        to the registered ASL and ADC volumes.
        
        Finally, these registered and masked volumes are analyzed for
        correlations.

 ARGUMENTS

	-v <level> (optional)
	Verbosity level.

        -D <dicomInputDir>
        The directory containing DICOM files for a particular study.

        -S <ASLdicom> 
        A file in <dicomInputDir> specifying the ASL volume to use.

        -C <ADCdicom>
        A file in <dicomInputDir> specifying the ADC volume to use.
        
        -B <B0dicom>
        A file in <dicomInputDir> specifying the B0 volume to use

	-s <asloffset> (Optional, default: $G_ASLOFFSET)
	The filter offset to use to tag ASL regions. This offset tags
	all intensities that exceeed (ASLmean + <asloffset> * ASLstd)

	-a <adcoffset> (Optional, default: $G_ADCOFFSET)
	The filter offset to use to tag ADC regions. This offset tags
	all intensities that exceeed (ADCmean + <adcoffset> * ADCstd)

        -E (Optional)
        Use 'expert' option files. For each processing run, if this flag
        is indicated, the output directory will be scanned for any files
        named <STAGEPROC>.opt -- which if found will be parsed and their
        contents appended *blindly* to the <STAGECMD> for that stage.

        -O <experimentTopDir> (Optional) (Default: $G_OUTDIR)
        The root directory node that contains the outputs of a particular
        registration run. Each run is stored in its own directory.

        -o <outputRunDir> 
	If specified, set the output directory directly to 
	<experimentTopDir>/<outputRunDir>, else construct output run dir
	from MRID.

        -R <DIRsuffix> (Optional)
        Appends <DIRsuffix> to the postproc/<MRID> as well as <logDir>. Since
        multiple studies on the same patient can in principle have the same
        MRID, interference can result in some of the log files and source
        data. By adding this <DIRsuffix>, different analyses on the same MRID
        can be cleanly separated.

        -p <outputPrefix> (Optional)
        If specified, prefix all generated output files with <outputPrefix>.

	-t <STAGES> (Optional) (Default: $G_STAGES)
	Stages to execute.

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

 STAGES

	1 - dcm_coreg.bash
	    Register the ADC and ASL volumes to the B0 volume.
	2 - bet
	    Perform a brain extraction on the B0 volume.
	3 - mris_calc
	    Mask the brain extracted B0 on the ADC and the ASL volumes.
	4 - mri_convert / mris_calc
	    Convert volumes to float format and normalize the ADC and ASL 
	    masks.
	5 - MatLAB
	    Perform the correlation analysis.

 PRECONDITIONS
	
	o nde

 POSTCONDITIONS

	o Output registered volumes (and matrices) are stored in:

              <experimentTopDir>/<outputRunDir>

          with the output volume and output matrix files: 
              <outputPrefix>-registered.[{img}{mat}] 

 HISTORY

	02 December 2008
	o Initial design and coding.

"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///
G_SELF=`basename $0`
G_PID=$$

# Actions
A_fileCheck="checking for a required file dependency"
A_noDicomDir="checking on input DICOM directory"
A_noOutRootDir="checking on output root directory"
A_noOutRunDir="checking on output run directory"
A_noDicomFile="checking on input DICOM file"
A_noDicomASLFile="checking on input DICOM ASL file"
A_noDicomADCFile="checking on input DICOM ADC file"
A_noDicomB0File="checking on input DICOM B0 file"
A_noDicomDirArg="checking on -d <dicomInputDir> argument"
A_noExpDir="checking on the output root directory"
A_metaLog="checking the meta log file"
A_dependencyStage="checking for a required dependency from an earlier stage"
A_stageRun="running a stage in the processing pipeline"

# Error messages
EM_fileCheck="it seems that a dependency is missing."
EM_noDicomDir="I couldn't access the input DICOM dir. Does it exist?"
EM_noOutRootDir="I couldn't access the output root dir. Does it exist?"
EM_noOutRunDir="I couldn't access the output run dir. Does it exist?"
EM_noDicomASLFile="I couldn't find the input DICOM file. Does it exist?"
EM_noDicomADCFile="I couldn't find the input DICOM file. Does it exist?"
EM_noDicomB0File="I couldn't find the input DICOM file. Does it exist?"
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
EC_noOutRootDir=54
EC_noOutRunDir=55
EC_noDicomDirArg=51
EC_noDicomADCFile=52
EC_noDicomASLFile=53
EC_noDicomB0File=54
EC_noExpDir=23
EC_metaLog=80

# Defaults
D_whatever=

function matlab_scriptCreate
{
    local BASEDIR=$1
    local SCRIPT=$2

    ROOTDIR=$(dirname $BASEDIR)
    
    cat > $SCRIPT <<-end-of-script
function [c]    = $(basename $SCRIPT .m)()
    c = basac_process();
    c = basac_initialize(c, 'default');

    cd('${ROOTDIR}/asladc-2-bet');
    c = set(c, 'b0_dir',  			pwd);
    c = set(c, 'b0_file', 			'B0_brain_mask.img');

    cd('../asladc-4-mri_convert');
    c = set(c, 'asladc_dir',  			pwd);
    c = set(c, 'asl_file',    			'ASL-B0_masked.f.norm.mgz');
    c = set(c, 'adc_file',    			'ADC-B0_masked.f.norm.mgz');
    c = set(c, 'asl_orig',                      'ASL-B0_masked.fgte0.mgz');
    c = set(c, 'adc_orig',                      'ADC-B0_masked.fgte0.mgz');
    c = set(c, 'asl_origScale',                 0.1);
    c = set(c, 'adc_origScale',                 1.0);

    c = set(c, 'mb_ADCsuppressCSF',		 1);
    c = set(c, 'stdOffsetADCCSF',		 1.5);
    c = set(c, 'stdOffsetADC', 			$G_ADCOFFSET);
    c = set(c, 'stdOffsetASL', 			$G_ASLOFFSET);
    c = set(c, 'filterOnRawROI',                0);

    c = set(c, 'binarizeMasks',			1);
    c = set(c, 'registrationPenalize',		1);
    c = set(c, 'registrationPenalizeFunc',	'sigmoid');
    c = set(c, 'ROIfilterCount',		-1);
    
    c = set(c, 'kernelADC',     		7);
    c = set(c, 'kernelASL',     		11);

    c = set(c, 'showVolumes',         		0);
    c = set(c, 'showScatter',         		0);
    c = set(c, 'showMaxCorrelation',  		0);
    c = set(c, 'mb_imagesSave',       		0);

    c = run(c);
    cd('../asladc-5-matlab');
end
end-of-script

}

###\\\
# Function definitions
###///

function niigz2img
{
    # ARGS
    # $1            in              working directory
    #
    # DESC
    # Converts any *.nii.gz files to img format.
    #

    local DIR=$1

    # Check for any nii.gz files
    for NIIGZ in ${DIR}/*nii.gz ; do
	lprint	"Converting $(basename $NIIGZ)"
	STEM=$(basename $NIIGZ .nii.gz)
	mri_convert $NIIGZ ${DIR}/${STEM}.img			\
	    > ${DIR}/mri_convert.std				\
	    2>${DIR}/mri_convert.err
	rprint "[ ok ]"
    done
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

while getopts D:S:C:B:s:a:Ev:O:o:p:t:R:cC:M:m: option ; do 
	case "$option"
	in
                D)      G_DICOMINPUTDIR=$OPTARG         ;;
                S)      G_DICOMINPUTASLFILE=$OPTARG     ;;
                C)      G_DICOMINPUTADCFILE=$OPTARG     ;;
                B)      G_DICOMINPUTB0FILE=$OPTARG      ;;
                s)	G_ASLOFFSET=$OPTARG		;;
                a)	G_ADCOFFSET=$OPTARG		;;
                E)      Gb_useExpertOptions=1           ;;
                v)      let Gi_verbose=$OPTARG          ;;
		O)      G_OUTDIR=$OPTARG                ;;
		o)	let Gb_useOverrideOut=1
			G_OUTRUNDIR="$OPTARG"           ;;
                p)      G_OUTPREFIX="$OPTARG"           ;;
                R)	G_DIRSUFFIX=$OPTARG		;;
                t)      G_STAGES="$OPTARG"              ;;
                c)      Gb_runCluster=1                 ;;
                C)      G_CLUSTERDIR=$OPTARG            ;;
                M)      Gb_mailStd=1
                        Gb_mailErr=1
                        G_MAILTO=$OPTARG                ;;
                m)      Gb_mailStd=1
                        Gb_mailErr=0
                        G_MAILTO=$OPTARG                ;;
		\?)     synopsis_show 
                        exit 0;;
	esac
done

verbosity_check
topDir=$(pwd)

printf "\n"
cprint  "hostname"      "[ $(hostname) ]"

## Check on script preconditions
REQUIREDFILES="bet dcm_coreg.bash mris_calc"
for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file"
        file_checkOnPath $file || fatal fileCheck
done

## TOC
statusPrint     "Checking on <dicomInputDir>/<dcm> file"
DICOMTOPFILE=$(ls -1 ${G_DICOMINPUTDIR}/*1.dcm 2>/dev/null | head -n 1)
fileExist_check $DICOMTOPFILE || fatal noDicomFile

## Check on DICOM meta data
statusPrint     "Querying <dicomInputDir> for sequences"
G_DCM_MKINDX=$(dcm_mkIndx.bash -i $DICOMTOPFILE)
ret_check $?

## MRID
MRID=$(MRID_find $G_DICOMINPUTDIR)
cprint          "MRID"          "[ $MRID ]"

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
SCANTABLE=$(dcm_mkIndx.bash -t '_')

statusPrint     "Checking input ASL volume"
DICOMINPUTASL=${G_DICOMINPUTDIR}/${G_DICOMINPUTASLFILE}
fileExist_check $DICOMINPUTASL || fatal noDicomASLFile
ASLSCAN=$(echo "$SCANTABLE" | grep $G_DICOMINPUTASLFILE | awk '{print $3}')
cprint "ASL scan"     "[ $ASLSCAN ]"

statusPrint     "Checking input ADC volume"
DICOMINPUTADC=${G_DICOMINPUTDIR}/${G_DICOMINPUTADCFILE}
fileExist_check $DICOMINPUTADC || fatal noDicomADCFile
ADCSCAN=$(echo "$SCANTABLE" | grep $G_DICOMINPUTADCFILE | awk '{print $3}')
cprint "ADC scan" "[ $ADCSCAN ]"

statusPrint     "Checking input B0 volume"
DICOMINPUTB0=${G_DICOMINPUTDIR}/${G_DICOMINPUTB0FILE}
fileExist_check $DICOMINPUTB0 || fatal noDicomB0File
B0SCAN=$(echo "$SCANTABLE" | grep $G_DICOMINPUTB0FILE| awk '{print $3}')
cprint "B0 scan" "[ $B0SCAN ]"

cprint 	"ASL offset"	"[ $G_ASLOFFSET ]"
cprint	"ADC offset"	"[ $G_ADCOFFSET	]"

if [[ $G_OUTPREFIX == "-x" ]] ; then
  G_OUTPREFIX="$INPUTSCAN-To-$REFSCAN"
fi

lprint		"Checking on output root dir"
dirExist_check ${G_OUTDIR} "not found - creating"  \
              || mkdir -p ${G_OUTDIR}              \
              || fatal noOutRootDir

statusPrint     "Checking on <outputRunDir>"
if (( !Gb_useOverrideOut )) ; then
  MRID=$(echo "$SCANTABLE" | grep "Patient ID" | awk '{print $3}')
  G_OUTRUNDIR=${MRID}${G_DIRSUFFIX}/asladc
fi
dirExist_check ${G_OUTDIR}/$G_OUTRUNDIR "not found - creating"  \
              || mkdir -p ${G_OUTDIR}/$G_OUTRUNDIR              \
              || fatal noOutRunDir
cd ${G_OUTDIR}/$G_OUTRUNDIR >/dev/null
OUTDIR=$(pwd)
echo $OUTDIR
cd $topDir

## Check which stages to process
statusPrint     "Checking which stages to process"
barr_stage=([0]=0 [1]=0 [2]=0 [3]=0 [4]=0 [5]=0)
for i in $(seq 1 5) ; do
        b_test=$(expr index $G_STAGES "$i")
        if (( b_test )) ; then b_flag="1" ; else b_flag="0" ; fi
        barr_stage[$i]=$b_flag
done
ret_check $?

G_LOGDIR=$OUTDIR
STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($(pwd)) $G_SELF $*" $STAMPLOG

STAGENUM="asladc-1"
STAGEPROC="dcm_coreg.bash"
STAGE=${STAGENUM}-${STAGEPROC}
STAGE1RELDIR=${G_OUTRUNDIR}/${STAGE}
STAGE1FULLDIR=${OUTDIR}/${STAGE}
statusPrint     "Checking stage 1 output dir"
dirExist_check ${OUTDIR}/${STAGE} "not found - creating"        \
            || mkdir -p ${OUTDIR}/${STAGE}                      \
            || fatal noOutRunDir
if (( ${barr_stage[1]} )) ; then
  for VOL in ADC ASL; do
    statusPrint \
        "$(date) | Processing STAGE 1 - ${VOL}-->B0... | START" "\n"
    if [[ $VOL == ADC ]] ; then INPUTDICOM=$G_DICOMINPUTADCFILE ; fi
    if [[ $VOL == ASL ]] ; then INPUTDICOM=$G_DICOMINPUTASLFILE ; fi
    statusPrint "Registering ${VOL} to B0"                 "\n"
    STAGECMD="$STAGEPROC                                                \
              -v 10                                                     \
              -D $G_DICOMINPUTDIR                                       \
              -d $INPUTDICOM                                            \
              -r $G_DICOMINPUTB0FILE                                    \
              -o ${STAGE1RELDIR}"
    stage_run   "$STAGE" "$STAGECMD"                                    \
                "${STAGE1FULLDIR}/${STAGEPROC}.std"                     \
                "${STAGE1FULLDIR}/${STAGEPROC}.err"                     \
                "SILENT"                                                \
                || fatal stageRun
    # Check for any nii.gz files
    niigz2img $STAGE1FULLDIR
    statusPrint \
        "$(date) | Processing STAGE 1 - ${VOL}-->B0... | END" "\n"
  done
fi

STAGE1OUT=$(ls -1 $STAGE1FULLDIR/*-ref.img | head -n 1)
STAGE1OUTFULLBASE=${STAGE1FULLDIR}/$(basename $STAGE1OUT .img)
STAGE1OUTBASE=$(basename $STAGE1OUT .img)
STAGE2IN=$STAGE1OUT
STAGENUM="asladc-2"
STAGEPROC=bet
STAGE=${STAGENUM}-${STAGEPROC}
STAGE2RELDIR=${G_OUTRUNDIR}/${STAGE}
STAGE2FULLDIR=${OUTDIR}/${STAGE}
statusPrint     "Checking stage 2 output dir"
dirExist_check ${STAGE2FULLDIR} "not found - creating"        \
            || mkdir -p ${STAGE2FULLDIR}                      \
            || fatal noOutRunDir
if (( ${barr_stage[2]} )) ; then
    cd $STAGE2FULLDIR
    statusPrint "$(date) | Processing STAGE 2 - B0 bet | START" "\n"
    statusPrint "Checking previous stage dependencies" 
    fileExist_check     $STAGE2IN       || fatal dependencyStage
    cp ${STAGE1OUTFULLBASE}* ${STAGE2FULLDIR}
    for ext in hdr img mat ; do
      mv ${STAGE2FULLDIR}/${STAGE1OUTBASE}*${ext} ${STAGE2FULLDIR}/B0.${ext}
    done
    EXOPTS=$(eval expertOpts_parse ${STAGEPROC})
    STAGECMD="$STAGEPROC                                        \
                ${STAGE2FULLDIR}/B0.img                         \
                ${STAGE2FULLDIR}/B0_brain.img                   \
                -m                                              \
                $EXOPTS"
    stage_run "$STAGE"  "$STAGECMD"                             \
              "${STAGE2FULLDIR}/${STAGEPROC}.std"               \
              "${STAGE2FULLDIR}/${STAGEPROC}.err"               \
              "SILENT"                                          \
              || fatal stageRun
    niigz2img $STAGE2FULLDIR
    statusPrint "$(date) | Processing STAGE 2 - B0 bet | END" "\n"
fi

STAGE2OUT=${STAGE2FULLDIR}/B0_brain_mask.img
STAGE2OUTFULLBASE=${STAGE2FULLDIR}/$(basename $STAGE2OUT .img)
STAGE2OUTBASE=$(basename $STAGE2OUT .img)
STAGE3IN=$STAGE2OUT
STAGENUM="asladc-3"
STAGEPROC=mris_calc
STAGE=${STAGENUM}-${STAGEPROC}
STAGE3RELDIR=${G_OUTRUNDIR}/${STAGE}
STAGE3FULLDIR=${OUTDIR}/${STAGE}
statusPrint     "Checking stage 3 output dir"
dirExist_check ${STAGE3FULLDIR} "not found - creating"        \
            || mkdir -p ${STAGE3FULLDIR}                      \
            || fatal noOutRunDir
if (( ${barr_stage[3]} )) ; then
    cd $STAGE3FULLDIR
    statusPrint "$(date) | Processing STAGE 3 - mask ADC and ASL | START" "\n"
    statusPrint "Checking previous stage dependencies"
    fileExist_check     $STAGE3IN       || fatal dependencyStage
    cp ${STAGE2OUTFULLBASE}* ${STAGE3FULLDIR}
    cp ${STAGE1FULLDIR}/*registered* ${STAGE3FULLDIR}
    rm ${STAGE3FULLDIR}/*mat
    ADC=${STAGE3FULLDIR}/*ADC*registered.img
    ASL=${STAGE3FULLDIR}/*ASL*registered.img
    B0=${STAGE3FULLDIR}/B0*img
    EXOPTS=$(eval expertOpts_parse $STAGEPROC)
    for VOL in ADC ASL ; do
      if [[ $VOL == ADC ]] ; then SRC=$ADC ; else SRC=$ASL ; fi
      STAGECMD="$STAGEPROC                                      \
                $EXOPTS                                         \
                -o ${VOL}-B0_masked.img                         \
                $SRC masked $B0"
      stage_run "$STAGE"  "$STAGECMD"                           \
              "${STAGE3FULLDIR}/${STAGEPROC}.std"               \
              "${STAGE3FULLDIR}/${STAGEPROC}.err"               \
              "SILENT"                                          \
              || fatal stageRun
    done
    statusPrint "$(date) | Processing STAGE 3 - mask ADC and ASL | END" "\n"
fi

# STAGE3OUT=${STAGE3FULLDIR}/ADC-B0_masked.img
# STAGE3OUTFULLBASE=${STAGE3FULLDIR}/$(basename $STAGE3OUT .img)
# STAGE3OUTBASE=$(basename $STAGE3OUT .img)
# STAGE4IN=$STAGE3OUT
# STAGENUM="asladc-4"
# STAGEPROC=mris_calc
# STAGE=${STAGENUM}-${STAGEPROC}
# STAGE4RELDIR=${G_OUTRUNDIR}/${STAGE}
# STAGE4FULLDIR=${OUTDIR}/${STAGE}
# statusPrint     "Checking stage 4 output dir"
# dirExist_check ${STAGE4FULLDIR} "not found - creating"        \
#             || mkdir -p ${STAGE4FULLDIR}                      \
#             || fatal noOutRunDir
# if (( ${barr_stage[0]} )) ; then
#     #
#     # The ADC volumes can have negative intensity values (this follows from 
#     # the ADC equation). When normalizing intensity values between 0 and 1,
#     # background pixels (originally with intensity=0) inherit some positive
#     # offset concordant with the relative offset to the original most negative
#     # intensity. In order to normalize correctly and maintain full dynamic
#     # contrast range, we remap the original background intensities to a value
#     # just less than the min(ADC) value. Normalization then results in
#     # background pixels correctly set at zero.
#     # 
#     # Essentially:
#     # Mneg      = Mask * -1
#     # Mflip     = Mneg + 1
#     # f_min     = min(ADC)
#     # Mbremap   = Mflip * (f_min - 1)
#     # ADCremap  = ADC + Mbremap
#     #
#     #
#     cd $STAGE4FULLDIR
#     statusPrint "$(date) | Processing STAGE 4 - remapping and normalizing ADC | START" "\n"
#     statusPrint "Checking previous stage dependencies"
#     fileExist_check     $STAGE4IN       || fatal dependencyStage
#     cp ${STAGE3FULLDIR}/ADC-B0_masked* ${STAGE4FULLDIR}
#     cp ${STAGE2OUTFULLBASE}* ${STAGE4FULLDIR}
#     EXOPTS=$(eval expertOpts_parse $STAGEPROC)
#     MASK=${STAGE2OUTBASE}.img
# 
#     mris_calc   -o Mneg.nii     $MASK mul -1
#     mris_calc   -o Mflip.nii    Mneg.nii add 1
#     let min=$(mris_calc ADC-B0_masked.img min 2>&1 | awk '{print $3}' | awk -F\. '{print $1}')
#     let min1=$(expr $min - 1)
#     mris_calc   -o Mbremap.nii  Mflip.nii mul $min1
#     mris_calc   -o ADCremap.nii ADC-B0_masked.img add Mbremap.nii
# 
#     mri_convert -odt float ADCremap.nii ADC-B0_masked.f.nii
#     mris_calc   -o ADC-B0_masked.f.norm.nii ADC-B0_masked.f.nii norm
# 
#     statusPrint "$(date) | Processing STAGE 4 - remapping and normalizing ADC | END" "\n"
# fi

STAGE3OUT=${STAGE3FULLDIR}/ADC-B0_masked.img
STAGE3OUTFULLBASE=${STAGE3FULLDIR}/$(basename $STAGE3OUT .img)
STAGE3OUTBASE=$(basename $STAGE3OUT .img)
STAGE4IN=$STAGE3OUT
STAGENUM="asladc-4"
STAGEPROC=mri_convert
STAGE=${STAGENUM}-${STAGEPROC}
STAGE4RELDIR=${G_OUTRUNDIR}/${STAGE}
STAGE4FULLDIR=${OUTDIR}/${STAGE}
statusPrint     "Checking stage 4 output dir"
dirExist_check ${STAGE4FULLDIR} "not found - creating"        \
            || mkdir -p ${STAGE4FULLDIR}                      \
            || fatal noOutRunDir
if (( ${barr_stage[4]} )) ; then
    cd $STAGE4FULLDIR
    statusPrint "$(date) | Processing STAGE 4 - normalizing ADC and ASL | START" "\n"
    statusPrint "Checking previous stage dependencies"
    fileExist_check     $STAGE4IN       || fatal dependencyStage
    cp ${STAGE3FULLDIR}/*-B0_masked* ${STAGE4FULLDIR}
    cp ${STAGE2FULLDIR}/B0_brain_mask* ${STAGE4FULLDIR}
    EXOPTS=$(eval expertOpts_parse $STAGEPROC)
    for VOL in ADC ASL ; do
      if [[ $VOL == ADC ]] ; then SRC=$ADC ; else SRC=$ASL ; fi
      statusPrint       "converting $VOL volume to float format..." "\n"
      STAGEPROC="mri_convert"
      STAGE=${STAGENUM}-${STAGEPROC}
      STAGECMD="$STAGEPROC                                      \
                $EXOPTS                                         \
                -odt float                                      \
                ${VOL}-B0_masked.img ${VOL}-B0_masked.f.img"
      stage_run "$STAGE"  "$STAGECMD"                           \
              "${STAGE4FULLDIR}/${STAGEPROC}.std"               \
              "${STAGE4FULLDIR}/${STAGEPROC}.err"               \
              "SILENT"                                          \
              || fatal stageRun

      statusPrint       "filtering $VOL float volume >= 0..." "\n"
      STAGEPROC="mris_calc"
      STAGE=${STAGENUM}-${STAGEPROC}
      STAGECMD="mris_calc                                       \
                -o ${VOL}-B0_masked.fgte0.mgz                   \
                ${VOL}-B0_masked.f.img gte 0"
      stage_run "$STAGE"  "$STAGECMD"                           \
              "${STAGE4FULLDIR}/${STAGEPROC}.std"               \
              "${STAGE4FULLDIR}/${STAGEPROC}.err"               \
              "SILENT"                                          \
              || fatal stageRun

      statusPrint       "normalizing $VOL float volume..." "\n"
      STAGEPROC="mris_calc"
      STAGE=${STAGENUM}-${STAGEPROC}
      STAGECMD="mris_calc                                       \
                -o ${VOL}-B0_masked.f.norm.mgz                  \
                ${VOL}-B0_masked.fgte0.mgz norm"
      stage_run "$STAGE"  "$STAGECMD"                           \
              "${STAGE4FULLDIR}/${STAGEPROC}.std"               \
              "${STAGE4FULLDIR}/${STAGEPROC}.err"               \
              "SILENT"                                          \
              || fatal stageRun

    done
    statusPrint "$(date) | Processing STAGE 4 - normalizing ADC and ASL | END" "\n"
fi

STAGE4OUT=${STAGE4FULLDIR}/ASL-B0_masked.f.norm.mgz
STAGE5IN=$STAGE4OUT
STAGENUM="asladc-5"
STAGEPROC=matlab
STAGE=${STAGENUM}-${STAGEPROC}
STAGE5RELDIR=${G_OUTRUNDIR}/${STAGE}
STAGE5FULLDIR=${OUTDIR}/${STAGE}
statusPrint     "Checking stage 5 output dir"
dirExist_check ${STAGE5FULLDIR} "not found - creating"        \
            || mkdir -p ${STAGE5FULLDIR}                      \
            || fatal noOutRunDir
if (( ${barr_stage[5]} )) ; then
    cd $STAGE5FULLDIR
    statusPrint "$(date) | Processing STAGE 5 - performing correlation | START" "\n"
    statusPrint "Checking previous stage dependencies"
    fileExist_check     $STAGE5IN       || fatal dependencyStage
    statusPrint         "creating MatLAB script file..." "\n"
    MATLABSCRIPT=basac_drive.m
    matlab_scriptCreate $(pwd) $MATLABSCRIPT
    statusPrint         "running MatLAB script file..." "\n"
    
    STAGECMD="eval \"$G_MATLAB -nodesktop -nosplash -nojvm	\
              -r \\\"c = $(basename $MATLABSCRIPT .m)(); exit\\\"\""                                      
    stage_run "$STAGE"  "$STAGECMD"                             \
              "${STAGE5FULLDIR}/${STAGEPROC}.std"               \
              "${STAGE5FULLDIR}/${STAGEPROC}.err"               \
              "SILENT"                                          \
              || fatal stageRun

    cat matlab.std | grep -i ADC | grep V0
    cat matlab.std | grep -i ASL | grep V0
    cat matlab.std | grep -i correlation
    cat matlab.std | grep -i ADC | grep volume | grep -v and
    cat matlab.std | grep -i ASL | grep volume | grep -v and
    statusPrint "$(date) | Processing STAGE 5 - performing correlation | END" "\n"
fi

cd $topDir
verbosity_check
shut_down 0
