#!/bin/bash
G_SYNOPSIS="

NAME

	bbox_clean.sh

SYNOPSIS

	bbox_clean.sh [-v] <file1.[e]ps> ... <fileN.[e]ps> 

DESCRIPTION

	'bbox_clean.sh' cleans OpenOffice eps exports by reducing
	the PostScript BoundingBox line to a box containing only
	the image and no superfluous white space.

	This is achieved in something of a round-about way. The original
	input file is run through ps2epsi. The resultant file has the
	correct BoundingBox parameter. This is extracted and copied
	back into the original file.

TODO

PRECONDITIONS
o  It is assumed that the OpenOffice.org generated eps files have 
   a bounding box of 0 0 575 755!!

HISTORY

14 April 2004
o Initial design and coding.

" 

###\\\
# Global variables
###///
SELF=`basename $0`

# Actions
A_comargs="checking command line arguments"

# Error messages
EM_noPSFiles="no Postscript files specified!"

# Error codes
EC_noPSFiles=1

# Defaults
D_VERBOSE="NO"

###\\\
# Function definitions
###///

function shut_down
# $1: Exit code
{
	if [ $D_VERBOSE = "YES" ] ; then
		echo -e "\n$SELF:\n\tShutting down with code $1.\n"
        	fi

	exit $1
}

function synopsis_show
{
	echo "USAGE:"
	echo -e "\t$SELF [-v] [-h] <file1.[e]ps> ... <fileN.[e]ps>"
	echo -e ""
	shut_down 1
}
 
function help_show
{
	echo "$G_SYNOPSIS"
	shut_down 1
}
                  
function error
# $1: Action
# $2: Error string
# $3: Exit code
{
	echo -e "\n$SELF:\n\tSorry, but there seems to be an error." >&2
	echo -e "\tWhile $1,"                                      >&2
	echo -e "\t$2\n"                                           >&2
	synopsis_show
	shut_down $3
}                

function warn
# $1: Action
# $2: Warn string
# $3: Default value
{
	echo -e "\n$SELF: WARNING\n" 			>&2
	echo -e "\tWhile $1,"                           >&2
	echo -e "\t$2\n"                                >&2
	echo -e "\tSetting default to '$3'\n"		>&2
}

###\\\
# Process command options
###///

while getopts "vh" option ; do
        case "$option"
        in
                v  ) D_VERBOSE="YES" ;;
		h  ) help_show;;
                \? ) synopsis_show ;;
        esac
done
shift $(($OPTIND - 1))

if [ "$#" = 0 ] ; then
	error "$A_comargs" "$EM_noPSFiles" "$EC_noPSFiles"
fi

for FILEEXT in $*
do
	if [ $FILEEXT != "-v" ]; then
		FILE=`basename $FILEEXT .eps`
		if [ $D_VERBOSE = "YES" ] ; then
			echo -n "$FILEEXT --> ${FILE}.epsi"
		fi
		ps2epsi $FILEEXT ${FILE}.epsi
		bbox=$(cat ${FILE}.epsi | grep Bounding)
		cat $FILEEXT | sed "s/%%BoundingBox: 0 0 575 755/$bbox/" > ${FILE}.1.eps
		if [ $D_VERBOSE = "YES" ] ; then
			echo " --> ${FILE}.1.eps --> $FILEEXT"
		fi
		mv ${FILE}.1.eps $FILEEXT
		rm ${FILE}.epsi
	fi
done

shut_down 0








