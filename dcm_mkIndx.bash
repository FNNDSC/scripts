#!/bin/bash
#
# dcm_coreg.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

declare -i      Gi_verbose=0
declare -i      Gi_showAll=0
declare -i      Gb_translateSpace=0

G_SPACECHAR="-"

G_SYNOPSIS="

 NAME

	$SELF

 SYNOPSIS

	$SELF [-i <dcmFile>] [-a] [-t <translateSpaceChar>]

 DESCRIPTION

	'$SELF' is a simple wrapper about 'mri_probedicom' that generates
	a simple table in a directory of DICOM files from an MRI study.

 ARGUMENTS

	-a (Optional Boolean: $Gi_showAll)
	If specified, show additional (non-anonymous data) such as
	patient name.

	-i <dcmFile> (Optional file specifier)
	If specified, use the passed <dcmFile> to run the index against.
	Otherwise, use the first file in the current directory.

	-t <translateSpaceChar> (Optional space translator)
	If specified, replace any spaces in series names with the 
	<translateSpaceChar>.

 PRECONDITIONS

	o nse/nde

	o In default mode, the current working dir must be populated 
	  with DiCOM data.

 POSTCONDITIONS

	o A simple table is dumped to stdout.

 HISTORY

 07 Feb 2005
 o Initial design and coding.

 16 July 2008
 o Misc extensions, adding the [-a] flag.	

 01 October 2008
 o Added patient bday, age, and scan date.
 
 11 May 2009
 o Changed lookup method for Age, Sex, etc. from original dcm_dump_file
   to mri_probedicom.
"

TOPSET=$(/bin/ls -1 *1.dcm 2>/dev/null | head -n 1)
while getopts hai:t: option ; do
        case "$option"
        in
		h) 	synopsis_show
			exit 0;;
		a)	let Gi_showAll=1	;;
		i)	TOPSET=$OPTARG 
			b_FORCESET=1		;;
		t)	Gb_translateSpace=1
			G_SPACECHAR=$OPTARG     ;;
		\?) 	synopsis_show
                    	exit 0;;
        esac
done

PATIENTID=$(mri_probedicom --i $TOPSET --t 10 20)
#PATIENTID=$(echo $PATIENTID | sed 's/\([0-9]*\).*/\1/')

printf "%40s\t%-20s\n" "Patient ID" $PATIENTID
if (( Gi_showAll )) ; then
	PATIENTNAME=$(mri_probedicom --i $TOPSET --t 10 10)
	PATIENTSEX=$(mri_probedicom --i $TOPSET --t 10 40)
	PATIENTBDAY=$(mri_probedicom --i $TOPSET --t 10 30)
	PATIENTSCANDATE=$(mri_probedicom --i $TOPSET --t 08 23)
	
	PATIENTAGE=$(mri_probedicom --i $TOPSET --t 10 1010)
	# The PatientAge tag (0010, 1010) is an optional tag and may
	# not be present in the DICOM data.  However, the StudyDate and
	# PatientBirthDay may still be present so attempt to compute the
	# age from these fields.
	if (( $? )) ; then
		PATIENTAGE=$(age_calc.py $PATIENTBDAY $PATIENTSCANDATE)
	fi
	
	
	printf "%40s\t%-20s\n" "Patient Name" 		    $PATIENTNAME
	printf "%40s\t%-20s\n" "Patient Age" 		    $PATIENTAGE
	printf "%40s\t%-20s\n" "Patient Sex" 		    $PATIENTSEX
	printf "%40s\t%-20s\n" "Patient Birthday"           $PATIENTBDAY
	printf "%40s\t%-20s\n" "Image Scan-Date"    	    $PATIENTSCANDATE
 
fi

if (( !b_FORCESET )) ; then	
	SETOLD=$(find . -maxdepth 1 -name "*-1.dcm" -print 2>/dev/null)
	#SETNEW=$(/bin/ls *0001.dcm 2>/dev/null)
	# DRG - The above test does not work when the series does not start with InstanceID 1.  To workaround this, the below
	#       code users mri_probedicom to find the SeriesInstanceID (0020,000e) and then gets the first unique filename
	#       from each series 
	SERIESNUMS=$(find . -maxdepth 1 -name "*.dcm" -print 2>/dev/null | tr -d './' | awk -F "-" '{print $1"-"$2}' | sort | uniq)
	for SERIES in $SERIESNUMS ; do
	    DCMFILE=$(find . -maxdepth 1 -name "$SERIES-*.dcm" -print | sort | grep -m 1 $SERIES | sed 's/^.\///')
	    SETNEW="$SETNEW $DCMFILE" 
	done
	
	declare -i lenOLD=0
	declare -i lenNEW=0
	lenOLD=$(echo ${#SETOLD})
	lenNEW=$(echo ${#SETNEW})
	
	if (( lenOLD )) ; then
	    SET=$SETOLD
	else
	    SET=$SETNEW
	fi
    SET=$(echo "$SETOLD" "$SETNEW")
else
    SET=$TOPSET ; 
fi

MANUFACTURER=$(mri_probedicom --i $TOPSET --t 8 70)
SCANNER=$(mri_probedicom --i $TOPSET --t 8 1090)
SOFTWAREVER=$(mri_probedicom --i $TOPSET --t 18 1020)
printf "%40s\t%-20s\n"	"Scanner Manufacturer"  "$MANUFACTURER"
printf "%40s\t%-20s\n"	"Scanner Model" 	"$SCANNER"
printf "%40s\t%-20s\n"	"Software Ver"  	"$SOFTWAREVER"
printf "\n"
for GROUP in $SET ; do	
	printf "%40s\t" "Scan $GROUP"
	SEQ=$(mri_probedicom --i $GROUP --t 0008 103e)
        if (( Gb_translateSpace )) ; then
          SEQ=$(echo "$SEQ" | tr ' ' $G_SPACECHAR )
        fi
	printf "%-20s\n" "$SEQ"
done
printf "\n"

