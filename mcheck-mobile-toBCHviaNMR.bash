#!/bin/bash
#
# mcheck-ssh-osx1927.bash
#
# Copyright 2010 Rudolph Pienaar
# Children's Hospital Boston
#
# SPDX-License-Identifier: MIT
#

# "include" the set of common script functions
source common.bash

G_REPORTLOG=/tmp/${G_SELF}.reportLog.$G_PID
G_ADMINUSERS=rudolph.pienaar@childrens.harvard.edu

declare -i targetList

declare -a TARGET_CHECK
declare -a TARGETACTION

G_SYNOPSIS="

 NAME

       mcheck-mobile.bash

 SYNOPSIS

       mcheck-mobile.bash

 DESCRIPTION
 
        'mcheck-mobile.bash' is used to check that certain script-defined
	conditions are true. If any of these conditions are false, it executes 
	a set of corrective actions.

	It should typically be called from a cron process, and this particular
	version of 'mcheck' is tailored to monitoring ssh tunnels between this
	host and remote hosts.

	This particular script sets up the web of ssh-tunnel connections allowing
	connections to FNNDSC hosts.
		
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

 07 September 2011
  o Re-routed all tunnels through 'dreev' to prevent accidental flooding of tunnel
    nexus hosts.
  o Added 'maxTunnel' check -- script will not open new tunnels if 'maxTunnel' is
    exceeded (this is an added check against flooding).   

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

DOOR=door.nmr.mgh.harvard.edu
OSX1927=osx1927.tch.harvard.edu
OSX2147=osx2147.tch.harvard.edu
OSX1476=osx1476.tch.harvard.edu
DURBAN=durban.tch.harvard.edu
NATAL=natal.tch.harvard.edu
IPMI=ipmi.tch.harvard.edu
SHAKA=shaka.tch.harvard.edu
GLACIER=glacier.tch.harvard.edu
RCDRNO=rc-drno.tch.harvard.edu
PRETORIA=pretoria.tch.harvard.edu
GATE=gate.nmr.mgh.harvard.edu
H1=98.118.51.216

verbosity_check
REQUIREDFILES="common.bash tunnel.bash pgrep"

for file in $REQUIREDFILES ; do
#        printf "%40s"   "Checking for $file"
        file_checkOnPath $file >/dev/null || fatal fileCheck
done

targetList=22

#
##
### TUNNELS -- to 'FNNDSC' and 'NMR' destinations
##
#
 TARGET_CHECK[0]="tunnel.bash --forward	--from 7777  --via rudolph@${DOOR} --to localhost:7777 --isRunning"
 TARGETACTION[0]="tunnel.bash --forward	--from 7777  --via rudolph@${DOOR} --to localhost:7777"
 TARGET_CHECK[1]="tunnel.bash --forward	--from 10402 --via rudolph@${DOOR} --to localhost:10402 --isRunning"
 TARGETACTION[1]="tunnel.bash --forward	--from 10402 --via rudolph@${DOOR} --to localhost:10402"
 TARGET_CHECK[2]="tunnel.bash --forward	--from 10401 --via rudolph@${DOOR} --to kaos:10401 --isRunning"
 TARGETACTION[2]="tunnel.bash --forward	--from 10401 --via rudolph@${DOOR} --to kaos:10401"
 TARGET_CHECK[3]="tunnel.bash --forward	--from 9900  --via rudolph@${DOOR} --to localhost:9900 --isRunning"
 TARGETACTION[3]="tunnel.bash --forward	--from 9900  --via rudolph@${DOOR} --to localhost:9900"
 TARGET_CHECK[4]="tunnel.bash --forward	--from 7776  --via rudolph@${DOOR} --to kaos:22 --isRunning"
 TARGETACTION[4]="tunnel.bash --forward	--from 7776  --via rudolph@${DOOR} --to kaos:22"
 TARGET_CHECK[5]="tunnel.bash --forward	--from 8800  --via rudolph@${DOOR} --to kaos:80 --isRunning"
 TARGETACTION[5]="tunnel.bash --forward	--from 8800  --via rudolph@${DOOR} --to kaos:80"
 TARGET_CHECK[6]="tunnel.bash --forward	--from 4900  --via rudolph@${DOOR} --to tesla:5900 --isRunning"
 TARGETACTION[6]="tunnel.bash --forward	--from 4900  --via rudolph@${DOOR} --to tesla:5900"
 TARGET_CHECK[7]="tunnel.bash --reverse	--from rudolph@${DOOR}:1601        --to localhost:22 --isRunning"
 TARGETACTION[7]="tunnel.bash --reverse	--from rudolph@${DOOR}:1601        --to localhost:22"
 TARGET_CHECK[8]="tunnel.bash --forward	--from 4212  --via rudolph@${DOOR} --to localhost:4212 --isRunning"
 TARGETACTION[8]="tunnel.bash --forward	--from 4212  --via rudolph@${DOOR} --to localhost:4212"
 TARGET_CHECK[9]="tunnel.bash --forward	--from 4214  --via rudolph@${DOOR} --to localhost:4214 --isRunning"
 TARGETACTION[9]="tunnel.bash --forward	--from 4214  --via rudolph@${DOOR} --to localhost:4214"
TARGET_CHECK[10]="tunnel.bash --forward	--from 4215  --via rudolph@${DOOR} --to localhost:4215 --isRunning"
TARGETACTION[10]="tunnel.bash --forward	--from 4215  --via rudolph@${DOOR} --to localhost:4215"
TARGET_CHECK[11]="tunnel.bash --forward	--from 4216  --via rudolph@${DOOR} --to localhost:4216 --isRunning"
TARGETACTION[11]="tunnel.bash --forward	--from 4216  --via rudolph@${DOOR} --to localhost:4216"
TARGET_CHECK[12]="tunnel.bash --forward	--from 8000  --via rudolph@${DOOR} --to localhost:8000 --isRunning"
TARGETACTION[12]="tunnel.bash --forward	--from 8000  --via rudolph@${DOOR} --to localhost:8000"
TARGET_CHECK[13]="tunnel.bash --forward	--from 5556  --via rudolph@${DOOR} --to localhost:5556 --isRunning"
TARGETACTION[13]="tunnel.bash --forward	--from 5556  --via rudolph@${DOOR} --to localhost:5556"
TARGET_CHECK[14]="tunnel.bash --forward	--from 8888  --via rudolph@${DOOR} --to localhost:8888 --isRunning"
TARGETACTION[14]="tunnel.bash --forward	--from 8888  --via rudolph@${DOOR} --to localhost:8888"
TARGET_CHECK[15]="tunnel.bash --forward	--from 8880  --via rudolph@${DOOR} --to localhost:8880 --isRunning"
TARGETACTION[15]="tunnel.bash --forward	--from 8880  --via rudolph@${DOOR} --to localhost:8880"
TARGET_CHECK[16]="tunnel.bash --forward	--from 3204  --via rudolph@${DOOR} --to localhost:3204 --isRunning"
TARGETACTION[16]="tunnel.bash --forward	--from 3204  --via rudolph@${DOOR} --to localhost:3204"
TARGET_CHECK[17]="tunnel.bash --forward	--from 27000 --via rudolph@${DOOR} --to localhost:27000 --isRunning"
TARGETACTION[17]="tunnel.bash --forward	--from 27000 --via rudolph@${DOOR} --to localhost:27000"
TARGET_CHECK[18]="tunnel.bash --forward	--from 2137  --via rudolph@${DOOR} --to localhost:2137 --isRunning"
TARGETACTION[18]="tunnel.bash --forward	--from 2137  --via rudolph@${DOOR} --to localhost:2137"
TARGET_CHECK[19]="tunnel.bash --forward	--from 1143  --via rudolph@${DOOR} --to machris:443 --isRunning"
TARGETACTION[19]="tunnel.bash --forward	--from 1143  --via rudolph@${DOOR} --to machris:443"
TARGET_CHECK[20]="tunnel.bash --forward	--from 4443  --via rudolph@${DOOR} --to localhost:4443 --isRunning"
TARGETACTION[20]="tunnel.bash --forward	--from 4443  --via rudolph@${DOOR} --to localhost:4443"
TARGET_CHECK[21]="tunnel.bash --forward	--from 3228  --via rudolph@${DOOR} --to localhost:3228 --isRunning"
TARGETACTION[21]="tunnel.bash --forward	--from 3228  --via rudolph@${DOOR} --to localhost:3228"

# Process command line options
while getopts hv: option ; do
        case "$option"
        in
		v) 	let Gi_verbose=$OPTARG	;;
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
