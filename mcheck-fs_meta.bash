#!/bin/bash
#
# mcheck-fs_meta.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# SPDX-License-Identifier: MIT
#

# "include" the set of common script functions
source common.bash

G_REPORTLOG=/tmp/${SELF}.reportLog.$G_PID
G_ADMINUSERS=rudolph@nmr.mgh.harvard.edu

declare -i targetList

declare -a TARGETCHECK
declare -a TARGETACTION

G_SYNOPSIS="

 NAME

       mcheck-fs_meta.bash

 SYNOPSIS

       mcheck-fs_meta.bash

 DESCRIPTION
 
        'mcheck-fs_meta.bash' is used to check that certain script-defined
	conditions are true. If any of these conditions are false, it executes 
	a set of corrective actions.
	
	It should typically be called from a cron process, and this particular
	version of 'mcheck' is tailored to monitoring 'fs_meta.bash' pipeline
	outputs.
	
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
 20 May 2008
  o fs_meta.bash integration.

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

targetList=1

TARGETCHECK[0]="ps -Af | grep filewatch | grep schedule.log | grep -v grep | grep -v $G_SELF | wc -l"
TARGETACTION[0]="(cd $HOME ; /homes/9/rudolph/arch/scripts/fwatch_restart.sh -v 10 schedule.log )"

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
        result=$(eval ${TARGETCHECK[$i]})
	if [ "$result" -eq "0" ] ; then
	        #echo "${TARGETACTION[$i]} &"
		statusPrint "Restarting target action..."
	        eval "${TARGETACTION[$i]} &"
		ret_check $? || badRestart
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