#!/bin/bash

# "include" the set of common script functions
source common.bash

declare -i Gi_verbose=0
declare -i Gb_useOverrideOut=0
declare -i Gb_forceStage=1
declare -i Gb_scanAll=0

DICOMDIR="/chb/osx1927/1/users/dicom/files"
MRISLIST=""
G_SYNOPSIS="

 NAME

	dcm_MRIDget.bash

 SYNOPSIS

	dcm_MRIDget.bash 	[-v <verbosity>] 		\\
				[-d <dicomDir>] 		\\
				[-a]				\\
				[<MRID1> <MRID2> ... <MRIDn>]

 DESCRIPTION

	'dcm_MRIDget.bash' targets a given <dicomDir>, and for each
	subdirectory, checks for the MRID.

 ARGUMENTS

	-v <level> (optional)
	Verbosity level.

	-d <dicomDir> (optional)
	The 'root' directory containing dicom subdirs.
	Defaults to $DICOMDIR.

	-a (optional)
	Scan all directories in <dicomDir>. By default, the script will
	only flag the first directory containing the MRID. For multiple
	scans of the same MRID, the *entire* directory needs to be scanned.

	<MRID1> <MRID2> ... <MRIDn>
	A list of target MRIDs. If specified, dcm_MRIDget will only search
	for these MRIDs, otherwise all MRIDs in <dicomDir> will be shown.

 PRECONDITIONS
	
	o /usr/pubsw/bin/dcm_dump_file
	o Assumes that the <dicomDir> is a 'root' directory containing 
	  subdirectories, each of which contains dicoms for a particular 
	  MRID.
	o FreeSurfer env.

 POSTCONDITIONS

	o For each subdir in <dicomDir>, the MRID associated with each
	  subdir is displayed. If a MRID is specified on the command line
	  the script will only output the particular subdirectory containing
	  the passed MRID.

 HISTORY

	19 April 2006
	o Initial design and coding.
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///

# Actions
A_noDCMFILE="checking for <DCMFILE>"
A_noDICOMDIR="checking on <dicomDir>"
A_noSubjectsDirVar="checking environment"

# Error messages
EM_noDCMFILE="could not read <DCMFILE>."
EM_noDICOMDIR="could not find <dicomDir>."
EM_noSubjectsDirVar="it seems that the SUBJECTS_DIR environment var is not set."

# Error codes
EC_noDCMFILE=1
EC_noDICOMDIR=2
EC_noSubjectsDir=10

# Defaults
D_whatever=

###\\\
# Function definitions
###///


###\\\
# Process command options
###///

while getopts d:v:a option ; do 
	case "$option"
	in
		d) DICOMDIR=$OPTARG ;;
		a) let Gb_scanAll=1 ;;
		v) let Gi_verbose=$OPTARG ;;
		\?) synopsis_show 
		    exit 0;;
	esac
done

verbosity_check
topDir=$(pwd)

printf "%40s"	"Checking for SUBJECTS_DIR env variable"
b_subjectsDir=$(set | grep SUBJECTS_DIR | wc -l)
if (( !b_subjectsDir )) ; then
	fatal noSubjectsDirVar
fi
ret_check $?

printf "%40s"   "Checking for <dicomDir>"
dirExist_check $DICOMDIR || fatal noDICOMDIR
cd $DICOMDIR ; DICOMDIR=$(pwd) ; cd $topDir

shift $(($OPTIND - 1))
DCMLIST=$*
b_DCMLIST=$(echo $DCMLIST | wc -w)

cd $DICOMDIR
let hitCount=0
let b_hit=0
exec 1>&6 6>&-
for DIR in * ; do
    dirExist_check $DIR >/dev/null
    if (( !$? )) ; then 
	cd "$DIR" >/dev/null 2>/dev/null; 
	ID=$(dcm_mkIndx.bash 2>/dev/null | grep ID | awk '{print $3}'); 
	b_MRID=$(echo "$ID" | wc -w)
	if (( b_MRID )) ; then
		b_hit=1
		if (( b_DCMLIST )) ; then
			b_hit=$(echo "$DCMLIST" | grep $ID | wc -l)
		fi
		if (( b_hit )) ; then
			printf "%-55s\t" "$DIR"; 
			printf "%25s\n" "$ID"; 
			let "hitCount += 1"
			if (( b_DCMLIST )) ; then
			    if (( hitCount >= b_DCMLIST && !Gb_scanAll )) ; then
				verbosity_check
				shut_down 0
			    fi
			fi
		fi
	fi
	cd $DICOMDIR; 
    fi
done

verbosity_check
if (( b_hit )) ; then
	shut_down 0
else
	shut_down 1
fi
