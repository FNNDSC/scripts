#!/bin/bash
# "include" the set of common script functions
source common.bash
source getoptx.bash

declare -i Gi_verbose=0

G_SYNOPSIS="

NAME

	ge2nii.sh
	
SYNOPSIS

       ge2nii.sh                [-v <verbosity>]                        \\
				DIR1 DIR2 ... DIRn

DESCRIPTION

	'ge2nii.sh' converts old-style GE raw scanner data to NIfTI.
	
	The script uses AFNI and FreeSurfer tools. 
	
 PRECONDITIONS
 
 	o The input DIRs should all contain GE data named:
	
		I.001 I.002 I.003 ... I.00n
		
	o The AFNI tool 'Ifile' must be on the path.
	o The FreeSurfer tool 'mri_convert' must be on the path.

"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///

# Actions
A_fileCheck="checking for a required file dependency"
A_stageRun="running a stage in the processing pipeline"
A_noSubjectsDirVar="checking environment"
A_noSubjectsDir="checking environment"
A_noSubjectBase="checking base subject dir"
A_noDicomDir="checking on input DICOM directory"
A_noDicomDirArg="checking on -d <dicomInputDir> argument"
A_badMigrateDir="checking on --migrate-analysis <migrateDir>"

# Error messages
EM_fileCheck="it seems that a dependency is missing."
EM_stageRun="I encountered an error processing this stage."
EM_noSubjectsDirVar="it seems that the SUBJECTS_DIR environment var is not set."
EM_noSubjectsDir="it seems that the SUBJECTS_DIR refers to an invalid directory."
EM_noSubjectBase="I couldn't find a subject base directory."
EM_noDicomDir="I couldn't access the input DICOM dir. Does it exist?"
EM_noDicomDirArg="it seems as though you didn't specify a -D <dicomInputDir>."
EM_badMigrateDir="I couldn't access <migrateDir>"

# Error codes
EC_fileCheck=1
EC_stageRun=30
EC_noSubjectsDirVar=100
EC_noSubjectsDir=101
EC_noSubjectBase=102
EC_noDicomDir=50
EC_noDicomDirArg=51
EC_badMigrateDir=83

# Defaults
D_whatever=

###\\\
# Process command options
###///

while getoptex "v: migrate-analysis:" "$@" ; do 
        case "$OPTOPT"
        in
                v)      Gi_verbose=$OPTARG                      ;;
                migrate-analysis)
                        G_MIGRATEANALYSISDIR=$OPTARG            ;;
                \?) synopsis_show 
                    exit 0;;
        esac
done

verbosity_check
topDir=$(pwd)

REQUIREDFILES="common.bash Ifile mri_convert"
for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file..."
        file_checkOnPath $file || fatal fileCheck
done

shift $(($OPTIND - 1))
CLISUBJECTS=$*
b_SUBJECTLIST=$(echo $CLISUBJECTS | wc -w)
if (( b_SUBJECTLIST )) ; then
        SUBJECTS="$CLISUBJECTS"
fi

SUBJECTS=$(echo $SUBJECTS | tr ' ' '\n' )

for D in $SUBJECTS ; do
	IFILES=$(/bin/ls -1 $D/I.* | wc -l)
	cprint "$D" "[ $IFILES ]"
	if (( ! IFILES )) ; then continue ; fi
	rm -fr afni* GERT_Reco MAP* Panga*
	if (( IFILES > 1 )) ; then
		Ifile $D/I.*
		./GERT_Reco
		mri_convert afni/OutBrick_r1+orig.BRIK $D.nii
	fi
done
rm -fr afni* GERT_Reco MAP* Panga*

shut_down 0
