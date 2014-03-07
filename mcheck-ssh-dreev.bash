#!/bin/bash
#
# mcheck-ssh-osx1927.bash
#
# Copyright 2010 Rudolph Pienaar
# Children's Hospital Boston
#
# GPL v2
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

       mcheck-ssh-dreev.bash

 SYNOPSIS

       mcheck-ssh-dreev.bash

 DESCRIPTION
 
        'mcheck-ssh-dreev.bash' is used to check that certain script-defined
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
  o JOHANNESBURG integration.

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

DREEV=dreev.tch.harvard.edu
JOHANNESBURG=johannesburg.tch.harvard.edu
BERLIN=berlin.tch.harvard.edu
OSX1476=osx1476.tch.harvard.edu
DURBAN=durban.tch.harvard.edu
NATAL=natal.tch.harvard.edu
PARIS=paris.tch.harvard.edu
SHAKA=shaka.tch.harvard.edu
GLACIER=glacier.tch.harvard.edu
RCDRNO=rc-drno.tch.harvard.edu
RCRUSSIA=rc-russia.tch.harvard.edu
PRETORIA=pretoria.tch.harvard.edu
GATE=gate.nmr.mgh.harvard.edu
CHRIS=chris.tch.harvard.edu
MATLAB=rc-matlab.tch.harvard.edu
H1=98.118.51.216
FNNDSC=fnndsc.tch.harvard.edu
TAUTONA=tautona.tch.harvard.edu

verbosity_check
REQUIREDFILES="common.bash tunnel.bash pgrep"

for file in $REQUIREDFILES ; do
#        printf "%40s"   "Checking for $file"
        file_checkOnPath $file >/dev/null || fatal fileCheck
done

targetList=37
#
##
### REVERSE TUNNELS -- from dreev
##
# VNC screen access on osx1927
TARGET_CHECK[0]="tunnel.bash --reverse 	--from ch137123@${DREEV}:9900 	--to ${JOHANNESBURG}:5900 --isRunning"
TARGETACTION[0]="tunnel.bash --reverse 	--from ch137123@${DREEV}:9900 	--to ${JOHANNESBURG}:5900"
# VNC screen access to osx1476
TARGET_CHECK[1]="tunnel.bash --reverse	--from ch137123@${DREEV}:1476 	--to ${OSX1476}:5900 --isRunning"
TARGETACTION[1]="tunnel.bash --reverse	--from ch137123@${DREEV}:1476 	--to ${OSX1476}:5900"
# VNC screen access to Siemens Longwood 3.0T
TARGET_CHECK[2]="tunnel.bash --reverse	--from ch137123@${DREEV}:5214	--to 10.3.1.214:5900 --isRunning"
TARGETACTION[2]="tunnel.bash --reverse	--from ch137123@${DREEV}:5214	--to 10.3.1.214:5900"
# VNC screen access to Siemens Waltham 3.0T
TARGET_CHECK[3]="tunnel.bash --reverse	--from ch137123@${DREEV}:5241	--to 10.64.4.241:5900 --isRunning"
TARGETACTION[3]="tunnel.bash --reverse	--from ch137123@${DREEV}:5241	--to 10.64.4.241:5900"
# DICOM transmission/reception to osx1927
TARGET_CHECK[4]="tunnel.bash --reverse 	--from ch137123@${DREEV}:10402 	--to ${PRETORIA}:10401 --isRunning"
TARGETACTION[4]="tunnel.bash --reverse 	--from ch137123@${DREEV}:10402 	--to ${PRETORIA}:10401"
# Web access to 'durban'
TARGET_CHECK[5]="tunnel.bash --reverse 	--from ch137123@${DREEV}:8000 	--to ${DURBAN}:80 --isRunning"
TARGETACTION[5]="tunnel.bash --reverse 	--from ch137123@${DREEV}:8000 	--to ${DURBAN}:80"
# Web access to 'johannesburg'
TARGET_CHECK[6]="tunnel.bash --reverse	--from ch137123@${DREEV}:8800	--to ${JOHANNESBURG}:80 --isRunning"
TARGETACTION[6]="tunnel.bash --reverse	--from ch137123@${DREEV}:8800	--to ${JOHANNESBURG}:80"
# Web access to 'natal'
TARGET_CHECK[7]="tunnel.bash --reverse	--from ch137123@${DREEV}:8880	--to ${NATAL}:80 --isRunning"
TARGETACTION[7]="tunnel.bash --reverse	--from ch137123@${DREEV}:8880	--to ${NATAL}:80"
# OsiriX listener on 'osx1927'
TARGET_CHECK[8]="tunnel.bash --reverse 	--from ch137123@${DREEV}:11112	--to ${JOHANNESBURG}:11112 --isRunning"
TARGETACTION[8]="tunnel.bash --reverse 	--from ch137123@${DREEV}:11112	--to ${JOHANNESBURG}:11112"
# SVN source code repositories
TARGET_CHECK[9]="tunnel.bash --reverse	--from ch137123@${DREEV}:5555	--to ${BERLIN}:22 --isRunning"
TARGETACTION[9]="tunnel.bash --reverse	--from ch137123@${DREEV}:5555	--to ${BERLIN}:22"
TARGET_CHECK[10]="tunnel.bash --reverse	--from ch137123@${DREEV}:5556	--to ${NATAL}:22 --isRunning"
TARGETACTION[10]="tunnel.bash --reverse	--from ch137123@${DREEV}:5556	--to ${NATAL}:22"
TARGET_CHECK[11]="tunnel.bash --reverse	--from ch137123@${DREEV}:4212	--to ${PARIS}:22 --isRunning"
TARGETACTION[11]="tunnel.bash --reverse	--from ch137123@${DREEV}:4212	--to ${PARIS}:22"
TARGET_CHECK[12]="tunnel.bash --reverse	--from ch137123@${DREEV}:4214	--to ${SHAKA}:22 --isRunning"
TARGETACTION[12]="tunnel.bash --reverse	--from ch137123@${DREEV}:4214	--to ${SHAKA}:22"
TARGET_CHECK[13]="tunnel.bash --reverse	--from ch137123@${DREEV}:4216 	--to ${GLACIER}:22 --isRunning"
TARGETACTION[13]="tunnel.bash --reverse	--from ch137123@${DREEV}:4216 	--to ${GLACIER}:22"
TARGET_CHECK[14]="tunnel.bash --reverse --from ch137123@${DREEV}:7777 	--to ${JOHANNESBURG}:22 --isRunning"
TARGETACTION[14]="tunnel.bash --reverse --from ch137123@${DREEV}:7777 	--to ${JOHANNESBURG}:22"
TARGET_CHECK[15]="tunnel.bash --reverse	--from ch137123@${DREEV}:4215	--to ${PRETORIA}:22 --isRunning"
TARGETACTION[15]="tunnel.bash --reverse	--from ch137123@${DREEV}:4215	--to ${PRETORIA}:22"
# Cluster repository
TARGET_CHECK[16]="tunnel.bash --reverse	--from ch137123@${DREEV}:3204	--to ${RCDRNO}:22 --isRunning"
TARGETACTION[16]="tunnel.bash --reverse	--from ch137123@${DREEV}:3204	--to ${RCDRNO}:22"
TARGET_CHECK[17]="tunnel.bash --reverse	--from ch137123@${DREEV}:2121   --to ${FNNDSC}:21 --isRunning"
TARGETACTION[17]="tunnel.bash --reverse	--from ch137123@${DREEV}:2121   --to ${FNNDSC}:21"
TARGET_CHECK[18]="tunnel.bash --reverse	--from ch137123@${DREEV}:3203	--to ${RCRUSSIA}:22 --isRunning"
TARGETACTION[18]="tunnel.bash --reverse	--from ch137123@${DREEV}:3203	--to ${RCRUSSIA}:22"
# ChRIS VM
TARGET_CHECK[19]="tunnel.bash --reverse	--from ch137123@${DREEV}:8888	--to ${CHRIS}:80 --isRunning"
TARGETACTION[19]="tunnel.bash --reverse	--from ch137123@${DREEV}:8888	--to ${CHRIS}:80"

#
##
### (1/2) FORWARD TUNNELS -- maps a port on localhost to port on intermediary;
### these are connection points for reverse tunnels back to NMR.
##
# 
# tesla VNC
TARGET_CHECK[20]="tunnel.bash --forward	--from 4900 --via ch137123@${DREEV} --to localhost:4900 --isRunning"
TARGETACTION[20]="tunnel.bash --forward	--from 4900 --via ch137123@${DREEV} --to localhost:4900"
# kaos login
TARGET_CHECK[21]="tunnel.bash --forward --from 7776 --via ch137123@${DREEV} --to localhost:7776 --isRunning"
TARGETACTION[21]="tunnel.bash --forward --from 7776 --via ch137123@${DREEV} --to localhost:7776"
# tesla login
TARGET_CHECK[22]="tunnel.bash --forward	--from 7775 --via ch137123@${DREEV} --to localhost:7775 --isRunning"
TARGETACTION[22]="tunnel.bash --forward	--from 7775 --via ch137123@${DREEV} --to localhost:7775"
# kaos -- DICOM listener
TARGET_CHECK[23]="tunnel.bash --forward --from 10301 --via ch137123@${DREEV} --to localhost:10301 --isRunning"
TARGETACTION[23]="tunnel.bash --forward --from 10301 --via ch137123@${DREEV} --to localhost:10301"

#
##
### FORWARD TUNNELS -- to site H1
##
#
TARGET_CHECK[24]="tunnel.bash --forward	--from 9000 --via rudolph@${H1} --to localhost:80 --sshArgs '-p 7778' --isRunning"
TARGETACTION[24]="tunnel.bash --forward	--from 9000 --via rudolph@${H1} --to localhost:80 --sshArgs '-p 7778'"
TARGET_CHECK[25]="tunnel.bash --forward	--from 6812 --via rudolph@${H1} --to localhost:22 --sshArgs '-p 7778' --isRunning"
TARGETACTION[25]="tunnel.bash --forward	--from 6812 --via rudolph@${H1} --to localhost:22 --sshArgs '-p 7778'"

#
##
### FORWARD TUNNELS -- to Partners clusters
##
#
TARGET_CHECK[26]="tunnel.bash --forward	--from 7774 --via ch137123@${DREEV} --to localhost:7774 --isRunning"
TARGETACTION[26]="tunnel.bash --forward	--from 7774 --via ch137123@${DREEV} --to localhost:7774"
TARGET_CHECK[27]="tunnel.bash --forward	--from 7773 --via ch137123@${DREEV} --to localhost:7773 --isRunning"
TARGETACTION[27]="tunnel.bash --forward	--from 7773 --via ch137123@${DREEV} --to localhost:7773"

# MatLAB
TARGET_CHECK[28]="tunnel.bash --reverse	--from ch137123@${DREEV}:27000  --to ${MATLAB}:27000 --isRunning"
TARGETACTION[28]="tunnel.bash --reverse	--from ch137123@${DREEV}:27000  --to ${MATLAB}:27000 "


# ChRIS @ NMR
TARGET_CHECK[29]="tunnel.bash --forward	--from 1148 --via ch137123@${DREEV} --to localhost:1148 --isRunning"
TARGETACTION[29]="tunnel.bash --forward	--from 1148 --via ch137123@${DREEV} --to localhost:1148"
TARGET_CHECK[30]="tunnel.bash --forward	--from 1188 --via ch137123@${DREEV} --to localhost:1188 --isRunning"
TARGETACTION[30]="tunnel.bash --forward	--from 1188 --via ch137123@${DREEV} --to localhost:1188"
TARGET_CHECK[31]="tunnel.bash --forward	--from 1143 --via ch137123@${DREEV} --to localhost:1143 --isRunning"
TARGETACTION[31]="tunnel.bash --forward	--from 1143 --via ch137123@${DREEV} --to localhost:1143"

TARGET_CHECK[32]="tunnel.bash --reverse	--from ch137123@${DREEV}:4443 --to ${CHRIS}:443 --isRunning"
TARGETACTION[32]="tunnel.bash --reverse	--from ch137123@${DREEV}:4443 --to ${CHRIS}:443"

# Persistent hosts: fnndsc, tautona, rc-majesty
TARGET_CHECK[33]="tunnel.bash --reverse	--from ch137123@${DREEV}:2137 --to ${FNNDSC}:22 --isRunning"
TARGETACTION[33]="tunnel.bash --reverse	--from ch137123@${DREEV}:2137 --to ${FNNDSC}:22 "
TARGET_CHECK[34]="tunnel.bash --reverse	--from ch137123@${DREEV}:3228 --to ${TAUTONA}:22 --isRunning"
TARGETACTION[34]="tunnel.bash --reverse	--from ch137123@${DREEV}:3228 --to ${TAUTONA}:22 "
TARGET_CHECK[35]="tunnel.bash --reverse	--from ch137123@${DREEV}:8443 --to ${CHRIS}:443 --isRunning"
TARGETACTION[35]="tunnel.bash --reverse	--from ch137123@${DREEV}:8443 --to ${CHRIS}:443"
TARGET_CHECK[36]="tunnel.bash --reverse	--from ch137123@${DREEV}:3142 --to ${CHRIS}:3142 --isRunning"
TARGETACTION[36]="tunnel.bash --reverse	--from ch137123@${DREEV}:3142 --to ${CHRIS}:3142"


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
