#!/bin/bash

# "include" the set of common script functions
source common.bash

declare -i      Gi_verbose=0
declare -i      Gi_showAll=0
declare -i	Gi_strict=0

G_OUTPUT=out.pdf

G_SYNOPSIS="

 NAME

        $G_SELF

 SYNOPSIS

        $G_SELF [-o <output>] <PDF_1> <PDF_2> ... <PDF_N> 

 DESCRIPTION

        '$G_SELF' combines several PDF files into a single one.

 ARGUMENTS

 	-o <output> (optional)
	If specified, use <output> for the output file name, otherwise
	use '$G_OUTPUT'.

	<PDF_1> <PDF_2> ... <PDF_N>
	List of pdf files to combine.

 PRECONDITIONS

	o gs and pdftk

 POSTCONDITIONS

	o An output PDF file is created that is the concatenation of the
	  passed input PDFs.

 HISTORY

	31 May 2011
	o Initial design and coding.
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///

# Actions
A_noSubjectsDirVar="checking environment"

# Error messages
EM_noSubjectsDirVar="it seems that the SUBJECTS_DIR environment var is not set."

# Error codes
EC_noSubjectsDir=10

while getopts o:v:SM: option ; do
        case "$option"
        in
                o) G_OUTPUT=$OPTARG 		;;
                v) let Gi_verbose=$OPTARG 	;;
                \?) synopsis_show
                    exit 0;;
        esac
done

verbosity_check
topDir=$(pwd)

shift $(($OPTIND - 1))
PDFLIST=$*
b_PDFLIST=$(echo $PDFLIST | wc -w)

if (( b_PDFLIST )) ; then
	gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=$G_OUTPUT -dBATCH $PDFLIST
fi
