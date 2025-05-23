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

declare -a TARGETCHECK
declare -a TARGETACTION

G_SYNOPSIS="

 NAME

       mcheck-ssh-brain.bash

 SYNOPSIS

       mcheck-ssh-brain.bash

 DESCRIPTION
 
        'mcheck-ssh-brain' is used to check that certain script-defined
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
  o OSX2147 integration.

"

###\\\
# Global variables
###///

# Actions
A_badRestart="attempting a corrective action"

# Error messages
EM_badRestart="the corrective action failed. Perhaps a target process failed?"

# Error codes
EC_badRestart=10

DOOR=door.nmr.mgh.harvard.edu
SUN=sun.chpc.ac.za
H1=96.237.51.69

targetList=7

 TARGET_CHECK[0]="tunnel.bash --forward	--from 2525 --via rpienaar@${SUN} --to smtp.chpc.ac.za:25 --isRunning"
 TARGETACTION[0]="tunnel.bash --forward	--from 2525 --via rpienaar@${SUN} --to smtp.chpc.ac.za:25"
 TARGET_CHECK[1]="tunnel.bash --forward	--from 2468 --via rpienaar@${SUN} --to localhost:2468 --isRunning"
 TARGETACTION[1]="tunnel.bash --forward	--from 2468 --via rpienaar@${SUN} --to localhost:2468"
 TARGET_CHECK[2]="tunnel.bash --forward	--from 2444 --via rpienaar@${SUN} --to localhost:2444 --isRunning"
 TARGETACTION[2]="tunnel.bash --forward	--from 2444 --via rpienaar@${SUN} --to localhost:2444"
 TARGET_CHECK[3]="tunnel.bash --forward	--from 2214 --via rudolph@${DOOR} --to localhost:2214 --isRunning"
 TARGETACTION[3]="tunnel.bash --forward	--from 2214 --via rudolph@${DOOR} --to localhost:2214"
 TARGET_CHECK[4]="tunnel.bash --forward	--from 4443 --via rudolph@${DOOR} --to localhost:4443 --isRunning"
 TARGETACTION[4]="tunnel.bash --forward	--from 4443 --via rudolph@${DOOR} --to localhost:4443"

 TARGET_CHECK[5]="tunnel.bash --forward --from 10402 --via rudolph@${DOOR} --to localhost:10402 --isRunning"
 TARGETACTION[5]="tunnel.bash --forward --from 10402 --via rudolph@${DOOR} --to localhost:10402"
 TARGET_CHECK[6]="tunnel.bash --forward --from 10403 --via rudolph@${DOOR} --to localhost:10403 --isRunning"
 TARGETACTION[6]="tunnel.bash --forward --from 10403 --via rudolph@${DOOR} --to localhost:10403"


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
        echo -e "Failed:\t\t${TARGETCHECK[$i]}"         >> $G_REPORTLOG
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
