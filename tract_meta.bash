#!/bin/bash
#
# tract_meta.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

declare -i Gi_verbose=0
declare -i Gb_useExpertOptions=1
declare -i Gb_useOverrideOut=0
declare -i Gb_forceStage=0

declare -i Gb_mailAll=0
declare -i Gb_mailStd=0
declare -i Gb_mailErr=0
declare -i Gb_mailLog=0

declare -i Gb_runCluster=0

declare -i Gb_useDICOMFile=0
declare -i Gb_useFA=0

declare -i Gi_bValue=1000
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
G_DICOMINPUTFILE="-x"
G_DICOMSERIESLIST="DIFFUSION_HighRes;ISO DIFFUSION TRUE AXIAL"
G_GRADIENTFILE="-x"

G_IMAGEMODEL="DTI"
G_RECONALG="fact"
G_FALOWERTHRESHOLD="-x"

G_CLUSTERNAME=seychelles
G_CLUSTERDIR=${G_OUTDIR}/${G_CLUSTERNAME}
G_SCHEDULELOG="schedule.log"
G_MAILTO="rudolph.pienaar@childrens.harvard.edu,daniel.ginsburg@childrens.harvard.edu"

G_STAGES="12345"

G_MATLAB32="/space/lyon/9/pubsw/Linux2-2.3-i386.new/bin/matlab.new -nosplash -nodesktop -nojvm -nodisplay "
G_MATLAB64="/space/lyon/9/pubsw/Linux2-2.3-x86_64/bin/matlab.new -nosplash -nodesktop -nojvm -nodisplay "
G_MATLABDARWIN="/space/lyon/9/pubsw/MacOS10.5-i686/bin/matlab -nosplash -nodesktop -nojvm -nodisplay "
G_MATLAB="$G_MATLAB32"

# Possibly multiply xyz columns of gradient table with -1
G_iX=""
G_iY=""
G_iZ=""

G_SYNOPSIS="

 NAME

	tract_meta.bash

 SYNOPSIS

	tract_meta.bash		-D <dicomInputDir>			\\
				[-S <dicomSeriesList>]			\\
				[-d <dicomSeriesFile>]			\\
				[-g <gradientTableFile>] [-G]		\\
                                [-B <b0vols>]                           \\
                                [-A <reconAlg>] [-I <imageModel>]       \\
                                [-F <lth>]                              \\
				[-L <logDir>]				\\
				[-v <verbosity>]			\\
				[-O <outputDir>] [-o <suffix>]		\\
				[-R <DIRsuffix>]			\\
                                [-E]					\\
				[-k] [-U] [-b <bFieldVal>]		\\
				[-t <stage>] [-f]			\\
				[-c] [-C <clusterDir>]                  \\
				[-X] [-Y] [-Z]              \\
                                [-M | -m <mailReportsTo>]

 DESCRIPTION

	'tract_meta.bash' is the meta shell controller for a (semi) automated
        tractography integration stream.

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

	-b <bFieldVal> (Optional: Default $Gi_bValue)
	The b field value, passed through to 'dcm2trk'.

	-d <dicomSeriesFile> (Optional)
	If specified, override the automatic sequence detection and run the
	pipeline seeded on the series containinig <dicomSeriesFile>. This
	filename is relative to the <dicomInputDir>.

        [-B <b0vols>] (Optional)
        This option should only be used with care and overrides the internal
        detection of the number of b0 volumes, forcing this to be <b0vols>.

        [-A <reconAlg>] [-I <imageModel>] (Optional: Default 'fact'/'DTI')
        Specifies the reconstruction algorithm and model to use. The default
        algorithm is 'fact', and the default model is DTI.
        
        [-F <lth>] (Optional)
        If specified, use the FA volume as a mask. Moreover, use the <lth> as
        a lower cutoff threshold on the mask. To use the entire FA volume, use
        '-F 0.0'.

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

 	-c 		(Optional: bool default $Gb_runCluster)
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

STAGES

        'tract_meta.bash' offers the following stages:

        1 - dicom_seriesCollect.bash
		Collect a DICOM series from a given directory.
        2 - dcm2trk.bash
		Convert the series to a 'trackvis' trk file (including eddy
	    	current correction).
        3 - tract_slice.bash
		Slice the trk file into a set of flat png images.
        4 - (MatLAB) img2dicom
		Dicomize the set of png images.
        5 - dicom_dirSend.bash
		Transmit the images to remote server.

 OUTPUT
	Each processing stage has its own set of inputs and outputs. Typically
	the outputs from one stage become the inputs to a subsequent stage.

	As a whole, this processing pipelie has two main classes of output:

	1. A trackvis format *.trk file that can be visualized by TrackVis
	2. A set of dicomized images that are transmistted to a remote PACS
	   conforming server.

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

	o fs_meta.bash -- functionally similar pipeline geared for
	  FreeSurfer processing.

 HISTORY

	10 March 2008
	o Initial design and coding.

	28 April 2008
	o Further design and coding.

	31 July 2008
	o Added user spec'd gradient table file
	o Added GE / Siemens case handling
        
        17 March 2009
        o Added -I <imageModel> and -A <reconAlg>
        
        11 May 2009
        o Added -F <lth>.

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
#	for LOG in ${G_OUTDIR}/*.log ; do
#	    cp $LOG ${LOG}.mail
#	    mail -s "$LOG: ${G_SELF}" $G_MAILTO < ${LOG}.std.mail
#	done
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

function matlab_check
{
    # ARGS
    #
    # DESC
    # Checks (and assigns) a valid MatLAB binary.
    # 
    statusPrint	"Checking which host-type of MatLAB to use"
    let b_64=$(uname -a | grep 64 | wc -l)
    let b_Darwin=$(uname -a | grep -i Darwin | grep -i 386 | wc -l)
    let b_32=$(uname -a | grep i386 | wc -l)
    let b_found=0

    if (( b_64 )) 	; then 
	G_MATLAB=$G_MATLAB64 	; 
	statusPrint "[ Linux-64 ]" "\n"
	b_found=1
    fi
    if (( b_32 )) 	; then 
	G_MATLAB=$G_MATLAB32 	; 
	statusPrint "[ Linux-32 ]" "\n"
	b_found=1
    fi
    if (( b_Darwin ))	; then 
	G_MATLAB=$G_MATLABDARWIN	; 
	statusPrint "[ Darwin-i386 ]" "\n"
	b_found=1
    fi
    if (( !b_found )) ; then fatal noMatlab ; fi
 
    statusPrint "Checking on MatLAB binary"
    MATLABBIN=$(echo $G_MATLAB | awk '{print $1}')
    fileExist_check $MATLABBIN || fatal noMatlab
    return 0
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
	STAGECMD="$G_SELF $COMARGS -f 			 >\
		    ${G_LOGDIR}/${G_SELF}.std 		2>\
		    ${G_LOGDIR}/${G_SELF}.err"
        STAGECMD=$(echo $STAGECMD | sed 's|/local_mount||g')
	CLUSTERSH=${G_LOGDIR}/tract-cluster.sh
	echo "#!/bin/bash" 					> $CLUSTERSH
	echo "export PATH=$PATH"				>> $CLUSTERSH	
	echo "source $FREESURFER_HOME/SetUpFreeSurfer.sh" >>$CLUSTERSH
	echo "source /usr/share/fsl/etc/fslconf/fsl.sh" >> $CLUSTERSH
	echo "export SUBJECTS_DIR=$SUBJECTS_DIR"		>> $CLUSTERSH
	echo "export DSI_PATH=$(echo $PATH | tr ":" "\n" | grep dtk)/matrices" >> $CLUSTERSH 	
	echo "$STAGECMD" 					>> $CLUSTERSH
	chmod 755 $CLUSTERSH
	STAGECMD="${G_LOGDIR}/tract-cluster.sh"
        STAGECMD=$(echo $STAGECMD | sed 's|/local_mount||g')
	stage_stamp "$STAGECMD" ${G_CLUSTERDIR}/$G_SCHEDULELOG
	stage_stamp "$STAGE Schedule for cluster" $STAMPLOG
	stage_stamp "$STAGE" $STAMPLOG
}

function matlabFile_create
{
    # ARGS
    # $1                        original input DICOM directory
    # $2			tract_slice root image directory
    # $3			output directory for DICOMs
    # $4			output MatLAB driver file
    #
    # DESC
    # Creates a MatLAB "driver" script that is run in MatLAB.
    # 
 
    local	originalDICOMDir=$1
    local	tractSliceRootDir=$2
    local	outputDICOMDir=$3
    local 	matlabFile=$4

    PROG=$(printf "
	function [c] =	img2dicom_drive(varargin)
	cell_plane	= {'SAG', 'COR', 'AXI'};

    	    function [num] = SeriesNumber_set(astr_plane)
		num = -1;
		switch astr_plane
	    	    case 'SAG'
			num = 1000;
	    	    case 'COR'
			num = 1001;
	    	    case 'AXI'
			num = 1002;
		end
    	    end

	c	= img2dicom();

	if length(varargin)
	    str_plane	= varargin{1};
	    cell_plane	= { str_plane };
	end

	for i=1:length(cell_plane)
          str_inputDir	  = sprintf('${tractSliceRootDir}/%s', cell_plane{i});
          str_description = sprintf('Track_vis_%s', cell_plane{i});
    	  c	= set(c,'verbosity',	10,				...
		'dicomInputDir', 	'${originalDICOMDir}',		...
		'imgInputDir',		str_inputDir,			...
		'dicomOutputDir',	'${outputDICOMDir}',		...
		'SeriesDescription',	str_description,		...
		'SeriesNumber',		SeriesNumber_set(cell_plane{i}),...
		'b_newSeries',		1);
    	  c	= run(c);
	end

	end
    " "%s" "%s")

    echo "$PROG"	> $matlabFile
    return 0
}


###\\\
# Process command options
###///

while getopts v:D:d:B:A:F:I:kEL:O:R:o:fS::XYZt:cC:g:GUb:M:m option ; do 
	case "$option"
	in
		v) 	Gi_verbose=$OPTARG		;;
		D)	G_DICOMINPUTDIR=$OPTARG		;;
		d)	Gb_useDICOMFile=1		
			G_DICOMINPUTFILE=$OPTARG	;;
		E) 	Gb_useExpertOptions=1		;;
		k)	Gb_skipEddyCurrentCorrection=1	;;
		L)	G_LOGDIR=$OPTARG		;;
        O) 	Gb_useOverrideOut=1	
            G_OUTDIR=$OPTARG  
			G_CLUSTERDIR=${G_OUTDIR}/${G_CLUSTERNAME}        ;;
        R)  G_DIRSUFFIX=$OPTARG             ;;
		o)	G_OUTSUFFIX=$OPTARG		;;
		g)	Gb_forceGradientFile=1	
			G_GRADIENTFILE=$OPTARG		;;
        B)  Gb_b0override=1
            Gi_b0vols=$OPTARG               ;;
        I)  G_IMAGEMODEL=$OPTARG            ;;
        A)  G_RECONALG=$OPTARG              ;;
        F)  Gb_useFA=1
            G_FALOWERTHRESHOLD=$OPTARG      ;;
		G)	Gb_GEGradientInlineFix=0	;;
		S)	G_DICOMSERIESLIST=$OPTARG	;;
		f) 	Gb_forceStage=1			;;
		t)	G_STAGES=$OPTARG		;;
		c)	Gb_runCluster=1			;;
		C)	G_CLUSTERNAME=$OPTARG
			G_CLUSTERDIR=${G_OUTDIR}/${G_CLUSTERNAME}       ;;
		U)	Gb_useDiffUnpack=0		;;
		b)	Gi_bValue=$OPTARG		;;
        X)  G_iX="-X"                     ;;
        Y)  G_iY="-Y"                       ;;
        Z)  G_iZ="-Z"                       ;;
        M)  Gb_mailStd=1
            Gb_mailErr=1
            G_MAILTO=$OPTARG                ;;
        m)  Gb_mailStd=1
            Gb_mailErr=0
            G_MAILTO=$OPTARG                ;;
		\?) synopsis_show 
		    exit 0;;
	esac
done

verbosity_check
topDir=$(pwd)
echo ""
cprint  "hostname"      "[ $(hostname) ]"

## Check on script preconditions
REQUIREDFILES="common.bash dcm2trk.bash tract_slice.bash dicom_dirSend.bash \
		dicom_seriesCollect.bash mri_info $XVFB dcm_mkIndx.bash	\
		ge_diffusionProcess.bash siemens_diffusionProcess.bash convert"

cprint	"Use diff_unpack for dcm->nii"	"[ $Gb_useDiffUnpack ]"
if (( Gb_useDiffUnpack )) ; then
	REQUIREDFILES="$REQUIREDFILES diff_unpack"
fi

for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file"
        file_checkOnPath $file || fatal fileCheck
done

## Check on input directory and files
statusPrint 	"Checking -D <dicomInputDir>"
if [[ "$G_DICOMINPUTDIR" == "-x" ]] ; then fatal noDicomDirArg ; fi
ret_check $?
statusPrint	"Checking on <dicomInputDir>"
dirExist_check $G_DICOMINPUTDIR || fatal noDicomDir
cd $G_DICOMINPUTDIR >/dev/null
G_DICOMINPUTDIR=$(pwd)
cd $topDir
lprintn "<dicomInputDir>: $G_DICOMINPUTDIR"
statusPrint	"Checking on <dicomInputDir>/<dcm> file"
DICOMTOPFILE=$(ls -1 ${G_DICOMINPUTDIR}/*1.dcm 2>/dev/null | head -n 1)
fileExist_check $DICOMTOPFILE || fatal noDicomFile

## Check on DICOM meta data
statusPrint	"Querying <dicomInputDir> for sequences"
G_DCM_MKINDX=$(dcm_mkIndx.bash -i $DICOMTOPFILE)
ret_check $?
MANUFACTURER=$(echo "$G_DCM_MKINDX" 	|\
		 grep Manu 		|\
		 awk '{for(i=3; i<=NF; i++) printf("%s ", $i); printf("\n");}')
cprint		"Manufacturer"	" [ $MANUFACTURER ]"
Gb_Siemens=$(echo $MANUFACTURER | grep -i Siemens 	| wc -l)
Gb_GE=$(echo $MANUFACTURER 	| grep -i GE		| wc -l)
if (( Gb_Siemens )) ; 	then G_MANUFACTURER="Siemens" ; fi
if (( Gb_GE)) ; 	then G_MANUFACTURER="GE" ; 	fi
MRID=$(MRID_find $G_DICOMINPUTDIR)
cprint		"MRID"		"[ $MRID ]"

## Did the user provide a gradient table override?
if (( Gb_forceGradientFile )) ; then
    G_GRADIENTFILE=$(echo "$G_GRADIENTFILE" | tr -d '"')
    statusPrint "Checking on <gradientTableFile>"
    fileExist_check $G_GRADIENTFILE || fatal noGradientFile
fi

G_RECONALG=$(echo $G_RECONALG | tr '[A-Z]' '[a-z]')
G_IMAGEMODEL=$(echo $G_IMAGEMODEL | tr '[A-Z]' '[a-z]')

cprint          "Algorithm"     "[ $G_RECONALG ]"
cprint          "Image Model"   "[ $G_IMAGEMODEL ]"

if [[ $G_RECONALG != "fact" && $G_RECONALG != "rk2" ]] ; then
    fatal reconAlg
fi
if [[ $G_IMAGEMODEL != "dti" && $G_IMAGEMODEL != "hardi" ]] ; then
    fatal imageModel
fi

## Log directory
statusPrint	"Checking on <logDir>"
if [[ "$G_LOGDIR" == "-x" ]] ; then
    G_LOGDIR=${G_DICOMINPUTDIR}/log${G_DIRSUFFIX}
fi
dirExist_check $G_LOGDIR "created" || mkdir $G_LOGDIR || fatal badLogDir
G_LOGDIR=$(echo $G_LOGDIR | sed 's|/local_mount||g')

## Any output dir overrides?
if (( Gb_useOverrideOut )) ; then
    statusPrint	"Checking on <outputOverride>"
    G_OUTDIR=$(echo "$G_OUTDIR" | tr ' ' '-' | tr -d '"')
    dirExist_check $G_OUTDIR || mkdir "$G_OUTDIR" || fatal badOutDir
    cd $G_OUTDIR >/dev/null
    G_OUTDIR=$(pwd)
fi
topDir=$G_OUTDIR
cd $topDir

# Xvfb checking:
# On the 'seychelles' cluster, a Centos 4.4 version of Xvfb must be used.
# Essentially, this script checks if 'Xvfb' exists on the current PATH;
# if not, it assumes that Xvfb exists in the G_CLUSTERDIR directory

statusPrint		"Checking for Xvfb on current system"
file_checkOnPath	Xvfb
if (( $? )) ; then
	XVFB=${G_CLUSTERDIR}/Xvfb
else
	XVFB="Xvfb"	
fi


## Main processing start
STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($topDir) $G_SELF $*" $STAMPLOG

## Check on cluster access
if (( Gb_runCluster )) ; then
  statusPrint	"Checking on <clusterDir>"
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
    STAGECMD="$STAGE1PROC				\
		-v 10 -D "$G_DICOMINPUTDIR"		\
		$TARGETSPEC				\
                -m $G_DIRSUFFIX                         \
		-L $G_LOGDIR -A	-l			\
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
STAGE1DIR=$(cat $LOGFILE | grep Collection | tail -n 1 	|\
	awk -F \| '{print $4}'				|\
	sed 's/^[ \t]*//;s/[ \t]*$//')

if (( ! ${#STAGE1DIR} )) ; then fatal dependencyStage; fi

G_OUTDIR=$(dirname $STAGE1DIR)
STAGE1OUT=$STAGE1DIR

# Stage 2
STAGE2IN=$STAGE1OUT
STAGE2PROC=dcm2trk.bash
STAGE=2-$STAGE2PROC
STAGE2DIR="${G_OUTDIR}/tract_meta-stage-$STAGE"
if (( ${barr_stage[2]} )) ; then
    statusPrint "$(date) | Processing STAGE 2 - dicom --> trk | START" "\n"
    statusPrint "Checking previous stage dependencies"
    dirExist_check $STAGE2IN || fatal dependencyStage
    GEOPTS=""
    DIFFUSIONDICOM=$(ls -1 $STAGE2IN | head -n 1)
    DIFFUSIONINPUT=$STAGE2IN/$DIFFUSIONDICOM
    case $G_MANUFACTURER
    in
      "Siemens" )
        statusPrint "Extracting meta data: mri_info"
        DIFFUSIONINFO=$(mri_info ${STAGE2IN}/$DIFFUSIONDICOM 2>/dev/null)
	if (( Gb_forceGradientFile )) ; then test 1==1; fi
        ret_check $? || fatal mri_info
        
        # There are two possibilities for Siemens scans:
        #  1. mri_info knows about this type of Siemens scan
        #     and grabs the gradient table from the freesurfer
        #     MGH gradient table
        #  OR
        #  2. mri_info does not know about this type of Siemens scan,
        #     in which case we need to extract the gradients ourselves
        #     using dcm2nii. This next test determines whether the
        #     gradient file was automatically detected and if not
        #     the gradients will be extracted manually.   
        if (( !Gb_forceGradientFile )) ; then
        	G_GRADIENTFILE=$(echo "$DIFFUSIONINFO" 				|\
				 grep GradFile | awk '{print $2}')
		if [[ "$G_GRADIENTFILE" == "" ]] ; then
			statusPrint "Extracting meta data: siemens_diffusionProcess.bash"
			TARGETSPEC=""
        		if (( Gb_useDICOMFile )) ; then
            			TARGETSPEC="-d $G_DICOMINPUTFILE"
        		fi
			siemens_diffusionProcess.bash -D $G_DICOMINPUTDIR 		   \
			    $TARGETSPEC                                                    \
			    -O $G_OUTDIR/siemens_diffusionProcess                          \
                            -L $G_LOGDIR                                                   \
                             >${G_LOGDIR}/${STAGE2PROC}-siemens_diffusionProcess.bash.std  \
	                    2>${G_LOGDIR}/${STAGE2PROC}-siemens_diffusionProcess.bash.err
			DIFFUSIONINFO=$(cat                                                \
                            ${G_LOGDIR}/${STAGE2PROC}-siemens_diffusionProcess.bash.std)
			ret_check $? || fatal siemens_diffusionProcess
        	fi
        	if (( !Gb_useDiffUnpack )) ; then
			DIFFUSIONINPUT=$(find $G_OUTDIR/siemens_diffusionProcess -name "*.nii.gz" | head -n 1)
		fi
	fi
        
        # Add oblique correction to the dti_recon expertOpts file
        DTIOPT=${STAGE2DIR}/dti_recon.opt
	if [[ ! -f $DTIOPT ]] ; then
	    if [[ ! -d $(dirname $DTIOPT) ]] ; then
	    	mkdir -p $(dirname $DTIOPT)
	    fi
	    touch $DTIOPT
	fi
        grep "oc" $DTIOPT > /dev/null 2>/dev/null || \
              echo " -oc" >> $DTIOPT

	;;
      "GE" )
	cprint	"Inline gradient table fixing" "[ $Gb_GEGradientInlineFix ]"
	statusPrint "Extracting meta data: ge_diffusionProcess.bash"
	if (( Gb_GEGradientInlineFix )) ; then GEOPTS="-G"; fi
        TARGETSPEC=""
        if (( Gb_useDICOMFile )) ; then
            TARGETSPEC="-d $G_DICOMINPUTFILE"
        fi
        ge_diffusionProcess.bash -D $G_DICOMINPUTDIR $GEOPTS		   \
            $TARGETSPEC                                                    \
            -O $G_OUTDIR/ge_diffusionProcess                               \
            -L $G_LOGDIR                                                   \
             >${G_LOGDIR}/${STAGE2PROC}-ge_diffusionProcess.bash.std       \
	    2>${G_LOGDIR}/${STAGE2PROC}-ge_diffusionProcess.bash.err  
        DIFFUSIONINFO=$(cat                                                \
            ${G_LOGDIR}/${STAGE2PROC}-ge_diffusionProcess.bash.std)
        ret_check $? || fatal ge_diffusionProcess
	if (( !Gb_useDiffUnpack )) ; then
	  DIFFUSIONINPUT=$(find $G_OUTDIR/ge_diffusionProcess -name "*.nii.gz" | head -n 1)
	fi
	if (( !Gb_GEGradientInlineFix )) ; then
	   grep "Z" $(expertOpts_file $STAGE2PROC)			   \
		>/dev/null 2>/dev/null					|| \
		echo "-Z" >> $(expertOpts_file $STAGE2PROC)
           echo "opt file: $(expertOpts_file $STAGE2PROC)"
 	fi
	;;
      *) fatal unknownManufacturer
	;;
    esac
    if (( !Gb_forceGradientFile )) ; then
        G_GRADIENTFILE=$(echo "$DIFFUSIONINFO" 				|\
			 grep GradFile | awk '{print $2}')    
    fi
    cprint 	"Gradient File" 	"[ $(basename $G_GRADIENTFILE) ]"
    statusPrint "Checking gradient file"
    fileExist_check $G_GRADIENTFILE || fatal noGradientFile
    if (( Gb_forceGradientFile )) ; then
      G_nDIR=$(cat $G_GRADIENTFILE | wc -l)
    else
      G_nDIR=$(echo "$DIFFUSIONINFO" | grep "nDir" | awk '{print $3}')
    fi
    cprint 	"Gradient Directions"	"[ $G_nDIR ]"
    G_nB0=$(echo "$DIFFUSIONINFO" | grep "B0" | awk '{print $3}')
    if (( ! ${#G_nB0} )) ; then G_nB0="unknown" ; fi
    cprint	"Number of B0 Volumes"	"[ $G_nB0 ]"
    statusPrint	"Checking stage output root directory"
    dirExist_check $STAGE2DIR "created" || mkdir $STAGE2DIR
    STAGESTEPS="12345"
    FA=""
    if (( Gb_skipEddyCurrentCorrection )) ; then STAGESTEPS="1345" ; fi
    if (( Gb_useFA )) ; then FA="-F $G_FALOWERTHRESHOLD" ; fi
    EXOPTS=$(eval expertOpts_parse $STAGE2PROC)
    SKIPDIFFUNPACK=""
    if (( !Gb_useDiffUnpack )) ; then SKIPDIFFUNPACK="-U"; fi
    B0Vols="-B $G_nB0"
    if (( Gb_b0override )) ; then B0Vols="-B $Gi_b0vols" ; fi
    STAGECMD="$STAGE2PROC				\
		-v 10 -d $DIFFUSIONINPUT		\
		$SKIPDIFFUNPACK				\
                -A $G_RECONALG -I $G_IMAGEMODEL         \
                $FA
		-g $G_GRADIENTFILE			\
		-O $STAGE2DIR				\
		-o ${MRID}${G_OUTSUFFIX}		\
		-E $EXOPTS                              \
		-b $Gi_bValue				\
                $B0Vols                                 \
                $G_iX $G_iY $G_iZ                       \
		-t $STAGESTEPS -f"
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE2PROC}.std"         \
                "${G_LOGDIR}/${STAGE2PROC}.err"         \
         || fatal stageRun
         
         
    # Now, generate a preview mosaic image for the trk file
    statusPrint "$(date) | Processing STAGE 2 - generate preview mosaic | BEGIN" "\n"
    cd $STAGE2DIR/final-trackvis
    tract_slice.bash -v 10 -V -d 1 -B $XVFB                           \
                     -T 1 -t ${MRID}${G_OUTSUFFIX}.trk                \
                     >${G_LOGDIR}/${STAGE2PROC}-tract_slice.bash.std  \
	    			2>${G_LOGDIR}/${STAGE2PROC}-tract_slice.bash.err
    
    convert -page +0+0 AXI/*.png -page +1000+0 COR/*.png     \
            -background wheat -page +500+800 SAG/*.png       \
            -mosaic ${MRID}${G_OUTSUFFIX}.trk.png            \
            > ${G_LOGDIR}/${STAGE2PROC}-convert.std          \
           2> ${G_LOGDIR}/${STAGE2PROC}-convert.err
       
    statusPrint "$(date) | Processing STAGE 2 - generate preview mosaic | END" "\n"
    
         
    statusPrint "$(date) | Processing STAGE 2 - dicom --> trk | END" "\n"
fi

# Stage 3
STAGE2OUTDIR=${STAGE2DIR}/final-trackvis
STAGE2OUTFILE=$(find $STAGE2OUTDIR -iname "*.trk")
STAGE3IN=$STAGE2OUTFILE
STAGE3PROC=tract_slice.bash
STAGE3REQUIREDFILES="$XVFB"
STAGE3DISPLAY="1"
STAGE=3-$STAGE3PROC
STAGE3DIR="${G_OUTDIR}/tract_meta-stage-$STAGE"
if (( ${barr_stage[3]} )) ; then
    cd $STAGE2DIR
    statusPrint "$(date) | Processing STAGE 3 - trk --> png | START" "\n"
    statusPrint "Checking previous stage dependencies"
    fileExist_check $STAGE3IN || fatal dependencyStage
    for file in $STAGE3REQUIREDFILES ; do
        statusPrint	"Checking for $file..."
        file_checkOnPath $file || fatal fileCheck
    done
    statusPrint	"Checking stage output root directory"
    dirExist_check $STAGE3DIR || mkdir $STAGE3DIR
    EXOPTS=$(eval expertOpts_parse $STAGE3PROC)
    cd $STAGE3DIR
    STAGECMD="$STAGE3PROC				\
		-v 10 -V -m 2 -x 65 -y 65 -a		\
		-d $STAGE3DISPLAY -B $XVFB		\
		-t $STAGE2OUTFILE			\
		$EXOPTS"
#     echo $STAGECMD
    stage_run "$STAGE" "$STAGECMD"                      \
                "${G_LOGDIR}/${STAGE3PROC}.std"         \
                "${G_LOGDIR}/${STAGE3PROC}.err"         \
        || fatal stageRun
    statusPrint "$(date) | Processing STAGE 3 - trk --> png | END" "\n"
fi

# Stage 4
STAGE4PROC=img2dicom.m
STAGE=4-$STAGE4PROC
STAGE4DIR=${G_OUTDIR}/tract_meta-stage-$STAGE
STAGE4IN=${STAGE3DIR}/${STAGE3PROC}.log
STAGE4OUTFILE=${STAGE4DIR}/img2dicom_drive.m
if (( ${barr_stage[4]} )) ; then
    statusPrint "$(date) | Processing STAGE 4 - png --> dcm | START" "\n"
    statusPrint "Checking previous stage dependencies"
    fileExist_check $STAGE4IN || fatal dependencyStage
    statusPrint	"Checking stage output root directory"
    dirExist_check $STAGE4DIR || mkdir $STAGE4DIR
    cd $STAGE4DIR
    matlab_check
    statusPrint	"Creating MatLAB driver file"
    matlabFile_create 	$STAGE1OUT			\
			$STAGE3DIR			\
			$STAGE4DIR			\
			$STAGE4OUTFILE
    ret_check $?
    STAGECMD="$G_MATLAB -r \"c = img2dicom(); c = img2dicom_drive() ; exit\""
#     echo $STAGECMD
    stage_run "$STAGE" "$STAGECMD"                      \
                 "${G_LOGDIR}/${STAGE4PROC}.std"        \
                 "${G_LOGDIR}/${STAGE4PROC}.err"        \
          || fatal stageRun
    statusPrint "$(date) | Processing STAGE 4 - png --> dcm | END" "\n"
    mv $STAGE4OUTFILE $G_OUTDIR
fi

# Stage 5
STAGE5PROC=dicom_dirSend.bash
STAGE=5-$STAGE5PROC
STAGE5IN=${G_OUTDIR}/img2dicom_drive.m
if (( ${barr_stage[5]} )) ; then
    statusPrint "$(date) | Processing STAGE 5 - dcm --> PACS | START" "\n"
    statusPrint "Checking previous stage dependencies"
    fileExist_check $STAGE5IN || fatal dependencyStage
    statusPrint	"Checking directory to transmit"
    dirExist_check $STAGE4DIR || fatal dependencyStage
    STORESCU=""
    # Check for valid 'storescu'. If not found, force to the version 
    # in the cluster directory (note this version might have distro
    # conflicts!)
    statusPrint "Checking for 'storescu'"
    file_checkOnPath storescu || STORESCU="-s ${G_CLUSTERDIR}/storescu"
    STAGECMD="$STAGE5PROC		 		\
		-v -a ELLENGRANT			\
		-h kaos.nmr.mgh.harvard.edu		\
		-p 10401				\
		$STORESCU				\
		$STAGE4DIR"
#     echo $STAGECMD
    stage_run "$STAGE" "$STAGECMD" 
                "${G_LOGDIR}/${STAGE5PROC}.std"         \
                "${G_LOGDIR}/${STAGE5PROC}.err"         \
          || fatal stageRun
    statusPrint "$(date) | Processing STAGE 5 - dcm --> PACS | END" "\n"
fi

STAGE="Normal termination -- collecting log files"
statusPrint	"Checking final log dir"
FINALLOG=${G_OUTDIR}/log${G_DIRSUFFIX}
dirExist_check	${G_OUTDIR}/log "created" || mkdir $FINALLOG
for EXT in "log" "err" "std" ; do
    find ${G_OUTDIR} -iname "*.$EXT" -exec cp {} $FINALLOG 2>/dev/null
done
cp ${G_LOGDIR}/* $FINALLOG
stage_stamp "$STAGE" $STAMPLOG

printf "%40s" "Cleaning up"

mail_reports
shut_down 0

