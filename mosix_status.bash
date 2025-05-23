#!/bin/bash
#
# mosix_status.bash
#
# Copyright 2010 Dan Ginsburg
# Children's Hospital Boston
#
# SPDX-License-Identifier: MIT
#

# "include" the set of common script functions
source common.bash

G_LOGFILE=${G_SELF}.log
G_JOBID="-x"
G_REMOTESERVERNAME="-x"

G_SYNOPSIS="
 NAME

        mosix_status.bash

 SYNOPSIS

        mosix_status.bash    -J     <jobID>                \\
                             [-r    <remoteServerName>]
                                               
                            

 DESCRIPTION

        'mosix_status.bash' is a script for determing the status of the job
        on a cluster.  
        

 ARGUMENTS
        
        -J <jobId>
        Specify a job ID for the cluster job.  This job ID must be supported
        by the underlying clustering software.
        
        -r <remoteServerName> (Optional)
        The remote name of the server to run the status command on (for example, the
        head node of the cluster).
  
               

 PRECONDITIONS

        o The appropriate clustering status script (e.g., mosix_status.bash) must exist.

 POSTCONDITIONS

        o The status of the job will be returned.

 HISTORY
        5 May 20010
        o Initial design and coding
"
###\\\
# Global variables --->
###///

# Actions
A_noJobIdArg="checking on the -J <JobId> argument"

# Error messages
EM_noJobIdArg="it seems as though you didn't specify a -J <JobID>."

# Error codes
EC_noJobIdArg=11

###\\\ 
# function definitions --->
###/// 


###\\\ 
# Process command options --->
###/// 

while getopts r:J:c: option ; do
        case "$option" 
        in
                J)      G_JOBID=$OPTARG;;
                r)      G_REMOTESERVERNAME=$OPTARG;;
                c)      ;;
                \?)     synopsis_show;;
        esac
done

###\\\
# Some error checking --->
###///


###\\\
# Main --->
###///

IFS=''
QUEUELIST=""
if [[ "$G_REMOTESERVERNAME" == "-x" ]] ; then
    QUEUELIST=$(mosq -j listall)
else
    QUEUELIST=$(ssh -n ${G_REMOTESERVERNAME} "mosq -j listall")    
fi
RESULT=$(echo -e $QUEUELIST | awk 'NR > 1 {print $5" "$6}') # | grep ${G_JOBID} | awk '{print $1}')
IFS="$(echo -e "\n\r")"
for line in $RESULT ; do
    JOBID=$(echo -e $line | awk '{print $2}')
    STATUS=$(echo -e $line | awk '{print $1}')
    STATUS_INTERP="UNKNOWN"    
    echo -e "$STATUS" | grep "RUN" > /dev/null
    if [ $? -eq 0 ] ; then
    	STATUS_INTERP="RUNNING"
    else
        if [[ "$STATUS" != "" ]] ; then
            STATUS_INTERP="QUEUED"
        fi
    fi
    if [[ "$G_JOBID" == "-x" || "$G_JOBID" == "$JOBID" ]] ; then
    	echo -e "$JOBID $STATUS_INTERP"
    fi    
done

unset IFS


