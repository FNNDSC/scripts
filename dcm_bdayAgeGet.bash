#!/bin/bash
#
# mcheck-fs_meta.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

let Gi_verbose=0

G_SYNOPSIS="

 NAME

	dcm_bdayAgeGet.bash

 SYNOPSIS

	dcm_bdayAgeGet.bash [-v <verbosity>] <DCMFILE>

 DESCRIPTION

	'dcm_bdayAgeGet.bash' is a simple wrapper about dcm_dump_file
	that filters out the age and birthday field from a <DCMDIR>.

 ARGUMENTS

	-v <level> (optional)
	Verbosity level.

	<DCMFILE>
	A DiCOM file.

 PRECONDITIONS
	
	o /usr/pubsw/bin/dcm_dump_file

 POSTCONDITIONS

	o Age and birthdate data are echoed to stdout

 HISTORY

	19 April 2006
	o Initial design and coding.
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///
G_SELF=`basename $0`
G_PID=$$

# Actions
A_noDCMFILE="checking for <DCMFILE>"

# Error messages
EM_noDCMFILE="could not read <DCMFILE>."

# Error codes
EC_noDCMFILE=1

# Defaults
D_whatever=

###\\\
# Function definitions
###///


###\\\
# Process command options
###///

while getopts v: option ; do 
	case "$option"
	in
		v) let Gi_verbose=$OPTARG ;;
		\?) synopsis_show 
		    exit 0;;
	esac
done


verbosity_check
topDir=$(pwd)
shift $(($OPTIND - 1))
DCMFILE=$1

if (( ${#DCMFILE} )) ; then
    statusPrint	"Checking for <DCMFILE>"
    fileExist_check $DCMFILE || fatal noDCMFILE
else
    DCMFILE=$(ls -1 *1.dcm | head -n 1)
fi

if (( 0 == 1 )) ; then
    DCM_DUMP_FILE=/usr/pubsw/bin/dcm_dump_file

    BDAY=$($DCM_DUMP_FILE $DCMFILE 2>/dev/null			|\
				 grep -i "Patient Birthdate" 	|\
				 awk '{print $7}' 		|\
				 awk -F "//" '{print $2}')

    AGE=$($DCM_DUMP_FILE $DCMFILE 2>/dev/null			|\
				 grep -i "Patient Age" 		|\
				 awk '{print $7}' 		|\
				 awk -F "//" '{print $2}')

    IMAGEDATE=$($DCM_DUMP_FILE $DCMFILE 2>/dev/null		|\
				 grep -i "Image Date" 		|\
				 awk '{print $7}' 		|\
				 awk -F "//" '{print $2}')
else
        NAME=$(mri_probedicom --i $DCMFILE --t 10 10)
        AGE=$(mri_probedicom --i $DCMFILE --t 10 1010)
        SEX=$(mri_probedicom --i $DCMFILE --t 10 40)
        BDAY=$(mri_probedicom --i $DCMFILE --t 10 30)
        IMAGEDATE=$(mri_probedicom --i $DCMFILE --t 08 23)
fi
exec 1>&6 6>&-

printf "%40s\t%-20s\n" "Patient Age at scan" 	"$AGE"
printf "%40s\t%-20s\n" "Patient birthday" 	"$BDAY"
printf "%40s\t%-20s\n" "Image date" 		"$IMAGEDATE"
printf "%40s\t%-20s\n" "Patient name" 		"$NAME"
printf "%40s\t%-20s\n" "Patient sex" 		"$SEX"

verbosity_check
statusPrint	"Cleaning up"
shut_down 0

