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
G_ADMINUSERS=daniel.ginsburg@childrens.harvard.edu

declare -i targetList

declare -a TARGETCHECK
declare -a TARGETACTION

G_SYNOPSIS="

 NAME

       mcheck-ssh-kaos.bash

 SYNOPSIS

       mcheck-ssh-kaos.bash

 DESCRIPTION
 
        'mcheck-ssh-kaos.bash' is used to check that certain script-defined
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
  o KAOS integration.

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

targetList=3

TARGETCHECK[0]="psa 5556  | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[0]="(exec ~/workspace/trunk/scripts/sshTunnel_restart.sh -F -H localhost -h dreev.tch.harvard.edu -u ch141111 -R 5556 -L 5556)"
TARGETCHECK[1]="psa 5559  | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[1]="(exec ~/workspace/trunk/scripts/sshTunnel_restart.sh -B -H kaos -h gate -u ginsburg -R 5559 -L 80)"
TARGETCHECK[2]="psa 10409  | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[2]="(exec ~/workspace/trunk/scripts/sshTunnel_restart.sh -B -H kaos -h gate -u ginsburg -R 10409 -L 10401 -g)"

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
