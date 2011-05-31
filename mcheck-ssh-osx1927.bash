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

declare -a TARGETCHECK
declare -a TARGETACTION

G_SYNOPSIS="

 NAME

       mcheck-ssh-osx1927.bash

 SYNOPSIS

       mcheck-ssh-osx1927.bash

 DESCRIPTION
 
        'mcheck-ssh-osx1927.bash' is used to check that certain script-defined
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

targetList=21

TARGETCHECK[0]="psa 7777  | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[0]="(exec ~/arch/scripts/sshTunnel_restart.sh -g -R 7777 -L 22)"
TARGETCHECK[1]="psa 9900  | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[1]="(exec ~/arch/scripts/sshTunnel_restart.sh -g -R 9900 -L 5900)"
TARGETCHECK[2]="psa 10402 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[2]="(~/arch/scripts/sshTunnel_restart.sh -g -R 10402 -L 10401)"
TARGETCHECK[3]="psa 4900 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[3]="(~/arch/scripts/sshTunnel_restart.sh -g -F -H tesla -h gate -u rudolph -L 4900 -R 5900)"
TARGETCHECK[4]="psa 10301 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[4]="(~/arch/scripts/sshTunnel_restart.sh -g -F -H kaos -h gate -u rudolph -L 10301 -R 10401)"
TARGETCHECK[5]="psa 40960 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[5]="(~/arch/scripts/sshTunnel_restart.sh -g -F -H tesla -h gate -u rudolph -L 40960 -R 4096)"
TARGETCHECK[6]="psa 11112 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[6]="(~/arch/scripts/sshTunnel_restart.sh -g -R 11112 -L 11112)"
TARGETCHECK[7]="psa 8000 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[7]="(exec ~/arch/scripts/sshTunnel_restart.sh -g -R 8000 -L 80 -H durban -h dreev.tch.harvard.edu)"
TARGETCHECK[8]="psa 1476 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[8]="(exec ~/arch/scripts/sshTunnel_restart.sh -g -R 1476 -L 5900 -H osx1476 -h dreev.tch.harvard.edu)"
TARGETCHECK[9]="psa 4212 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[9]="(exec ~/arch/scripts/sshTunnel_restart.sh -g -R 4212 -H ipmi -L 22 -u ch137123 -h dreev.tch.harvard.edu)"
TARGETCHECK[10]="psa 4214 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[10]="(exec ~/arch/scripts/sshTunnel_restart.sh -g -R 4214 -H shaka -h dreev.tch.harvard.edu -u ch137123 -L 22)"
TARGETCHECK[11]="psa 7776 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[11]="(~/arch/scripts/sshTunnel_restart.sh -g -F -H kaos -h gate -u rudolph -L 7776 -R 22)"
TARGETCHECK[12]="psa 7775 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[12]="(~/arch/scripts/sshTunnel_restart.sh -g -F -H heisenberg -h gate -u rudolph -L 7775 -R 22)"
TARGETCHECK[13]="psa 4204 | grep $(whoami) | grep ssh | grep -v grep |  wc -l"
TARGETACTION[13]="(exec ~/arch/scripts/sshTunnel_restart.sh -g -R 4204 -H rc-drno -h dreev.tch.harvard.edu -u ch137123 -L 22)"
TARGETCHECK[14]="psa 8888 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[14]="(exec ~/arch/scripts/sshTunnel_restart.sh -g -R 8888 -H natal -h dreev.tch.harvard.edu -u ch137123 -L 22)"
TARGETCHECK[15]="psa 5214 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[15]="(exec ~/arch/scripts/sshTunnel_restart.sh -g -R 5214 -H 10.3.1.214 -h dreev.tch.harvard.edu -u ch137123 -L 5900)"
TARGETCHECK[16]="psa 5241 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[16]="(exec ~/arch/scripts/sshTunnel_restart.sh -g -R 5241 -H 10.64.4.241 -h dreev.tch.harvard.edu -u ch137123 -L 5900)"
TARGETCHECK[17]="psa 8800 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[17]="(exec ~/arch/scripts/sshTunnel_restart.sh -g -R 8800 -H natal -h dreev.tch.harvard.edu -u ch137123 -L 80)"
TARGETCHECK[18]="psa 4216 | grep $(whoami) | grep -v grep |  wc -l"
TARGETACTION[18]="(exec ~/arch/scripts/sshTunnel_restart.sh -g -R 4216 -H glacier -h dreev.tch.harvard.edu -u ch137123 -L 22)"
TARGETCHECK[19]="psa 9000| grep $(whoami) | grep ssh | grep -v grep |  wc -l"
TARGETACTION[19]="( ssh -p 7778 -g -f -N -X -L 9000:localhost:80 rudolph@71.184.80.220 )"
TARGETCHECK[20]="psa 6812 | grep $(whoami) | grep ssh | grep -v grep |  wc -l"
TARGETACTION[20]="( ssh -p 7778 -g -f -N -X -L 6812:localhost:22 rudolph@71.184.80.220 )"

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
