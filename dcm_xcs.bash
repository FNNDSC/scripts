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
source chris_env.bash
declare -i Gb_forceStage=1

let b_alreadyProcessed=0

MAILMSG="mail.msg"
LOGGENFILE="loggenfile.txt"
G_MAILALIAS="aliases.mail"
G_USRETC=$CHRIS_ETC
G_LOGDIR="/tmp"
G_MAILTO=$CHRIS_ADMINUSERS
G_DICOMROOT=$CHRIS_SESSIONPATH
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
				[-m <mailReportsTo>]			\\

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

	-m <mailReportsTo> (Optional. Default: $G_MAILTO)
	Specify e-mail address(es) to send new DICOM arrival notification to.

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

	2 April 2010
	o Added MAILALIAS processing -- allows AETitle matchining to user
	  email.
"

G_LC=40
G_RC=40

# Actions
A_dependency="checking for a required file dependency"
A_dependencyStage="checking for a required dependency from an earlier stage"
A_noDicomFileArg="checking for the -f <outputDicomFile> argument"
A_noDicomFile="checking on the <outputDicomFile> access"
A_noDicomDirArg="checking for the -p <outputDicomFile> argument"
A_noDicomDir="checking if the <outputDicomDir> is accessible"
A_noCallingEntityArg="checking for the -a <callingEntity> argument"
A_noCalledEntityArg="checking for the -c <calledEntity> argument"
A_lockFileGet="attempting to get lockfile"

# Error messages
EM_dependency="it seems that a dependency is missing."
EM_dependencyStage="it seems that a stage dependency is missing."
EM_noDicomFileArg="it seems that the <outputDicomFile> argument was not specified."
EM_noDicomFile="I am having problems accessing the <outputDicomFile>. Does it exist?"
EM_noDicomDirArg="it seems that the <outputDicomDir> argument was not specified."
EM_noDicomDir="I am having problems accessing the <outputDicomDir>. Does it exist?"
EM_noCallingEntityArg="it seems that the <callingEntity> argument was not specified."
EM_noCalledEntityArg="it seems that the <calledEntity> argument was not specified."
EM_lockFileGet="I am unable to get lockfile"


# Error codes
EC_dependency=1
EC_dependencyStage=2
EC_noDicomFileArg=10
EC_noDicomFile=11
EC_noDicomDirArg=12
EC_noDicomDir=13
EC_noCallingEntityArg=14
EC_noCalledEntityArg=15
EC_lockFileGet=16

###\\\
# Process command options
###///


while getopts v:p:f:a:c:l:d:m: option ; do 
	case "$option"
	in
		v) Gi_verbose=$OPTARG 					;;
		p) G_OUTPUTDICOMDIR=$OPTARG				;;
		f) G_OUTPUTDICOMFILE=$OPTARG				;;
		a) G_CALLINGENTITY=$OPTARG				;;
		c) G_CALLEDENTITY=$OPTARG				;;
		d) G_DICOMROOT=$OPTARG					;;
		l) G_LOGDIR=$OPTARG					;;	    
		m) G_MAILTO=$OPTARG					;;
		*) synopsis_show 
		    exit 0;;
	esac
done

verbosity_check
startDir=$(pwd)

cprint  "host"      $(hostname)

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

# Find the script directory so that we can find the path to 
# dayAge_calc.awk
SCRIPT_DIR=$(which common.bash)
G_DAYAGECALC_AWK="$(dirname $SCRIPT_DIR)/dayAge_calc.awk"

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

# Touch a file that indicates the arrival of a new scan, this is
# used later on to figure out if we need to regenerate the dcm_MRID.xml
# database
touch ${G_DICOMROOT}/newscan.txt

# LOCK (GET): {G_DICOMROOT}/${G_OUTPUTDICOMDIR}/toc.txt.lock
wait_for_lockfile ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/toc.txt.lock
if [ $? -ne 0 ] ; then fatal lockFileGet ; fi

	INDEX1=$(eval $G_DCM_MKINDX)
	DCM_FILE=$(echo "$INDEX1" | grep -v Patient | head -n 1 | awk '{print $1}')
	INDEX2=""
	if (( ${#DCM_FILE} )) ; then
		INDEX2=$(eval $G_DCM_BDAGE $DCM_FILE 2>/dev/null)
	fi

	TO=$G_MAILTO
	SUBJ="${CHRIS_NAME}: New DICOM Series Received"
	
	b_alreadyProcessed=$(echo "$INDEX1" | grep Track | wc -l)
	
	if (( b_alreadyProcessed )) ; then
	    TO=$G_MAILTO
	    SUBJ="${CHRIS_NAME}: DICOM Series Processed"
	fi

	# Create a permissions.txt file with the user being the 
        # application-entity title.
	# If the file already exists, then add this user only if 
        # is not already in the file. 
	# Multiple users can be spec'd in the AETitle with commas.
	PERMISSION_USER=$(echo $G_CALLEDENTITY | tr '[A-Z]' '[a-z]')
	for USER in $(echo $PERMISSION_USER | tr ',' ' '); do
	    if [[ ! -f ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/permissions.txt ]] ; then
	        echo "User $USER" > ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/permissions.txt
	        chmod 644 ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/permissions.txt
	    else
	        # Check to see if user is already in permissions.txt file
	        b_found=$(cat ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/permissions.txt|\
		   grep "User" | awk '{print $2}' 			|\
		   grep $USER | wc -w)
	        if ((!b_found)) ; then
	                echo "User $USER" >> \
			${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/permissions.txt                       
	        fi
	    fi
	done

	# Parse the mail alias file for PERMISSION_USER, and if found, append to 
	# the 'TO' string. Multiple users in the PERMISSION_USER are separated 
	# by commas
	MAILALIAS=${G_USRETC}/${G_MAILALIAS}
	USERLIST=""
	if [[ -f $MAILALIAS ]] ; then
	    for USER in $(echo $PERMISSION_USER | tr ',' ' '); do
	        RETURNMAIL=$(grep -i ^$USER $MAILALIAS | awk -F \: '{print $2}')
	        USERNAME=$(grep -i ^$USER $MAILALIAS | awk -F \: '{print $3}' | awk '{print $1}')
	        if (( ${#RETURNMAIL} )) ; then
		    TO="$TO,$RETURNMAIL"
		    if ${#USERLIST}; then 
		        USERLIST="$USERLIST, $USERNAME"
		    else
		        USERLIST="$USERNAME"
	            fi
	        fi
	    done
	fi


	echo "
		$(date)
		Dear $USERLIST
		A DICOM transmission has just been received on <$(hostname)>. Details:
	
		OutputDicomDir:		$G_OUTPUTDICOMDIR
		LastSeriesFile:		$G_OUTPUTDICOMFILE
		CallingEntity:		$G_CALLINGENTITY
		CalledEntity:		$G_CALLEDENTITY
	
		This transmission contains:
	
	$INDEX1
	
	$INDEX2

                -=+< ${CHRIS_NAME} >+=-

	" > /tmp/$MAILMSG


	# Check to see if the file has changed and only send it if so (or
	# if it does not exist yet).  Only look at the "Scan"'s because the
	# date and LastSeriesFile will always be different.
	grep "Scan" /tmp/$MAILMSG > /tmp/$MAILMSG.cmp1
	grep "Scan" ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/$MAILMSG > /tmp/$MAILMSG.cmp2
	cmp -s /tmp/$MAILMSG.cmp1 /tmp/$MAILMSG.cmp2 > /dev/null
	if [ $? -ne 0 ] ; then
		cp /tmp/$MAILMSG ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/$MAILMSG
		$CHRIS_MAIL -s "$SUBJ" "$TO" <${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/$MAILMSG
	else	
		rm -f /tmp/storescp*
	fi

	echo "$INDEX1" > ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/toc.txt
	if (( ${#INDEX2} )) ; then
	  echo "$INDEX2" > ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/toc.txt
	fi
	chmod 2775 ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}

# LOCK (RELEASE): {G_DICOMROOT}/${G_OUTPUTDICOMDIR}/toc.txt.lock
release_lockfile ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/toc.txt.lock


# If we are not already building the dcm_MRID.xml database, rebuild it.
if [[ ! -f ${G_DICOMROOT}/dcm_MRID.xml.build ]] ; then
        echo "
                $(date)
		Dear $USERLIST
                
                The CHRIS database is being updated with scans that were 
                recently received from a DICOM push that were associated with
                your user ID. Please be patient while this operation is 
                performed; it can take up to 10 or more minutes.
                
		You will receive an email once update is complete. If you
		have not received a completion email within an hour from 
		this email, please contact the CHRIS admin user for help:
		
		        $CHRIS_ADMINUSERS

                Scans in the following directory are being added:		
		
		$G_OUTPUTDICOMDIR

                -=+< ${CHRIS_NAME} >+=-

        " > /tmp/$MAILMSG
        
        $CHRIS_MAIL -s "${CHRIS_NAME}: Database update started" "$TO" </tmp/$MAILMSG
        
	# As long as new scans have arrived, keep updating the dcm_MRID.xml
	# database.  This will keep running until all new scans have been
	# processed.
	while [ -f ${G_DICOMROOT}/newscan.txt ]
	do
		# Delete the touch file.  If new scans arrive while this
		# processing was being done, the file will get recreated and
		# this loop will continue.  This make sure that any new
		# scans get added to the database
		rm -rf ${G_DICOMROOT}/newscan.txt

		# Regenerate the dcm_MRID.xml database
		dcm_MRIDgetXML.bash -d ${G_DICOMROOT} -a > ${G_DICOMROOT}/dcm_MRID.xml.build
		cp ${G_DICOMROOT}/dcm_MRID.xml.build ${G_DICOMROOT}/dcm_MRID.xml
	done
	rm -rf ${G_DICOMROOT}/dcm_MRID.xml.build	
fi
	
# Also, run mri_info
STAGE1PROC=mri_info_batch.bash
statusPrint "$(date) | Processing STAGE - mri_info_batch.bash | START" "\n"
STAGE=1-$STAGE1PROC
STAGECMD="$STAGE1PROC -v 10 -D ${G_DICOMROOT}/${G_OUTPUTDICOMDIR} -s"
stage_run "$STAGE" "$STAGECMD"                          \
          "${G_LOGDIR}/${STAGE1PROC}.std"               \
          "${G_LOGDIR}/${STAGE1PROC}.err"
statusPrint "$(date) | Processing STAGE -  mri_info_batch.bash | END" "\n"

# Append the new entry to the dcm_MRID*.log if it has not yet been done
if [[ ! -f ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/$LOGGENFILE ]] ; then
	
	# LOCK (GET): ${G_DICOMROOT}/dcm_MRID.xml.lock
	wait_for_lockfile ${G_DICOMROOT}/dcm_MRID.log.lock
	if [ $? -ne 0 ] ; then fatal lockFileGet ; fi
	
		# First get the MRID to add entry to dcm_MRID.log
		MRID=$(grep ID  ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/toc.txt | awk '{print $3}')
		printf "%-55s\t%25s\n" "$G_OUTPUTDICOMDIR" "$MRID" >> ${G_DICOMROOT}/dcm_MRID.log
		
		# Now get the Age to add to dcm_MRID_age.log
		AGE=$(dcm_bdayAgeGet.bash | grep Age | awk '{print $5}' | tr '\n' ' ')
		printf "%55s\t%50s\t%10s\n" "$G_OUTPUTDICOMDIR" "$MRID" "$AGE" >> ${G_DICOMROOT}/dcm_MRID_age.log
		
		# Finally regenerate dcm_MRID_ageDays.log
		cat ${G_DICOMROOT}/dcm_MRID_age.log | awk -f ${G_DAYAGECALC_AWK} | sort -n -k 3 > ${G_DICOMROOT}/dcm_MRID_ageDays.log	
	
		echo "Appened to dcm_MRID*.log: $MRID $AGE $G_OUTPUTDICOMDIR" > ${G_DICOMROOT}/${G_OUTPUTDICOMDIR}/$LOGGENFILE
	
	# LOCK (RELEASE): {G_DICOMROOT}/${G_OUTPUTDICOMDIR}/toc.txt.lock
	release_lockfile ${G_DICOMROOT}/dcm_MRID.log.lock
fi

echo "
                $(date)
		Dear $USERLIST

                All scans have been successfully added to the database and
                should now be available from the CHRIS web interface:
                
                        $CHRIS_WEBSITE

                Scans in the following directory were successfully added:		
		
		$G_OUTPUTDICOMDIR

                -=+< ${CHRIS_NAME} >+=-

" > /tmp/$MAILMSG
        
$CHRIS_MAIL -s "${CHRIS_NAME}: Database update successful" "$TO" </tmp/$MAILMSG
rm /tmp/$MAILMSG

STAGE="Normal termination"
stage_stamp "$STAGE" $STAMPLOG

statusPrint "Cleaning up"
cd $startDir
shut_down 0

