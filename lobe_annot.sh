#!/bin/bash

# "include" the set of common script functions
source common.bash

declare -i      Gi_verbose=0
declare -i      Gi_showAll=0
declare -i	Gi_strict=0

MRIANNOT2LABEL="mri_annotation2label"

G_SYNOPSIS="

 NAME

        $G_SELF

 SYNOPSIS

        $G_SELF [-S] [-M <mri_annotation2label>] <subj1> ... <subjN>

 DESCRIPTION

        '$G_SELF' reprocesses a FreeSurfer multi-entry annotation file
	and creates a lobar annotation. It is a simple wrapper around
	'mri_annotations2label'.

 ARGUMENTS

 	-S (optional)
	If specified, perform a more \"strict\" lobar parcellation.

	-M <mri_annotation2label> (optional)
	If specified, use the passed executable to perform the annotation to
	label. This is only useful for development purposes and if several
	slightly different versions of <mri_annotation2label> exist.

	<subj1> ... <subjN>
	List of subject directories to process.

 PRECONDITIONS

        o nse/nde

	o Each <subjI> must be a properly processed FreeSurfer run.

 POSTCONDITIONS

        o A annotation file with lobar regions is created.
	o Each annotation file is also processed into its constituent
	  label files.

 HISTORY

	24 May 2010
	o Initial design and coding.

	04 June 2010
	o Label file extraction added.

	3 September 2010
	o Added '-S' flag for more strict lobar division.
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///

# Actions
A_noSubjectsDirVar="checking environment"

# Error messages
EM_noSubjectsDirVar="it seems that the SUBJECTS_DIR environment var is not set."

# Error codes
EC_noSubjectsDirVar=10

while getopts d:v:SM: option ; do
        case "$option"
        in
                d) DICOMDIR=$OPTARG 		;;
		M) MRIANNOT2LABEL=$OPTARG	;;
                S) let Gi_strict=1 		;;
                v) let Gi_verbose=$OPTARG 	;;
                \?) synopsis_show
                    exit 0;;
        esac
done

verbosity_check
topDir=$(pwd)

G_LC=80
G_RC=10

statusPrint "Checking for SUBJECTS_DIR env variable"
b_subjectsDir=${SUBJECTS_DIR+1}
if (( !b_subjectsDir )) ; then
        fatal noSubjectsDirVar
fi
ret_check $?   

statusPrint	"Checking on mri_annot2label"
file_checkOnPath $MRIANNOT2LABEL

shift $(($OPTIND - 1))
SUBJLIST=$*
b_SUBJLIST=$(echo $SUBJLIST | wc -w)

if (( b_SUBJLIST )) ; then
    for SUBJ in $SUBJLIST ; do
	for HEMI in rh lh ; do
            b_annotExist=1
            ANNOTBASE=${SUBJ}/label/${HEMI}.aparc.annot
            ANNOTLOBE=${SUBJ}/label/${HEMI}.lobesStrict.annot
            statusPrint "Checking on $ANNOTBASE"
            fileExist_check $ANNOTBASE || b_annotExist=0
	    LOBEARG="--lobes ${HEMI}.lobes.annot"
	    ANNOTARG="--annotation lobes"
	    if (( Gi_strict )) ; then
            	ANNOTLOBE=${SUBJ}/label/${HEMI}.lobesStrict.annot
		LOBEARG="--lobesStrict ${HEMI}.lobesStrict.annot"
		ANNOTARG="--annotation lobesStrict"
	    fi
            if (( b_annotExist )) ; then
                statusPrint "Creating $ANNOTLOBE"
                CMD="$MRIANNOT2LABEL	     --subject $SUBJ --hemi $HEMI       \
                                     $LOBEARG 2>/dev/null >/dev/null"
		eval $CMD
                ret_check $?
		statusPrint "Extracting labels"
		CMD="$MRIANNOT2LABEL --subject ${SUBJ} --hemi $HEMI			
				     $ANNOTARG				 	
				     --outdir ${SUBJ}/label			
					>/dev/null 2>/dev/null"
		eval $CMD
		ret_check $?
            fi
	done
    done
fi
