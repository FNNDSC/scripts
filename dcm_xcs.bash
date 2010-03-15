#!/bin/bash
#
# dcm_xcs.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# GPL v2
#

# "include" the set of common script functions
source common.bash
declare -i Gb_forceStage=1

source /opt/arch/Darwin/packages/freesurfer/dev/SetUpFreeSurfer.sh
export DCMDICTPATH=/opt/local/lib/dicom.dic

let b_alreadyProcessed=0

MAILMSG="mail.msg"
LOGGENFILE="loggenfile.txt"
G_LOGDIR="/tmp"
G_DICOMROOT=/local_mount/space/osx1927/1/users/dicom/files
G_OUTPUTDICOMDIR="-x"
G_OUTPUTDICOMFILE="-x"
G_CALLINGENTITY="-x"
G_CALLEDENTITY="-x"

G_DCM_MKINDX="dcm_mkIndx.bash -a"
G_DCM_BDAGE="dcm_bdayAgeGet.bash"
G_MRI_INFO_BATCH="mri_info_batch.bash"

G_SYNOPSIS="

 NAME

	dcm_xcs.bash

 SYNOPSIS

	dcm_xcs.bash		-p <outputDicomDir>			\\		
				-f <outputDicomFile>  			\\
				-a <callingEntity>			\\
				-c <calledEntity>			\\
				[-d <dicomRootDir>]			\\
				[-l <logDir>]				\\
				[-v <verbosity>]			\\

 DESCRIPTION

	'dcm_xcs.bash' is a dispatching script, called from DCMTK's storescp
	whenever a remote process has pushed a DICOM series. The 'xcs' refers
	to the -xcs argument to 'storescp'.

	The script's main purpose is to serve in a central 'callback' type
	capacity. If called each time that a series has been transmitted from
	a PACS server, it allows an easy platform to dispatch to more complex
	callback capability.

 ARGUMENTS

	-p <outputDicomDir>
	Corresponds to storescp's #p argument, i.e the output directory
	containing the transmitted DICOM series. Note that this has been
	processed by 'dcm_rename.'

	-f <outputDicomFile>
	Corresponds to storescp's #f argument, i.e the filename of the
	current (i.e. last) transmitted DICOM file. Note that this has been
	processed by 'dcm_rename.'

	-a <callingEntity>
	Corresponds to storescp's #a argument, i.e the calling application
	entity title of the peer Storage SCU.

	-c <calledEntity>
	Corresponds to storescp's #c argument, i.e the called application
	entity title.

	-d <dicomRootDir> (Optional. Default: $G_DICOMROOT)
	Base directory of the received DICOM file tree.
	
	-l <logDir> (Optional. Default: $G_LOGDIR)
	Directory containing script log file.

	-v <level> (Optional)
	Verbosity level.

 OUTPUT

	Depends on the particular dispatching script that is called from 
	here.

 PRECONDITIONS

	o NMR-accessible environment

		- common.bash
		- cnde

 POSTCONDITIONS


 HISTORY

	14 March 2008
	o Initial design and coding.

	13 August 2009
	o Added block-check for email -- stops the repetitive emails if a 
	  message has already been sent.
"

G_LC=50
G_RC=20

# Actions
A_dependency="checking for a required file dependency"
A_dependencyStage="checking for a required dependency from an earlier stage"
A_noDicomFileArg="checking for the -f <outputDicomFile> argument"
A_noDicomFile="checking on the <outputDicomFile> access"
A_noDicomDirArg="checking for the -p <outputDicomFile> argument"
A_noDicomDir="checking if the <outputDicomDir> is accessible"
A_noCallingEntityArg="checking for the -a <callingEntity> argument"
A_noCalledEntityArg="checking for the -c <calledEntity> argument"

# Error messages
EM_dependency="it seems that a dependency is missing."
EM_dependencyStage="it seems that a stage dependency is missing."
EM_noDicomFileArg="it seems that the <outputDicomFile> argument was not specified."
EM_noDicomFile="I am having problems accessing the <outputDicomFile>. Does it exist?"
EM_noDicomDirArg="it seems that the <outputDicomDir> argument was not specified."
EM_noDicomDir="I am having problems accessing the <outputDicomDir>. Does it exist?"
EM_noCallingEntityArg="it seems that the <callingEntity> argument was not specified."
EM_noCalledEntityArg="it seems that the <calledEntity> argument was not specified."

# Error codes
EC_dependency=1
EC_dependencyStage=2
EC_noDicomFileArg=10
EC_noDicomFile=11
EC_noDicomDirArg=12
EC_noDicomDir=13
EC_noCallingEntityArg=14
EC_noCalledEntityArg=15

function expertOpts_parse
{
    # ARGS
    # $1                        process name
    #
    # DESC
    # Checks for <processName>.opt in $G_LOGDIR.
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

###\\\
# Process command options
###///


while getopts v:p:f:a:c:l:d: option ; do 
	case "$option"
	in
		v) Gi_verbose=$OPTARG 					;;
		p) G_OUTPUTDICOMDIR=$OPTARG				;;
		f) G_OUTPUTDICOMFILE=$OPTARG				;;
		a) G_CALLINGENTITY=$OPTARG				;;
		c) G_CALLEDENTITY=$OPTARG				;;
		d) G_DICOMROOT=$OPTARG					;;
		l) G_LOGDIR=$OPTARG					;;
		*) synopsis_show 
		    exit 0;;
	esac
done

verbosity_check
startDir=$(pwd)

cprint  "hostname"      $(hostname)

statusPrint 	"Checking -p <outputDicomDir>"
if [[ "$G_OUTPUTDICOMDIR" == "-x" ]] ; then fatal noDicomDirArg ; fi
ret_check $?
# statusPrint	"Checking on <outputDicomDir>"
# dirExist_check $G_OUTPUTDICOMDIR || fatal noDicomDir

statusPrint 	"Checking -f <outputDicomFile>"
if [[ "$G_OUTPUTDICOMDIR" == "-x" ]] ; then fatal noDicomFileArg ; fi
ret_check $?

statusPrint 	"Checking -a <callingEntity>"
if [[ "$G_CALLINGENTITY" == "-x" ]] ; then fatal noCallingEntityArg ; fi
ret_check $?

statusPrint 	"Checking -c <calledEntity>"
if [[ "$G_CALLEDENTITY" == "-x" ]] ; then fatal noCalledEntityArg ; fi
ret_check $?

# statusPrint     "Checking if <outputDirectory> is accessible"
# dirExist_check "$G_OUTPUTDICOMDIR" || fatal noDicomDir
# cd $G_OUTPUTDICOMDIR
# G_OUTPUTDICOMDIR=$(pwd)

# REQUIREDFILES="	common.bash mri_info"
# for file in $REQUIREDFILES ; do
#         statusPrint "Checking dependency: '$file'"
#         file_checkOnPath $file || fatal dependency
# done

STAMPLOG=${G_LOGDIR}/${G_SELF}.log
statusPrint     "$STAMPLOG" "\n"
stage_stamp "Init | ($startDir) $G_SELF $*" $STAMPLOG

DATE=$(date)
cd $G_DICOMROOT/$G_OUTPUTDICOMDIR 2>/dev/null

INDEX1=$(eval $G_DCM_MKINDX)
DCM_FILE=$(echo "$INDEX1" | grep -v Patient | head -n 1 | awk '{print $1}')
INDEX2=""
if (( ${#DCM_FILE} )) ; then
	INDEX2=$(eval $G_DCM_BDAGE $DCM_FILE 2>/dev/null)
fi

#TO="rudolph@nmr.mgh.harvard.edu,ellen@nmr.mgh.harvard.edu,neel@nmr.mgh.harvard.edu,hagmann@nmr.mgh.harvard.edu,orapalino@partners.org"
TO="rudolph.pienaar@childrens.harvard.edu,daniel.ginsburg@childrens.harvard.edu"
#TO="rudolph@nmr.mgh.harvard.edu"
SUBJ="New DICOM Series Received"

b_alreadyProcessed=$(echo "$INDEX1" | grep Track | wc -l)

if (( b_alreadyProcessed )) ; then
    TO="rudolph@nmr.mgh.harvard.edu"
    SUBJ="DICOM Series Processed"
fi

echo "
	$(date)
	A DICOM transmission has just been received on <$(hostname)>. Details:

	OutputDicomDir:		$G_OUTPUTDICOMDIR
	LastSeriesFile:		$G_OUTPUTDICOMFILE
	CallingEntity:		$G_CALLINGENTITY
	CalledEntity:		$G_CALLEDENTITY

	This transmission contains:

$INDEX1

$INDEX2
" > /tmp/$MAILMSG

if [[ ! -f ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/$MAILMSG ]] ; then
	cp /tmp/$MAILMSG ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/$MAILMSG
	/usr/bin/mail -s "$SUBJ" "$TO" <${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/$MAILMSG
else
	rm -f /tmp/storescp*
fi

echo "$INDEX1" > ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/toc.txt
if (( ${#INDEX2} )) ; then
  echo "$INDEX2" > ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/toc.txt
fi
chmod 2775 ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}

# Append the new entry to the dcm_MRID*.log if it has not yet been done
if [[ ! -f ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/$LOGGENFILE ]] ; then
	
	# First get the MRID to add entry to dcm_MRID.log
	MRID=$(grep ID  ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/toc.txt | awk '{print $3}')
	printf "%-55s\t%25s\n" "$G_OUTPUTDICOMDIR" "$MRID" >> ${G_DICOMROOT}/dcm_MRID.log
	
	# Next add it to the dcm_MRID.xml
	dcm_MRIDgetXML.bash -d ${G_DICOMROOT} ${G_OUTPUTDICOMDIR} >> ${G_DICOMROOT}/dcm_MRID.xml
	
	# Now get the Age to add to dcm_MRID_age.log
	AGE=$(dcm_bdayAgeGet.bash | grep Age | awk '{print $5}' | tr '\n' ' ')
	printf "%55s\t%50s\t%10s\n" "$G_OUTPUTDICOMDIR" "$MRID" "$AGE" >> ${G_DICOMROOT}/dcm_MRID_age.log
	
	# Finally regenerate dcm_MRID_ageDays.log
	cat ${G_DICOMROOT}/dcm_MRID_age.log | awk -f /local_mount/space/osx1927/1/users/dicom/repo/trunk/scripts/dayAge_calc.awk  | sort -n -k 3 > ${G_DICOMROOT}/dcm_MRID_ageDays.log

	# Also, run mri_info
	STAGE1PROC=mri_info_batch.bash
	statusPrint "$(date) | Processing STAGE - mri_info_batch.bash | START" "\n"
	STAGE=1-$STAGE1PROC
	STAGECMD="$STAGE1PROC	\
              -D ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}"
	stage_run "$STAGE" "$STAGECMD" 					\
		  "${G_LOGDIR}/${STAGE1PROC}.std"		\
      "${G_LOGDIR}/${STAGE1PROC}.err"
	statusPrint "$(date) | Processing STAGE -  mri_info_batch.bash | END" "\n"
	
	echo "Appened to dcm_MRID*.log: $MRID $AGE $G_OUTPUTDICOMDIR" > ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/$LOGGENFILE
fi

STAGE="Normal termination"
stage_stamp "$STAGE" $STAMPLOG

statusPrint "Cleaning up"
cd $startDir
shut_down 0

