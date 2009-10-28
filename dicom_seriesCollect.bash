#!/bin/bash
#
# dicom_seriesCollect.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

declare -i Gi_verbose=0
declare -i Gi_fileCount=0
declare -i Gb_useExperOptions=0
declare -i Gb_useDICOMFile=0
declare -i Gb_useDICOMSeries=0
declare -i Gb_findAllSeries=0
declare -i Gb_tagSet=0
declare -i Gb_useOverrideOut=0
declare -i Gb_useMRID=1
declare -i Gi_exitCode=1
declare -i Gb_doNotCleanOutputDir=0

G_LOGDIR="-x"
G_MRID=""
G_STAGES="1"
G_OUTDIR="./"
G_OUTROOTDIR="/space/kaos/5/users/dicom/postproc"
G_MRIDSUFFIX=""
G_TAGDIR=""
G_DICOMINPUTDIR="-x"
G_DICOMINPUTFILE="-x"
G_DICOMINPUTFILELIST=""
G_DICOMSERIESLIST="
	DIFFUSION_HighRes
	ISO DIFFUSION TRUE AXIAL
"
G_DICOMSERIESFILE=""

G_COPY="/bin/cp"

G_DCM_MKINDX="dcm_mkIndx.bash"

G_SYNOPSIS="

 NAME

	dicom_seriesCollect.bash

 SYNOPSIS

	dicom_seriesCollect.bash	-D <dicomInputDir>		\\
					[-d <dicomInputFile>]		\\
					[-L <logDir>]			\\
					[-R <outputRootDir>]		\\
					[-M] [-m <MRIDsuffix>]		\\
					[-T <outputTagDir>]		\\
					[-O <outputOverride>] [-C]	\\
					[-v <verbosity>]		\\
					[-S <dicomSeriesList>] [-A]	\\
					[-l]				\\
                                	[-E]

 DESCRIPTION

	'dicom_seriesCollect' retrieves a specific DICOM series from a target
	repository directory <dicomInputDir> and copies to <dicomOutputDir>.
	It was originally designed to be part of the 'track_meta.bash' 
	tractography pipeline.

	By default, the script will scan all DICOM series in the target
	directory for the first instance matching the list of scans in 
	G_DICOMSERIESLIST. All scans pertaining to this series will then
	be copied over to <dicomOutputDir>.

	Other modes are also available. A series name can be explicitly 
	specified using '-S <dicomSeriesName>', or simply a single DICOM
	file in a desired series with '-d <dicomInputFile>'.

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

	-S <dicomSeriesList> (Optional)
	If specified, override the automatic sequence detection and run the
	pipeline seeded on the specific series list candidate. Separate series
	names with a ';'.

	-l (Optional)
	If specified, perform a symbolic link when collecting the files.
	Otherwise, copy the files.

	-A (Optional -- bool default: $Gb_findAllSeries)
	Find all series. By default, the <dicomInputDir> is searched for the
	first sequence that matches the first hit in the <dicomSeriesList>. By
	specifying a '-A', *all* sequences in the <dicomSeriesList> are 
	searched for. Note also that the '-A' search is a substring search.
	If the <dicomSeriesList> contains '3D SPGR', then all sequences
	containing the term '3D SPGR' are collected.

	-R <outputRootDir> 	(Optional: $G_OUTDIR)
	-M 			(Optional: $Gb_useMRID)
	-m <MRIDsuffix>		(Optional)
	-T <outputTagDir>	(Optional: $G_TAGDIR)
	-O <outputOverride>	(Optional: $G_OUTDIR)

	These flags specify the destination directory for the collected
	DICOM files. This directory is constructed as:

		<outputRootDir>/<MRID><MRIDsuffix>/<outputTagDir>

	where the <MRID> denotes the MRID field in the original input
	DICOM. If none of these flags are specified, the script will 
	dump its files to 
	
		<outputRootDir>/<MRID><MRIDsuffix>/<sequenceName>

	The '-M' flag in this case turns OFF the <MRID> collection, and
	should only be used with caution.
	
	Since a single MRID can contain multiple sequences of a similar
	type, and since concurrent processing of these types can cause
	interference, the <MRIDsuffix> can be used to further differentiate
	an analysis if necessary.

	If a simple output directory is required, then use the 
	'-O <outputOverride>'.

	-C (Optional: Default $Gb_doNotCleanOutputDir)
	If specified, do not clean the output dir if it already exists. This
	is useful for cases when DICOM files from several input sequences are
	being collected in a single directory. Most likely, this option will
	only be necessary if an '-O <outputOverride>' has been made.

 STAGES

        'dicom_seriesCollect' has a single operational stage:

        1 - Collect a DICOM series from a given directory and transfer to
	    a target directory.

 PRECONDITIONS
	
	o A FreeSurfer 'std' or 'dev' environment.

 POSTCONDITIONS

        o Targetted DICOM series is collected (either copied or linked).

 SEE ALSO

	o track_meta.bash

 HISTORY

	29 April 2008
	o Initial design and coding (stripped from 'track_meta.bash').

"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///
G_SELF=`basename $0`
G_PID=$$

# Actions
A_fileCheck="checking for a required file dependency"
A_metaLog="checking the dicom_seriesCollect.bash.log file"
A_noDicomDirArg="checking for the -D <dicomInputDir> argument"
A_noDicomDir="checking if the <dicomInputDir> is accessible"
A_noOutRootDir="checking if the <outputRootDir> is accessible"
A_noDicomFile="checking on the <dicomInputFile> access"
A_noDicomSeries="scanning for the target series"
A_collectionDirCreate="creating the collection directory"
A_dicomCopy="copying the DICOM files from source to collection"
A_noFilesFlagged="scanning for DICOM files to flag"
A_badLogDir="checking on the log directory"
A_badLogFile="checking on the log file"
A_badOutDir="checking on <outputOverride>"

# Error messages
EM_fileCheck="it seems that a dependency is missing."
EM_metaLog="it seems as though this stage has already run.\n\tYou can force execution with a '-f'"
EM_noDicomDirArg="it seems that the <dicomInputDir> argument was not specified."
EM_noDicomDir="I am having problems accessing the <dicomInputDir>. Does it exist?"
EM_noOutRootDir="I am having problems accessing the <outputRootDir>. Does it exist?"
EM_noDicomFile="I am having problems accessing the <dicomInputFile>. Does it exist?"
EM_noDicomSeries="I couldn't find the target series."
EM_collectionDirCreate="I couldn't create the directory. Do you have permission?"
EM_dicomCopy="some copy error ocurred. Do you have sufficient rights and space?"
EM_noFilesFlagged="I couldn't find any files in target series."
EM_badLogDir="I couldn't access the <logDir>. Does it exist?"
EM_badLogFile="I couldn't access a specific log file. Does it exist?"
EM_badOutDir="I couldn't create the <outputOverride> dir."

# Error codes
EC_fileCheck=1
EC_metaLog=80
EC_noDicomFile=11
EC_noDicomDirArg=12
EC_noDicomDir=13
EC_noOutRootDir=14
EC_noDicomSeries=15
EC_collectionDirCreate=16
EC_dicomCopy=17
EC_noFilesFlagged=30
EC_badLogDir=20
EC_badLogFile=21
EC_badOutDir=22

# Defaults
D_whatever=

###\\\
# Function definitions
###///

function expertOpts_parse
{
    # ARGS
    # $1                        process name
    #
    # DESC
    # Checks for <processName>.opt in $G_OUTDIR.
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
    MRID=$(eval $G_DCM_MKINDX | grep Patient | awk '{print $3}')
    cd $here >/dev/null
    echo $MRID
}

function DICOMseries_findAll
{
    #
    # ARGS
    # $1		directory to scan
    #
    # DESCRIPTION
    # This function scans the input directory for all sequences
    # that match any sequences in the G_DICOMSERIESLIST.
    # 
    # PRECONDITIONS
    # o The input directory should contain DICOM files as written
    #   by NMR / dcmtk processes.
    #   
    # POSTCONDITIONS
    # o The output is a column list of DICOM file names that match
    #   the search criteria.
    #

    declare -i b_hit=0
    declare -i seriesCount=0
    declare -i fileFields=0
    local dcm_series="-x"

    here=$(pwd)
    cd $G_DICOMINPUTDIR >/dev/null
    statusPrint "Creating sequence/file list..." "\n"
    INDEX=$(eval $G_DCM_MKINDX)
    dcm_series=$(
      for indexLineNum in $(seq 1 $(echo "$INDEX" | wc -l)) ; do
	indexLine=$(echo "$INDEX" | head -$indexLineNum | tail -1 	|\
			sed 's/^[ \t]*//' )
	for seriesLineNum in $(seq 1 $(echo "$G_DICOMSERIESLIST" | wc -l)) ; do
	  seriesLine=$(echo "$G_DICOMSERIESLIST" 			|\
			 head -$seriesLineNum | tail -1 |sed 's/^[ \t]*//')
	  if (( ${#indexLine} && ${#seriesLine} )) ; then
	    dcm_seriesHit=$(echo "$indexLine" | grep "$seriesLine")
	    if (( ${#dcm_seriesHit} )) ; then
		echo "$dcm_seriesHit" | awk '{print $2}'
	    fi
	  fi
	done
      done
    )
    G_DICOMSERIESFILE="$dcm_series"
}

function DICOMfiles_find
{
    #
    # ARGS
    # $1		directory to scan
    #
    # DESCRIPTION
    # This function handles the 'targetting' of actual DICOM files
    # in the passed input directory. Files are flagged in various 
    # ways: either by searching for a sequence name, or starting with
    # a target file and finding all others in the same sequence.
    # 
    # PRECONDITIONS
    # o The input directory should contain DICOM files as written
    #   by NMR / dcmtk processes.
    #   
    # POSTCONDITIONS
    # o Flagged files are added to the global variable, 
    # 	G_DICOMINPUTFILELIST.
    # o Number of files flagged are stored in the global Gi_fileCount.
    #

    declare -i b_hit=0
    declare -i seriesCount=0
    declare -i fileFields=0
    local dcm_file="NotFound"
    local dcm_series="-x"
    local dcm_list=""

    here=$(pwd)
    cd $G_DICOMINPUTDIR >/dev/null
    statusPrint "Scanning for target series..." "\n"
    INDEX=$(eval $G_DCM_MKINDX)
    if (( ! Gb_useDICOMFile )) ; then
	dcm_series=$(echo "$G_DICOMSERIESLIST" 				|\
		sed 's/^[ \t]*//;s/[ \t]*$//'				|\
		awk -v str_table="$INDEX" 				\
        '  								\
	BEGIN {								\
            b_hit = 0;							\
            #printf("input table = %s\n", str_table);			\
	}								\
        {								\
          str_target = $0;						\
          #printf("Checking -->%s<--...", str_target);			\
          #printf("%d\n", index(str_table, str_target));		\
          if(!b_hit && index(str_table, str_target)>1) {		\
            b_hit = 1;							\
            printf("%s\n", str_target);					\
          }								\
        }'								\
	)
	b_hit=${#dcm_series}
	if (( b_hit )) ; then
	    dcm_file=$(echo "$INDEX" | grep "$dcm_series" | head -1 | awk '{print $2}')
	    dcm_series=$(mri_probedicom --i $dcm_file --t 0008 103e)
	fi
    else
	if [[ -f $G_DICOMINPUTFILE ]] ; then
	    dcm_file=$G_DICOMINPUTFILE
	    dcm_series=$(mri_probedicom --i $dcm_file --t 0008 103e)
	fi
    fi
    cprint	"target file"	"[ $dcm_file ]"
    cprint 	"target series" "[ $dcm_series ]"
    if [[ $dcm_file != "NotFound" ]] ; then
	if (( Gb_useMRID )) ; then
	    G_MRID=$(echo "$INDEX" | grep "Patient" | awk '{print $3}')
	    cprint "MRID" "[ $G_MRID ]"
	fi 
	statusPrint "Tagging all files in series..." "\n"
	dcm_list=""
	fileFields=$(echo $dcm_file | awk -F\- '{print NF}')
	if (( fileFields == 3 )) ; then
	    tagBase=$(echo $dcm_file | awk -F\- '{printf("%s-%s-*", $1, $2);}')
	    dcm_list=$(eval echo $tagBase)
	    seriesCount=$(/bin/ls -1 $(eval echo $tagBase) | wc -l)
	else
	    cprint "Non-standard filenames found"          \
	    "[ performing exhaustive search ]"
	    for dicomfile in * ; do
	      series=$(mri_probedicom --i $dicomfile --t 0008 103e)
	      if [[ "$series" == "$dcm_series" ]] ; then
		dcm_list="$dcm_list $dicomfile"
		seriesCount=$(expr $seriesCount + 1)
	      fi
	    done
	    printf "\n"
	fi
    fi
    cprint	"target file count"	"[ $seriesCount ]"
    G_DICOMINPUTFILELIST="$dcm_list"
    Gi_fileCount=$seriesCount
    if (( ! Gb_tagSet )) ; then
# 	G_TAGDIR=$(echo "$dcm_series" | tr ' ' '-' | tr '\(' '-' | tr '\)' '-')
        G_TAGDIR=$(string_clean "$dcm_series")
    fi
    cd $here >/dev/null
}

function DICOM_tagAndCollect
{
    #
    # ARGS
    # (none)
    # 
    # DESCRIPTION
    # This function embodies the main purpose of this script -- it
    # tags the targetted DICOM files pending user selection, and collects
    # them in the target directory. 
    # 
    statusPrint "$(date) | Tagging DICOM files | START" "\n"
    DICOMfiles_find $G_DICOMINPUTDIR
    statusPrint "$(date) | Tagging DICOM files | END" "\n"
    if (( Gi_fileCount )) ; then
	if (( ! $Gb_useOverrideOut )) ; then
	    G_OUTDIR=${G_OUTROOTDIR}/${G_MRID}${G_MRIDSUFFIX}/${G_TAGDIR}
	fi
	statusPrint "$(date) | Collecting DICOM files | START" "\n"
	echo $G_OUTDIR
	stage_stamp "Collection | $G_OUTDIR" $STAMPLOG
	if [[ ! -d $G_OUTDIR ]] ; then
	    statusPrint "Creating collection directory"
	    mkdir -p $G_OUTDIR || fatal collectionDirCreate
	    ret_check $?
	else
	  if (( ! Gb_doNotCleanOutputDir )) ; then
	    statusPrint "Cleaning collection directory"
	    cd $G_OUTDIR >/dev/null
	    rm -f *
	    ret_check $?
	  fi
	fi
	cd $G_OUTDIR >/dev/null
	cprint "Collection command" " [ $G_COPY ]"
	statusPrint "Collecting DICOM files..."
	# Here we collect the target files using an explicit loop since
	# for very long file list arguments, shell buffer space might
	# be exhausted.
	for FILE in $G_DICOMINPUTFILELIST ; do
	    eval $G_COPY ${G_DICOMINPUTDIR}/$FILE .
	done
	ret_check $? || fatal dicomCopy
	statusPrint "$(date) | Collecting DICOM files | END" "\n"
    fi
}

###\\\
# Process command options
###///

while getopts v:E:R:Mm:T:D:d:S:AL:O:Cl option ; do 
	case "$option"
	in
		v) 	Gi_verbose=$OPTARG		;;
		L)	G_LOGDIR=$OPTARG		;;
		E) 	Gb_useExperOptions=1		;;
		R)	G_OUTROOTDIR=$OPTARG		;;
		M)	Gb_useMRID=0			;;
		m)	G_MRIDSUFFIX=$OPTARG		;;
		T)	G_TAGDIR=$OPTARG		;;
                O) 	Gb_useOverrideOut=1		
			G_OUTDIR=$OPTARG                ;;
		S) 	Gb_useDICOMSeries=1
			G_DICOMSERIESLIST=$OPTARG	;;
		D)	G_DICOMINPUTDIR=$OPTARG		;;
		d)	Gb_useDICOMFile=1		
			G_DICOMINPUTFILE=$OPTARG	;;
		A)	Gb_findAllSeries=1		;;
		C)	Gb_doNotCleanOutputDir=1	;;
		l)	G_COPY="/bin/ln -s"		;;
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

statusPrint	"Checking on <logDir>"
if [[ "$G_LOGDIR" == "-x" ]] ; then
    G_LOGDIR=${G_DICOMINPUTDIR}/log
fi
dirExist_check $G_LOGDIR "created" || mkdir $G_LOGDIR || fatal badLogDir

if (( Gb_useOverrideOut )) ; then
    statusPrint	"Checking on <outputOverride>"
    G_OUTDIR=$(echo $G_OUTDIR | tr ' ' '-' | tr -d '"')
    dirExist_check $G_OUTDIR "not found - creating" || mkdir "${G_OUTDIR}" || fatal badOutDir
    cd $G_OUTDIR >/dev/null
    G_OUTDIR=$(pwd)
    cd $topDir
fi

REQUIREDFILES="common.bash mri_probedicom /bin/cp /bin/ln"
for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file..."
        file_checkOnPath $file || fatal fileCheck
done

statusPrint	"Checking on <outputRootDir>"
G_OUTROOTDIR=$(echo $G_OUTROOTDIR | tr -d '"')
dirExist_check $G_OUTROOTDIR "not found - creating"		\
		|| mkdir -p $G_OUTROOTDIR			\
	 	|| fatal noOutRootDir
cd $G_OUTROOTDIR >/dev/null
G_OUTROOTDIR=$(pwd)
cd $topDir >/dev/null
STAMPLOG=${G_LOGDIR}/${G_SELF}.log

# Convert a user specified list to table
if (( Gb_useDICOMSeries )) ; then
    G_DICOMSERIESLIST=$(echo "$G_DICOMSERIESLIST" | tr ';' '\n')
fi

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
Gi_exitCode=0

if (( ${barr_stage[1]} )) ; then
  stage_stamp "Collecting DICOM - START" $STAMPLOG
  if (( Gb_findAllSeries && !Gb_useDICOMFile )) ; then 
    DICOMseries_findAll
    Gb_useDICOMFile=1
    for indexLineNum in $(seq 1 $(echo "$G_DICOMSERIESFILE" | wc -l)) ; do
      indexLine=$(echo "$G_DICOMSERIESFILE" | head -$indexLineNum | tail -1 	|\
			sed 's/^[ \t]*//' )
      cprint "Tagging sequence file" "[ $indexLine ]"
      G_DICOMINPUTFILE="$indexLine"
      DICOM_tagAndCollect
    done
  else
    DICOM_tagAndCollect
  fi
  if (( !Gi_fileCount )) ; then
      fatal noFilesFlagged
  fi
  stage_stamp "Collecting DICOM - END" $STAMPLOG
fi

STAGE="Normal termination"
stage_stamp "$STAGE" $STAMPLOG

cd $topDir
printf "%40s" "Cleaning up"
shut_down $Gi_exitCode

