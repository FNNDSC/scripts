#!/bin/bash

# "include" the set of common script functions
source common.bash

declare -i      Gi_verbose=0
declare -i      Gi_showAll=0

G_SYNOPSIS="

 NAME

        $G_SELF

 SYNOPSIS

        $G_SELF <subj1> ... <subjN>

 DESCRIPTION

        '$G_SELF' reprocesses a FreeSurfer multi-entry annotation file
	and creates a lobar annotation. It is a simple wrapper around
	'mri_annotations2label'.

 ARGUMENTS

	<subj1> ... <subjN>
	List of subject directories to process.

 PRECONDITIONS

        o nse/nde

	o Each <subjI> must be a properly processed FreeSurfer run.

 POSTCONDITIONS

        o A annotation file with lobar regions is created.

 HISTORY

	24 May 2010
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


printf "%40s"   "Checking for SUBJECTS_DIR env variable"
b_subjectsDir=${SUBJECTS_DIR+1}
if (( !b_subjectsDir )) ; then
        fatal noSubjectsDirVar
fi
ret_check $?   

shift $(($OPTIND - 1))
SUBJLIST=$*
b_SUBJLIST=$(echo $SUBJLIST | wc -w)

if (( b_SUBJLIST )) ; then
    for SUBJ in $SUBJLIST ; do
	for HEMI in rh lh ; do
            b_annotExist=1
            ANNOTBASE=${SUBJ}/label/${HEMI}.aparc.annot
            ANNOTLOBE=${SUBJ}/label/${HEMI}.lobes.annot
            statusPrint "Checking on $ANNOTBASE"
            fileExist_check $ANNOTBASE || b_annotExist=0
            if (( b_annotExist )) ; then
                statusPrint "Creating $ANNOTLOBE"
                mri_annotation2label --subject $SUBJ --hemi $HEMI       \
                                     --lobes ${HEMI}.lobes.annot 2>/dev/null >/dev/null
                ret_check $?
            fi
	done
    done
fi
