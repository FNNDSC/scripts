#!/bin/bash

# "include" the set of common script functions
source common.bash

declare -i      Gi_verbose=0
declare -i      Gi_showAll=0

MRIANNOT2LABEL="mri_annotation2label"

SURFACE=white

G_SYNOPSIS="

 NAME

        $G_SELF

 SYNOPSIS

        $G_SELF -a <annotationBase> [-s <surface>] 	\
		[-M <mri_annotation2label>] 		\
		<subj1> ... <subjN>

 DESCRIPTION

        '$G_SELF' simply unpacks the labels inside an annotation file 
	across all the passed subjects.

 ARGUMENTS

	-a <annotationStem>
	The 'stem' of the annotation file. Fully qualified name is
	constructed from <hemi>.<annotationStem>.annot

	-s <surface>
	The surface on which to project the x,y,z position coordinates
	of the label vertices. Defaults to <$SURFACE>.

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

	15 June 2011
	o Initial adaptation from lobes_annot.sh
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///

# Actions
A_noSubjectsDirVar="checking environment"
A_noAnnotFile="checking on the annotation file"

# Error messages
EM_noSubjectsDirVar="it seems that the SUBJECTS_DIR environment var is not set."
EM_noAnnotFile="no annotation file was found."

# Error codes
EC_noSubjectsDir=10
EC_noAnnotFile=11

while getopts v:M:a:s: option ; do
        case "$option"
        in
		a) ANNOTSTEM=$OPTARG		;;
		s) SURFACE=$OPTARG		;;
		M) MRIANNOT2LABEL=$OPTARG	;;
                v) let Gi_verbose=$OPTARG 	;;
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

printf "%40s"	"Checking on mri_annot2label"
file_checkOnPath $MRIANNOT2LABEL


shift $(($OPTIND - 1))
SUBJLIST=$*
b_SUBJLIST=$(echo $SUBJLIST | wc -w)

if (( b_SUBJLIST )) ; then
    for SUBJ in $SUBJLIST ; do
	for HEMI in rh lh ; do
            b_annotExist=1
            ANNOTBASE=${SUBJ}/label/${HEMI}.${ANNOTSTEM}.annot
            statusPrint "Checking on $ANNOTBASE"
            fileExist_check $ANNOTBASE || b_annotExist=0
            if (( b_annotExist )) ; then
		statusPrint "Extracting labels"
		CMD="$MRIANNOT2LABEL --subject ${SUBJ} --hemi $HEMI			
				     --annotation $ANNOTSTEM
				     --surface $SURFACE
				     --outdir ${SUBJ}/label			
					>/dev/null 2>/dev/null"
		eval $CMD
		ret_check $?
            fi
	done
    done
fi
