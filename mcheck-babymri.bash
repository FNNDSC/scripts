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

       mcheck-babymri.bash

 SYNOPSIS

       mcheck-babymri.bash

 DESCRIPTION
 
        'mcheck-babymri' is used to check that certain script-defined
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
 23 Dec 2015
  o Setup.

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
H1=173.48.136.14

verbosity_check
REQUIREDFILES="common.bash tunnel.bash pgrep"

for file in $REQUIREDFILES ; do
#        printf "%40s"   "Checking for $file"
        file_checkOnPath $file >/dev/null || fatal fileCheck
done

targetList=1

#
##
### TUNNELS -- to 'FNNDSC' and 'NMR' destinations
##
#
 TARGET_CHECK[0]="tunnel.bash --forward	--from 4444 --via babymr5@babymri.org --to localhost:3333 --sshArgs '-p 2222' --isRunning"
 TARGETACTION[0]="tunnel.bash --forward	--from 4444 --via babymr5@babymri.org --to localhost:3333 --sshArgs '-p 2222'"

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
