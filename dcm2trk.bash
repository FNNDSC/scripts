#!/bin/bash
#
# dcm2trk.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# GPL v2
#

# "include" the set of common script functions
source common.bash
source getoptx.bash

declare -i Gi_bValue=1000
declare -i Gi_b0Volumes=1
declare -i Gb_forceStage=0
declare -i Gb_useExpertOptions=0
declare -i Gb_ECCdetected=0
declare -i Gb_useDiffUnpack=1
declare -i Gb_b0VolOverride=0

G_OUTDIR="./"
G_LOGDIR="./"
G_DICOMFILE="-x"
G_OUTPUTPREFIX="dcm2trk"
G_GRADIENTTABLE="-x"
G_STAGES="12345"

G_IMAGEMODEL="DTI"
G_RECONALG="fact"
G_MASKIMAGE1="dwi"
G_LOWERTHRESHOLD1="0.0"
G_UPPERTHRESHOLD1="1.0"
G_MASKIMAGE2="-x"
G_LOWERTHRESHOLD2="0.0"
G_UPPERTHRESHOLD2="1.0"

G_EXP_eddy_recon=""
G_EXP_dti_recon=""
G_EXP_dti_tracker=""
G_EXP_spline_filter=""

# Possibly multiply xyz columns of gradient table with -1
G_iX=""
G_iY=""
G_iZ=""

G_SYNOPSIS="

 NAME

        dcm2trk.bash

 SYNOPSIS

        dcm2trk.bash            -d <dicomFile>                          \\              
                                -g <gradientTableFile>                  \\
                                [-b <bFieldValue>] [-B <b0override>]    \\
                                [-A <reconAlg>] [-I <imageModel>]       \\
                                [-m1 <maskImage1>]                      \\
                                [-m2 <maskImage2>]                      \\
                                [-m1-lower-threshold <lth1>]            \\
                                [-m2-lower-threshold <lth2>]            \\
                                [-m1-upper-threshold <uth1>]            \\
                                [-m2-upper-threshold <uth2>]            \\
                                [-v <verbosity>]                        \\
                                [-o <outputPrefix>]                     \\
                                [-O <outputDirectory>]                  \\
                                [-X] [-Y] [-Z]                          \\
                                [-E] [-U]                               \\
                                [-t <stage>] [-f]               

 DESCRIPTION

        'dcm2trk.bash' is a core component of a diffusion processing pipeline
        infrastructure. It's primary purpose is to convert a diffusion scan
        volume to a TrackVis format trk file.

        A core design requirement is to create a trk file that is identical
        to that produced by the GUI front end diffusion toolkit. To this end,
        the script will by default use all the underlying processing steps
        used by the diffusion toolkit.  

        The <dicomFile> and <gradientTableFile> are strictly speaking the
        only arguments required to run the entire pipeline. If individual
        stages are run in isolation, these arguments might not be applicable
        and can be omitted.

        The number of b0 volumes in the input is determined by the
        difference between the number of rows in the gradient table
        and the number of frames in the input dicom volume.

 ARGUMENTS

        -d <dicomFile> (Required for stage 1)
        A single file in a particular DICOM run to process. This can be a
        relative or absolute file/directory spec. This file can also be
        a *.nii.gz, in which case the script will automatically skip the
        processing in stage 1, unzip the file, and place in the appropriate
        directory for downstream processing.

        -g <gradientTableFile> (Required for stage 3)
        The gradient table file for the DICOM images.

        -U (Optional)
        If specified, do NOT use 'diff_unpack' to convert from original
        DICOM data to nifti format. By default, the script will attempt
        to create a final trackvis trk file using the same components as
        the front end diffusion toolkit. In some cases better dcm to nifti
        conversion is possible using 'mri_convert' (for Siemens) or 
        'dcm2nii'(for GE). To use these alternatives, specifiy a '-U'.

        -b <bFieldValue> (Optional: $Gi_bValue)
        The b value field.

        -B <b0override> (Optional)
        If true, override the calculated number of b0 volumes with
        <b0override>. This is only useful in a very limited number of cases.

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
       
        -v <level> (Optional)
        Verbosity level.

        -o <outputPrefix> Optional: $G_OUTPUTPREFIX)
        All files created in the <outputDirectory> will be prefixed with
        <outputPrefix>. If running specific stages in isolation, it is 
        recommended that the <outputPrefix> be specified each time.

        -O <outputDirectory> (Optional: $G_OUTDIR)
        The root output directory to house conversion. See OUTPUT section
        for more detail. If this directory does not exist, the script  
        will attempt to create it.

        [-X] [-Y] [-Z] (Optional)
        Specifying any of the above multiplies the corresponding column
        in the gradient file with -1.

        [-t <stages>] (Optional: $G_STAGES)
        The stages to process. See STAGES section for more detail.

        [-f] (Optional: $Gb_forceStage)
        If true, force re-running a stage that has already been processed.

        [-E] (Optional)
        Use expert options. This script pipeline relies upon a number
        of underlying processes. Each of these processes accepts its
        own set of control options. Many of these options are not exposed
        by 'dcm2trk.bash', but can be specified by passing this -E flag.
        Currently, 'mri_convert', 'dti_tracker', and 'dti_recon' understand
        the -E flag.

        In such a case, 'dcm2trk' will search in the <outputDirectory>
        for text files of the form <processName>.opt that contain additional
        options for <processName>. If found, the contents are read and
        also passed to the <processName> as 'dcm2trk' executes it.

        For example, by default 'dti_tracker' uses a FACT reconstruction.
        To change this to Runge Kutta, for example, create a text file
        in the <outputDirectory> called 'dti_tracker.opt' containing the
        string '-rk2'. Use additional settings if necessary.

 STAGES

        'dcm2trk' offers the following stages:

                1 - convert from dicom to nifti format
                2 - perform eddy current correction
                3 - run 'dti_recon' (or 'odf_recon')
                4 - run 'dti_tracker' (or 'odf_tracker')
                5 - run 'spline_filter'

        The output of one stage is typically the input to its
        successor stage. The script will abort if a given stage
        has already been run for a particular dataset. A re-run
        can be forced with the '-f' flag. It is the responsibility
        of the caller to check for any dependency impications of
        re-running stages.

 OUTPUT

        Several directories are created in the <outputDirectory>. The 
        final output trk file from the whole pipeline is stored here:

                <outputDirectory>/final-trackvis/<outputPrefix>.trk


 PRECONDITIONS

        o '~/arch/scripts/common.bash'
        Houses a set of common script run-time functions.
        
        o A FreeSurfer 'std' or 'dev' environment.

        o The following files need to exist on the current \$PATH:

                * 'dti_recon'
                  Part of TrackVis.

                * 'dti_tracker'
                  Part of TrackVis.

                * 'spline_filter'
                  Part of TrackVis.

                * 'mri_convert', 'mri_info'
                  Convert MRI data file types.

                * 'eddy_correct'
                  Part of the FSL toolset.


 POSTCONDITIONS

        o For a given diffusion volume, a corresponding TrackVis format
          'trk' file that visualizes the track data is generated.

 HISTORY

        11 February 2008
        o Initial design and coding.

        10 July 2008
        o Added input *.nii.gz for automatic skip of stage 1.
        
        29 April 2009
        o Added orientation check and correction to stage 2 to fix
          a bug in FSL eddy current correction code. For some reason the
          ECC volume defaults to a LAS irrespective of input orientation.

"

G_LC=50
G_RC=20

# Actions
A_dependency="checking for a required file dependency"
A_dependencyStage="checking for a required dependency from an earlier stage"
A_noDicomFileArg="checking for the -d <dicomFile> argument"
A_noDicomFile="checking on the <dicomFile> access"
A_noDicomDir="checking if the <dicomDirectory> is accessible"
A_noOutputDir="checking if the <outputDirectory> is accessible"
A_noGradientFileArg="parsing the -g <gradientTableFile> argument"
A_noGradientFile="checking if the <gradientTableFile> exists"
A_comargs="checking command line arguments" 
A_noComSpec="checking for command spec"
A_metaLog="checking the dcm2trk.bash.log file"
A_outputDir="creating the output directory"
A_mriconvert="running 'mri_convert'"
A_stage2nii="attempting to fix missing nii output at stage 2"
A_tableRows="checking the number of rown in the gradient table"
A_stageRun="running a stage in the processing pipeline"
A_reconAlg="checking on the reconstruction algorithm"
A_imageModel="checking on the image model"
A_maskImage="checking on mask image"
A_fa="checking on the FA argument "
A_faRun="analyzing the Mask volume"

# Error messages
EM_dependency="it seems that a dependency is missing."
EM_dependencyStage="it seems that a stage dependency is missing."
EM_noDicomFileArg="it seems that the <dicomFile> argument was not specified."
EM_noDicomFile="I am having problems accessing the <dicomFile>. Does it exist?"
EM_noDicomDir="I am having problems accessing the <dicomDirectory>. Does it exist?"
EM_noOutputDir="I am having problems accessing the <outputDirectory>. Does it exist?"
EM_noGradientFileArg="there was an error resolving the directory or filename."
EM_noGradientFile="I am having problems accessing the <gradientTableFile>. Does it exist?"
EM_noComSpec="no command spec was found."
EM_metaLog="it seems as though this stage has already run.\n\tYou can force execution with a '-f'"
EM_outputDir="there was an error. Do you have permission to create here?"
EM_mriconvert="conversion failed. Please check source DICOM file."
EM_stage2nii="some error occured while running 'mri_convert'."
EM_tableRows="the 'wc' command returned an error."
EM_stageRun="I encountered an error processing this stage."
EM_reconAlg="must be either 'fact' or 'rk2'."
EM_imageModel="must be either 'hardi' or 'dti'."
EM_maskImage="must be either 'dwi', 'fa', or 'adc'."
EM_fa="No <lth> has been specified."
EM_faRun="the underlying analysis failed."

# Error codes
EC_dependency=1
EC_dependencyStage=2
EC_noDicomFileArg=10
EC_noDicomFile=11
EC_noDicomDir=12
EC_noOutputDir=13
EC_noGradientFileArg=20
EC_noGradientFile=21
EC_outputDir=40
EC_comargs=30
EC_metaLog=80
EC_mriconvert=110
EC_stage2nii=120
EC_tableRows=121
EC_stageRun=30
EC_reconAlg=70
EC_imageModel=71
EC_maskImage=72
EC_fa=80
EC_faRun=81

function b0Volumes_findNumber
{
    # ARGS
    #   <internal global>
    #
    # DESC
    # This function determines the number of b0 directions
    # by subtracting the number of rows in gradient table 
    # from the 4th dimension of the original DWI volume.
    #
 
    declare -i gradientRows=0
    declare -i D4=0
    declare -i b0Vols=0

    statusPrint "Calculating the number of b0 volumes"
    D4=$(mri_info $NIIOUT1 2>/dev/null | grep dimension | awk '{print $8}')
    gradientRows=$(wc -l $G_GRADIENTTABLE | awk '{print $1}')
    ret_check $? || fatal tableRows
    b0Vols=$(( D4 - gradientRows ))

    return $b0Vols
}

function stage2_niiConvert
{
    # ARGS
    #   <internal global>
    # 
    # DESC
    #   The output of stage 2 eddy_correct is converted
    #   to nifti format
    #
    statusPrint "Forcing run of 'mri_convert'"          
    mri_convert ${G_OUTPUTPREFIX}-eddy_correct.img ${NIIOUT2}.nii       \
                2>mri_convert.err.log                                   \
                >mri_convert.std.log
    fileExist_check ${NIIOUT2}.nii || fatal stage2nii
}

###\\\
# Process command options
###///

while getoptex "v: f g: d: D: b: B: I: A: o: O: X Y Z t: h E U \
                m1: m2: \
                m1-lower-threshold: \
                m2-lower-threshold: \
                m1-upper-threshold: \
                m2-upper-threshold:" "$@" ; do
        case "$OPTOPT"
        in
                v) Gi_verbose=$OPTARG                                   ;;
                f) Gb_forceStage=1                                      ;;
                g) G_GRADIENTTABLE=$OPTARG                              ;;
                d) G_DICOMFILE=$OPTARG                                  ;;
                b) Gi_bValue=$OPTARG                                    ;;
                B) Gb_b0VolOverride=1  
                   Gi_b0Volumes=$OPTARG                                 ;;
                I) G_IMAGEMODEL=$OPTARG                                 ;;
                A) G_RECONALG=$OPTARG                                   ;;
                m1-lower-threshold)
                   G_LOWERTHRESHOLD1=$OPTARG                            ;;
                m1-upper-threshold) 
                   G_UPPERTHRESHOLD1=$OPTARG                            ;;
                m1)	G_MASKIMAGE1=$OPTARG                                ;;
                m2-lower-threshold)
                   G_LOWERTHRESHOLD2=$OPTARG                            ;;
                m2-upper-threshold) 
                   G_UPPERTHRESHOLD2=$OPTARG                            ;;
                m2) G_MASKIMAGE2=$OPTARG                                ;;
                o) G_OUTPUTPREFIX=$OPTARG                               ;;
                O) G_OUTDIR=$OPTARG                                     ;;
                X) G_iX="-ix"                                           ;;
                Y) G_iY="-iy"                                           ;;
                Z) G_iZ="-iz"                                           ;;
                U) Gb_useDiffUnpack=0                                   ;;
                t) G_STAGES=$OPTARG                                     ;;
                E) Gb_useExpertOptions=1                                ;;
                *) synopsis_show 
                    exit 0;;
        esac
done


verbosity_check
startDir=$(pwd)

echo ""
cprint  "hostname"      "[ $(hostname) ]"

if [[ "$G_DICOMFILE" != "-x" ]] ; then
    statusPrint "Checking on <dicomFile>" "\n"
    DICOMDIR=$(dirname $G_DICOMFILE)
    DICOMFILE=$(basename $G_DICOMFILE)
    statusPrint "Checking on DICOMDIR" 
    dirExist_check $DICOMDIR || fatal noDicomDir
    cd $DICOMDIR >/dev/null
    G_DICOMFILE=$(pwd)/$DICOMFILE
    statusPrint "Checking on fully qualified DICOMSPEC"
    fileExist_check $G_DICOMFILE || fatal noDicomFile
    cd $startDir
fi

if [[ $G_GRADIENTTABLE != "-x" ]] ; then
    statusPrint "Checking on <gradientTableFile>" "\n"
    DIR=$(dirname $G_GRADIENTTABLE)
    FILE=$(basename $G_GRADIENTTABLE)
    statusPrint "Checking on DIR" 
    dirExist_check $DIR || fatal noGradientFileArg
    cd $DIR >/dev/null
    G_GRADIENTTABLE=$(pwd)/$FILE
    statusPrint "Checking on parsed name"
    fileExist_check $G_GRADIENTTABLE || fatal noGradientFile
#     statusPrint "Deleting any blank lines in gradient table"
#     cat $G_GRADIENTTABLE | sed '/^$/d' > /tmp/$(basename ${G_GRADIENTTABLE})_${G_PID}
#     ret_check $?
#     G_GRADIENTTABLE=/tmp/$(basename ${G_GRADIENTTABLE})_${G_PID} 
    cd $startDir
fi

G_RECONALG=$(echo $G_RECONALG | tr '[A-Z]' '[a-z]')
G_IMAGEMODEL=$(echo $G_IMAGEMODEL | tr '[A-Z]' '[a-z]')
G_MASKIMAGE1=$(echo $G_MASKIMAGE1 | tr '[A-Z]' '[a-z]')
G_MASKIMAGE2=$(echo $G_MASKIMAGE2 | tr '[A-Z]' '[a-z]')

cprint          "Algorithm"     "[ $G_RECONALG ]"
cprint          "Image Model"   "[ $G_IMAGEMODEL ]"
cprint          "Mask Image 1"  "[ $G_MASKIMAGE1 ]"
cprint          "Mask Image 2"  "[ $G_MASKIMAGE2 ]"


if [[ $G_RECONALG != "fact" && $G_RECONALG != "rk2" ]] ; then
    fatal reconAlg
fi
if [[ $G_IMAGEMODEL != "dti" && $G_IMAGEMODEL != "hardi" ]] ; then
    fatal imageModel
fi
if [[ $G_MASKIMAGE1 != "dwi" && $G_MASKIMAGE1 != "fa" && $G_MASKIMAGE1 != "adc" ]] ; then
    fatal maskImage
fi
if [[ $G_MASKIMAGE2 != "dwi" && $G_MASKIMAGE2 != "fa" && $G_MASKIMAGE2 != "adc" && $G_MASKIMAGE2 != "-x" ]] ; then
    fatal maskImage
fi

statusPrint     "Checking if <outputDirectory> is accessible"
dirExist_check "$G_OUTDIR" || fatal noOutputDir
cd $G_OUTDIR
G_OUTDIR=$(pwd)
echo $G_OUTDIR
G_LOGDIR=$G_OUTDIR

REQUIREDFILES=" common.bash mri_info                    \
                mri_convert eddy_correct                \
                dti_recon dti_tracker spline_filter     \
                vol_thFind.py hardi_mat odf_recon       \
                odf_tracker"

cprint  "Use diff_unpack for dcm->nii"  "[ $Gb_useDiffUnpack ]"

if (( Gb_useDiffUnpack )) ; then
        REQUIREDFILES="$REQUIREDFILES diff_unpack"
fi

for file in $REQUIREDFILES ; do
        statusPrint "Checking dependency: '$file'"
        file_checkOnPath $file || fatal dependency
done


STAMPLOG=${G_OUTDIR}/${G_SELF}.log
statusPrint     "$STAMPLOG" "\n"
stage_stamp "Init | ($startDir) $G_SELF $*" $STAMPLOG

statusPrint     "Checking which stages to process"
barr_stage=([0]=0 [1]=0 [2]=0 [3]=0 [4]=0 [5]=0)
for i in $(seq 1 5) ; do
        b_test=$(expr index $G_STAGES "$i")
        if (( b_test )) ; then b_flag="1" ; else b_flag="0" ; fi
        barr_stage[$i]=$b_flag
done
ret_check $?

DATE=$(date)
cd $G_OUTDIR

# Stage 1
NIIDIR1=${G_OUTDIR}/stage-1-mri_convert
NIIOUT1=${NIIDIR1}/${G_OUTPUTPREFIX}.nii
# Stage 2
NIIDIR2=${G_OUTDIR}/stage-2-eddy_correct
NIIOUT2=${NIIDIR2}/${G_OUTPUTPREFIX}-eddy_correct
REFVOL=0
# Stage 3
if [[ "$G_IMAGEMODEL" == "dti" ]] ; then
    NIIDIR3=${G_OUTDIR}/stage-3-dti_recon
    NIIOUT3=${NIIDIR3}/${G_OUTPUTPREFIX}-dti_recon
else
    NIIDIR3=${G_OUTDIR}/stage-3-odf_recon
    NIIOUT3=${NIIDIR3}/${G_OUTPUTPREFIX}-odf_recon
fi
# Stage 4
if [[ "$G_IMAGEMODEL" == "dti" ]] ; then
    NIIDIR4=${G_OUTDIR}/stage-4-dti_tracker
    NIIOUT4=${NIIDIR4}/${G_OUTPUTPREFIX}-dti_tracker
else
    NIIDIR4=${G_OUTDIR}/stage-4-odf_tracker
    NIIOUT4=${NIIDIR4}/${G_OUTPUTPREFIX}-odf_tracker
fi
# Stage 5
NIIDIR5=${G_OUTDIR}/stage-5-spline_filter
NIIOUT5=${NIIDIR5}/${G_OUTPUTPREFIX}-spline_filter
# final output
FINAL=${G_OUTDIR}/final-trackvis
FINALTRK=${FINAL}/${G_OUTPUTPREFIX}

# 
# Stage 1 is responsible for passing on a NIFTI (nii) volume 
# constructed from the original DICOM data. There are several
# ways in which this nii volume can be created:
# 
# 1. Use 'diff_unpack' which is part of trackvis.
#    This is the default behaviour, designed to generate output 
#    that mimics the GUI front end as closely as possible.
# 2. Pass a nii.gz volume directly to this script.
#    If a nii.gz volume is passed with '-d' AND diff_unpack
#    is turned off with '-U', then the passed nii.gz volume
#    is passed through. Typically, this is used for GE datasets
#    and is a by-product of the gradient table extraction used
#    by 'tract_meta.bash'.
# 3. Use 'mri_convert' to convert from dicom to nii format.
#    This is only used for Siemens data sets. Again, this will
#    only be used if a '-U' is passed to the script.
#
if (( ${barr_stage[1]} )) ; then
    statusPrint "$(date) | Processing STAGE 1 - dicom --> nii | START" "\n"
    statusPrint "Checking stage dependencies"
    fileExist_check $G_DICOMFILE || fatal noDicomFile
    dirExist_check      $NIIDIR1 >/dev/null || mkdir $NIIDIR1
    declare -i b_NIIGZ=0
    b_NIIGZ=$(echo $G_DICOMFILE | grep nii.gz | wc -l)
    if (( Gb_useDiffUnpack )) ; then
      INPUT=$G_DICOMFILE
      if (( b_NIIGZ )) ; then
        DICOMDIR=$(dirname $G_DICOMFILE)
        INPUTFILE=$(/bin/ls -1 $DICOMDIR | head -n 1)
        INPUT=$DICOMDIR/$INPUTFILE 
      fi
      STAGE1PROC=diff_unpack
      STAGE=1-$STAGE1PROC
      EXOPTS=$(eval expertOpts_parse diff_unpack)
      OUTPUT=$(echo ${NIIOUT1} | sed 's/\(.*\)\.nii/\1/')
      STAGECMD="diff_unpack                             \
                $INPUT                                  \
                $OUTPUT                                 \
                -ot nii                                 \
                $EXOPTS"
      stage_run "$STAGE" "$STAGECMD"                    \
                "${NIIDIR1}/${STAGE1PROC}.std"          \
                "${NIIDIR1}/${STAGE1PROC}.err"          \
                "NOECHO"                                \
         || fatal stageRun
         
      # For HARDI-only, we also need to run hardi_mat.  The reason
      # this is not its own stage is that DTI does not have an equivalent
      # and making this part of stage 1 was the easiest way to modify
      # this script.
      if [[ "$G_IMAGEMODEL" == "hardi" ]] ; then
        STAGE1PROC=hardi_mat
        STAGE=1-$STAGE1PROC
        STAGECMD="hardi_mat                             \
                ${G_GRADIENTTABLE}                      \
                $OUTPUT.dat                             \
                -ref $INPUT -oc"
        stage_run "$STAGE" "$STAGECMD"                  \
                "${NIIDIR1}/${STAGE1PROC}.std"          \
                "${NIIDIR1}/${STAGE1PROC}.err"          \
                "NOECHO"                                \
         || fatal stageRun
      fi
    else
      if (( b_NIIGZ )) ; then
        cp $G_DICOMFILE ${NIIOUT1}.gz
        gunzip ${NIIOUT1}.gz
      else
        STAGE1PROC=mri_convert
        STAGE=1-$STAGE1PROC
        EXOPTS=$(eval expertOpts_parse mri_convert)
        STAGECMD="UNPACK_MGH_DTI=0 mri_convert          \
                -ot nii                                 \
                $EXOPTS                                 \
                $G_DICOMFILE                            \
                ${NIIOUT1}"
        stage_run "$STAGE" "$STAGECMD"                  \
                "${NIIDIR1}/${STAGE1PROC}.std"          \
                "${NIIDIR1}/${STAGE1PROC}.err"          \
                "NOECHO"                                \
         || fatal stageRun
      fi
    fi
    
    statusPrint "$(date) | Processing STAGE 1 - dicom --> nii | END" "\n"
fi

if (( ${barr_stage[2]} )) ; then
    statusPrint "$(date) | Processing STAGE 2 - eddy current correction | START" "\n"
    statusPrint "Checking stage dependencies"
    fileExist_check ${NIIOUT1} || fatal dependencyStage
    STAGE2PROC=eddy_correct
    STAGE=2-$STAGE2PROC
    dirExist_check      $NIIDIR2 >/dev/null || mkdir $NIIDIR2
    cd $NIIDIR2
    STAGECMD="eddy_correct                              \
                ${NIIOUT1}                              \
                ${NIIOUT2}                              \
                $REFVOL"
    if [[ -f ${NIIOUT2}.nii ]] ; then Gb_ECCdetected=1 ; fi
    if (( !Gb_ECCdetected )) ; then 
        stage_run "$STAGE" "$STAGECMD"                  \
                "${NIIDIR2}/${STAGE2PROC}.std"          \
                "${NIIDIR2}/${STAGE2PROC}.err"          \
                "NOECHO"                                \
         || fatal stageRun
        eval $STAGECMD ; 
    else
        statusPrint "Previous ECC output detected. Skipping ECC" 
    fi           
    ret_check $?
    statusPrint "Checking for output ECC nii format file"
    if [[ -f ${G_OUTPUTPREFIX}-eddy_correct.img ]] ; then
      statusPrint "converting img->nii"
      stage2_niiConvert
    fi
    if [[ -f ${NIIOUT2}.nii.gz ]] ; then 
      statusPrint "unzipping .gz"
      gunzip ${NIIOUT2}.nii.gz
    fi
    ORIGORIENTATION=$(mri_info $NIIOUT1     | grep Orientation  \
                                            | awk '{print $3}'  \
                                            | tr ' ' '_')
    ECCORIENTATION=$(mri_info $NIIOUT2.nii  | grep Orientation  \
                                            | awk '{print $3}'  \
                                            | tr ' ' '_')
    cprint "Original Orientation"       "[ $ORIGORIENTATION ]"
    cprint "Post-ECC Orientation"       "[ $ECCORIENTATION ]"
    if [[ "$ORIGORIENTATION" != "$ECCORIENTATION" ]] ; then
        lprint "Mismatched Orientation! Performing DICOM header copy"
        mv ${NIIOUT2}.nii ${NIIOUT2}.${ORIGORIENTATION}.nii
        mri_copy_params ${NIIOUT2}.${ORIGORIENTATION}.nii $NIIOUT1 \
              $NIIOUT2.nii 2>/dev/null
        ret_check $?
    fi
    statusPrint "$(date) | Processing STAGE 2 - eddy current correction | END" "\n"
fi

if (( ${barr_stage[3]} )) ; then
    if [[ "$G_IMAGEMODEL" == "dti" ]] ; then
        STAGEEXE="dti_recon"
    else
        STAGEEXE="odf_recon"
    fi
    statusPrint "$(date) | Processing STAGE 3 - ${STAGEEXE} | START" "\n"
    statusPrint "Checking stage dependencies"
    if (( ${barr_stage[2]} )) ; then
        fileExist_check ${NIIOUT2}.nii || fatal dependencyStage
        RAWDATAFILE=${NIIOUT2}.nii
    else
        fileExist_check ${NIIOUT1} || fatal dependencyStage
        RAWDATAFILE=${NIIOUT1}
    fi
    statusPrint "Checking for gradient table"
    fileExist_check $G_GRADIENTTABLE || fatal noGradientFile
    STAGE3PROC=$STAGEEXE
    STAGE=3-$STAGE3PROC
    dirExist_check      $NIIDIR3 >/dev/null || mkdir $NIIDIR3
    EXOPTS=$(eval expertOpts_parse dti_recon)
    cd $NIIDIR3
    if (( ! Gb_b0VolOverride )) ; then
      b0Volumes_findNumber
      Gi_b0Volumes=$?
    fi
    # Correct for some strange GE sets that seem to have bvals with no '0' rows
    if (( Gi_b0Volumes == 0 )) ; then 
      statusPrint "bval vector does not contain nB0 data. Assuming nB0 = 1." "\n"
      Gi_b0Volumes=1 ; 
    fi
    cprint "b0 Volumes" " [ $Gi_b0Volumes ]"
    if [[ "$G_IMAGEMODEL" == "dti" ]] ; then
        STAGECMD="${STAGEEXE}               \
                $RAWDATAFILE                \
                ${NIIOUT3}                  \
                $EXOPTS                     \
                -gm ${G_GRADIENTTABLE}      \
                -ot nii                     \
                -b $Gi_bValue               \
                -b0 $Gi_b0Volumes"
    else
        declare -i gradientRows=0
        gradientRows=$(wc -l $G_GRADIENTTABLE | awk '{print $1}')
        GRADIENTROWS=$(( gradientRows + 1 ))
        OUTPUT=$(echo ${NIIOUT1} | sed 's/\(.*\)\.nii/\1/')
        STAGECMD="${STAGEEXE}               \
                $RAWDATAFILE                \
                $GRADIENTROWS               \
                181                         \
                ${NIIOUT3}                  \
                -nt                         \
                -b0 $Gi_b0Volumes           \
                -mat ${OUTPUT}.dat          \
                -ot nii"                        
    fi
    stage_run "$STAGE" "$STAGECMD"                      \
                "${NIIDIR3}/${STAGE3PROC}.std"          \
                "${NIIDIR3}/${STAGE3PROC}.err"          \
                "NOECHO"                                \
        || fatal stageRun
    statusPrint "$(date) | Processing STAGE 3 - ${STAGEEXE} | END" "\n"
fi

if (( ${barr_stage[4]} )) ; then
    if [[ "$G_IMAGEMODEL" == "dti" ]] ; then
        STAGEEXE="dti_tracker"
    else
        STAGEEXE="odf_tracker"
    fi
    statusPrint "$(date) | Processing STAGE 4 - ${STAGEEXE} | START" "\n"
    statusPrint "Checking stage dependencies"
    fileExist_check ${NIIOUT3}_dwi.nii || fatal dependencyStage
    STAGE4PROC=$STAGEEXE
    STAGE=4-$STAGE4PROC
    dirExist_check      $NIIDIR4 >/dev/null || mkdir $NIIDIR4
    EXOPTS=$(eval expertOpts_parse dti_tracker)
    
    MASK1=${NIIOUT3}_${G_MASKIMAGE1}.nii    
    if [[ $G_MASKIMAGE1 != "dwi" || $G_MASKIMAGE2 != "-x" ]] ; then
        if [[ "$G_IMAGEMODEL" == "hardi" ]] ; then
            # If we are doing hardi, we first need to run dti_recon because
            # the hardi pipeline does not output the FA/ADC image.  There is some
            # question over what the validity is of using the FA/ADC mask with 
            # HARDI, but if the user wants to do it this appears to be the only
            # way
            NIIOUT_FOR_MASK1=${NIIDIR4}/${G_OUTPUTPREFIX}-dti_tracker_for_${G_MASKIMAGE1}  
            STAGECMD="dti_recon                 \
                    $RAWDATAFILE                \
                    ${NIIOUT_FOR_MASK1}          \
                    -gm ${G_GRADIENTTABLE}      \
                    -ot nii                     \
                    -b $Gi_bValue               \
                    -b0 $Gi_b0Volumes"
                                
            stage_run "4-dti_recon_for_${G_MASKIMAGE1}" "$STAGECMD"  \
                    "${NIIDIR4}/dti_recon_for_${G_MASKIMAGE1}.std"   \
                    "${NIIDIR4}/dti_recon_for_${G_MASKIMAGE1}.err"   \
                    "NOECHO"                                        \
                    || fatal stageRun
            
            MASK1=${NIIOUT_FOR_MASK1}_${G_MASKIMAGE1}.nii                 
        else
            MASK1=${NIIOUT3}_${G_MASKIMAGE1}.nii     
        fi
        
        lprint "Analzying for lower intensity (Mask 1)"
        MASKminTH1=$(vol_thFind.py -v $MASK1 -t $G_LOWERTHRESHOLD1 2>/dev/null)
        ret_check $? || fatal faRun
        cprint "Lower threshold spec (Mask 1)"  		" [ $G_LOWERTHRESHOLD1 ]"
        cprint "Upper threshold spec (Mask 1)"  		" [ $G_UPPERTHRESHOLD1 ]"
        cprint "Lower threshold intensity (Mask 1)"     " [ $MASKminTH1 ]"
        lprint "Analzying for upper intensity (Mask 1)"
        MASKmaxTH1=$(vol_thFind.py -v $MASK1 -t $G_UPPERTHRESHOLD1 2>/dev/null)
        ret_check $? || fatal faRun
        cprint "Upper threshold intensity (Mask 1)"      " [ $MASKmaxTH1 ]"
        MASK1="$MASK1 $MASKminTH1 $MASKmaxTH1"
        
        # If specified, now also compute and include threshold for second mask image
        MASK2=""
        if [[ $G_MASKIMAGE2 != "-x" ]] ; then
            if [[ "$G_IMAGEMODEL" == "hardi" ]] ; then	        
                MASK2=${NIIOUT_FOR_MASK1}_${G_MASKIMAGE2}.nii    
            else
                MASK2=${NIIOUT3}_${G_MASKIMAGE2}.nii
            fi
	        lprint "Analzying for lower intensity (Mask 2)"
	        MASKminTH2=$(vol_thFind.py -v $MASK2 -t $G_LOWERTHRESHOLD2 2>/dev/null)
	        ret_check $? || fatal faRun
	        cprint "Lower threshold spec (Mask 2)"  		" [ $G_LOWERTHRESHOLD2 ]"
	        cprint "Upper threshold spec (Mask 2)"  		" [ $G_UPPERTHRESHOLD2 ]"
	        cprint "Lower threshold intensity (Mask 2)"     " [ $MASKminTH2 ]"
	        lprint "Analzying for upper intensity (Mask 2)"
	        MASKmaxTH2=$(vol_thFind.py -v $MASK2 -t $G_UPPERTHRESHOLD2 2>/dev/null)
	        ret_check $? || fatal faRun
	        cprint "Upper threshold intensity (Mask 2)"      " [ $MASKmaxTH2 ]"	        
            MASK2="-m2 $MASK2 $MASKminTH2 $MASKmaxTH2"
        fi
    fi
               
    cd $NIIDIR4
        
    if [[ "$G_IMAGEMODEL" == "dti" ]] ; then            
        STAGECMD="${STAGEEXE}                           \
                ${NIIOUT3}                              \
                ${NIIOUT4}.trk                          \
                $EXOPTS                                 \
                -$G_RECONALG                            \
                -at 35                                  \
                -it nii                                 \
                -m $MASK1                               \
                $MASK2                                  \
                $G_iX $G_iY $G_iZ"
    else
        # The default for odf_recon is non-interpolate streamline,
        # the "-fact" command-line argument is not supported.  However,
        # rk2 is supported.
        RECONALG=""
        if [[ "$G_RECONALG" == "rk2" ]] ; then
            RECONALG="-rk2";
        fi
        STAGECMD="${STAGEEXE}                           \
                ${NIIOUT3}                              \
                ${NIIOUT4}.trk                          \
                $EXOPTS                                 \
                $RECONALG                               \
                -at 35                                  \
                -it nii                                 \
                -m $MASK1                               \
                $MASK2                                  \
                $G_iX $G_iY $G_iZ"      
    fi                          
    stage_run "$STAGE" "$STAGECMD"                      \
                "${NIIDIR4}/${STAGE4PROC}.std"          \
                "${NIIDIR4}/${STAGE4PROC}.err"          \
                "NOECHO"                                \
        || fatal stageRun

    statusPrint "$(date) | Processing STAGE 4 - ${STAGEEXE} | END" "\n"
fi

if (( ${barr_stage[5]} )) ; then
    statusPrint "$(date) | Processing STAGE 5 - spline_filter | START" "\n"
    statusPrint "Checking stage dependencies"
    fileExist_check ${NIIOUT4}.trk || fatal dependencyStage
    STAGE5PROC="spline_filter"
    STAGE=5-$STAGE5PROC
    dirExist_check      $NIIDIR5 >/dev/null || mkdir $NIIDIR5
    cd $NIIDIR5
    STAGECMD="spline_filter                             \
                ${NIIOUT4}.trk                          \
                1                                       \
                ${NIIOUT5}.trk                          \
                > ${NIIDIR5}/spline_filter.std          \
                2> ${NIIDIR5}/spline_filter.err"
    stage_run "$STAGE" "$STAGECMD"                      \
                "${NIIDIR5}/${STAGE5PROC}.std"          \
                "${NIIDIR5}/${STAGE5PROC}.err"          \
                "NOECHO"                                \
        || fatal stageRun

    cd ${G_OUTDIR}
    statusPrint "$(date) | Processing STAGE 5 - postprocessing | START" "\n"
    statusPrint "Checking for 'trackvis' directory"
    dirExist_check $FINAL "created" || mkdir $FINAL
    cp ${NIIOUT5}.trk ${FINALTRK}.trk
    statusPrint "$(date) | Processing STAGE 5 - postprocessing | END" "\n"
fi

STAGE="Normal termination"
stage_stamp "$STAGE" $STAMPLOG

statusPrint "Cleaning up"
cd $startDir
shut_down 0

