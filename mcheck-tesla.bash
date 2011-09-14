#!/bin/bash
#
# mcheck-ssh-tesla.bash
#
# Copyright 2010 Rudolph Pienaar
# Massachusetts General Hospital
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

let Gi_verbose=1

G_REPORTLOG=/tmp/${SELF}.reportLog.$G_PID
G_ADMINUSERS=rudolph@nmr.mgh.harvard.edu

declare -i targetList

declare -a TARGET_CHECK
declare -a TARGETACTION

G_SYNOPSIS="

 NAME

       mcheck-ssh-tesla.bash

 SYNOPSIS

       mcheck-ssh-tesla.bash

 DESCRIPTION
 
        'mcheck-ssh-tesla.bash' is used to check that certain script-defined
	conditions are true. If any of these conditions are false, it executes 
	a set of corrective actions.
	
	It should typically be called from a cron process, and this particular
	version of 'mcheck' is tailored to monitoring ssh tunnels between this
	host and remote hosts. 
	
 PRECONDITIONS

	 o Conditions to check are defined in the script code itself. These
    	   are specified in two arrays: the first describing (per condition)
    	   the command to check; the second describing (per condition) whatever
    	   corrective action to run should the check command be false.
 	o  Conditions to check should be described in such a manner that, should
    	   the condition be false, the check command returns zero (0).
 
 POSTCONDITIONS

	o The corrective action (per condition) is executed if the check condition
    	  returns false (0).

 HISTORY
 24 May 2009
  o OSX1927 integration.

 08 September 2011
  o Updates to new check and action strings.

"

###\\\
# Global variables
###///

# Actions
A_badRestart="attempting a corrective action"
A_fileCheck="checking for a required file dependency"

# Error messages
EM_badRestart="the corrective action failed. Perhaps a target process failed?"
EM_fileCheck="it seems that a dependency is missing."

# Error codes
EC_badRestart=10
EC_fileCheck=1

DREEV=dreev.tch.harvard.edu
GATE=gate.nmr.mgh.harvard.edu
verbosity_check

REQUIREDFILES="common.bash tunnel.bash pgrep"

for file in $REQUIREDFILES ; do
        # printf "%40s"   "Checking for $file"
        file_checkOnPath $file >/dev/null || fatal fileCheck
done

targetList=18

#
##
### FORWARD -- connect to points on dreev and from there to FNNDSC
##
#
# ssh on osx1927
TARGET_CHECK[0]="tunnel.bash --forward	--from 7777  --via ch137123@${DREEV} --to localhost:7777 --isRunning"
TARGETACTION[0]="tunnel.bash --forward	--from 7777  --via ch137123@${DREEV} --to localhost:7777"
# DICOM listnener on osx1927
TARGET_CHECK[1]="tunnel.bash --forward	--from 10402 --via ch137123@${DREEV} --to localhost:10402 --isRunning"
TARGETACTION[1]="tunnel.bash --forward	--from 10402 --via ch137123@${DREEV} --to localhost:10402"
# VNC on osx1927
TARGET_CHECK[2]="tunnel.bash --forward	--from 9900  --via ch137123@${DREEV} --to localhost:9900 --isRunning"
TARGETACTION[2]="tunnel.bash --forward	--from 9900  --via ch137123@${DREEV} --to localhost:9900"
# OsiriX on osx1927
TARGET_CHECK[3]="tunnel.bash --forward	--from 11114  --via ch137123@${DREEV} --to localhost:11112 --isRunning"
TARGETACTION[3]="tunnel.bash --forward	--from 11114  --via ch137123@${DREEV} --to localhost:11112"
# ipmi
TARGET_CHECK[4]="tunnel.bash --forward	--from 4212  --via ch137123@${DREEV} --to localhost:4212 --isRunning"
TARGETACTION[4]="tunnel.bash --forward	--from 4212  --via ch137123@${DREEV} --to localhost:4212"
# shaka
TARGET_CHECK[5]="tunnel.bash --forward	--from 4214  --via ch137123@${DREEV} --to localhost:4214 --isRunning"
TARGETACTION[5]="tunnel.bash --forward	--from 4214  --via ch137123@${DREEV} --to localhost:4214"
# durban web (CHRIS)
TARGET_CHECK[6]="tunnel.bash --forward	--from 8000  --via ch137123@${DREEV} --to localhost:8000 --isRunning"
TARGETACTION[6]="tunnel.bash --forward	--from 8000  --via ch137123@${DREEV} --to localhost:8000"
# rc-drno
TARGET_CHECK[7]="tunnel.bash --forward	--from 3204  --via ch137123@${DREEV} --to localhost:3204 --isRunning"
TARGETACTION[7]="tunnel.bash --forward	--from 3204  --via ch137123@${DREEV} --to localhost:3204"
# glacier
TARGET_CHECK[8]="tunnel.bash --forward	--from 4216  --via ch137123@${DREEV} --to localhost:4216 --isRunning"
TARGETACTION[8]="tunnel.bash --forward	--from 4216  --via ch137123@${DREEV} --to localhost:4216"
# pretoria
TARGET_CHECK[9]="tunnel.bash --forward	--from 4215  --via ch137123@${DREEV} --to localhost:4215 --isRunning"
TARGETACTION[9]="tunnel.bash --forward	--from 4215  --via ch137123@${DREEV} --to localhost:4215"
# natal svn
TARGET_CHECK[10]="tunnel.bash --forward	--from 5556  --via ch137123@${DREEV} --to localhost:5556 --isRunning"
TARGETACTION[10]="tunnel.bash --forward	--from 5556  --via ch137123@${DREEV} --to localhost:5556"

#
##
### REVERSE -- connect back from dreev to NMR hosts
##
#
# VNC from tesla out to FNNDSC 
TARGET_CHECK[11]="tunnel.bash --reverse --from ch137123@${DREEV}:4900 	--to ${GATE}:4900 --isRunning"
TARGETACTION[11]="tunnel.bash --reverse --from ch137123@${DREEV}:4900 	--to ${GATE}:4900"
TARGET_CHECK[12]="tunnel.bash --reverse --from rudolph@${GATE}:4900 	--to tesla:5900 --isRunning"
TARGETACTION[12]="tunnel.bash --reverse --from rudolph@${GATE}:4900 	--to tesla:5900"
# ssh from localhost out to FNNDSC
TARGET_CHECK[13]="tunnel.bash --reverse --from ch137123@${DREEV}:7776 	--to localhost:22 --isRunning"
TARGETACTION[13]="tunnel.bash --reverse --from ch137123@${DREEV}:7776 	--to localhost:22"
# ssh from ${GATE}:7775 out to FNNDSC (dreev:7775)
TARGET_CHECK[14]="tunnel.bash --reverse --from ch137123@${DREEV}:7775 	--to ${GATE}:7775 --isRunning"
TARGETACTION[14]="tunnel.bash --reverse --from ch137123@${DREEV}:7775 	--to ${GATE}:7775"
TARGET_CHECK[15]="tunnel.bash --reverse --from rudolph@${GATE}:7775 	--to heisenberg:22 --isRunning"
TARGETACTION[15]="tunnel.bash --reverse --from rudolph@${GATE}:7775 	--to heisenberg:22"
# DICOM listener from ${GATE}:10301 to FNNDSC
TARGET_CHECK[16]="tunnel.bash --reverse --from ch137123@${DREEV}:10301 	--to ${GATE}:10301 --isRunning"
TARGETACTION[16]="tunnel.bash --reverse --from ch137123@${DREEV}:10301 	--to ${GATE}:10301"
TARGET_CHECK[17]="tunnel.bash --reverse --from rudolph@${GATE}:10301 	--to kaos:10401 --isRunning"
TARGETACTION[17]="tunnel.bash --reverse --from rudolph@${GATE}:10301 	--to kaos:10401"

# Process command line options
while getopts h option ; do
        case "$option"
        in
                h)      echo "$G_SYNOPSIS"
		        shut_down 1 ;;
                \?)     echo "$G_SYNOPSIS"
                        shut_down 1 ;;
        esac
done

rm -f $G_REPORTLOG
b_logGenerate=0

for i in $(seq 0 $(expr $targetList - 1)) ; do
        result=$(eval ${TARGET_CHECK[$i]})
	if (( result == 0 )) ; then
	        #echo "${TARGETACTION[$i]}"
		lprintn "Restarting target action..."
	        eval "${TARGETACTION[$i]} "
		ret_check $? || fatal badRestart
		TARGETRESTARTED="$TARGETRESTARTED $i"
		b_logGenerate=1
	fi
done

for i in $TARGETRESTARTED ; do
        echo ""
        echo -e "Failed:\t\t${TARGET_CHECK[$i]}"        >> $G_REPORTLOG
        echo -e "Executed:\t${TARGETACTION[$i]}"        >> $G_REPORTLOG
        echo ""
done

if [ "$b_logGenerate" -eq "1" ] ; then
        message="
	
	$SELF
        
	Some of the events I am monitoring signalled a FAILED condition
	The events and the corrective action I implemented are:
	
$(cat $G_REPORTLOG)
	
        "
	messageFile=/tmp/$SELF.message.$PID
	echo "$message" > $messageFile
	mail -s "Failed conditions restarted" $G_ADMINUSERS < $messageFile
	rm -f $messageFile 2>/dev/null
fi

# This is commented out otherwise cron noise becomes unbearable
#shut_down 0
