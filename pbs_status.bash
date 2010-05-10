#!/bin/bash
#
# pbs_status.bash
#
# Copyright 2010 Dan Ginsburg
# Children's Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

G_LOGFILE=${G_SELF}.log
G_JOBID="-x"
G_REMOTESERVERNAME="-x"

G_SYNOPSIS="
 NAME

        pbs_status.bash

 SYNOPSIS

        pbs_status.bash      -J     <jobID>                \\
                             [-r    <remoteServerName>]
                                               
                            

 DESCRIPTION

        'pbs_status.bash' is a script for determing the status of the job
        on a cluster.  
        

 ARGUMENTS
        
        -J <jobId>
        Specify a job ID for the cluster job.  This job ID must be supported
        by the underlying clustering software.
        
        -r <remoteServerName> (Optional)
        The remote name of the server to run the status command on (for example, the
        head node of the cluster).
  
               

 PRECONDITIONS

        o The appropriate clustering status script (e.g., pbs_status.bash) must exist.

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

while getopts r:J: option ; do
        case "$option" 
        in
                J)      G_JOBID=$OPTARG;;
                r)      G_REMOTESERVERNAME=$OPTARG;;
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
    QUEUELIST=$(qstat)
else
    QUEUELIST=$(ssh ${G_REMOTESERVERNAME} "qstat")    
fi
RESULT=$(echo -e $QUEUELIST | awk 'NR > 2 {print $1" "$2" "$5}') 
IFS="$(echo -e "\n\r")"
for line in $RESULT ; do
    JOBNAME=$(echo -e $line | awk '{print $1}')
    JOBID=$(echo -e $line | awk '{print $2}')
    STATUS=$(echo -e $line | awk '{print $3}')
    STATUS_INTERP="UNKNOWN"    
    
    #  qstat status can be:
    #               C -     Job is completed after having run/
    #               E -  Job is exiting after having run.
    #               H -  Job is held.
    #               Q -  job is queued, eligible to run or routed.
    #               R -  job is running.
    #               T -  job is being moved to new location.
    #               W -  job is waiting for its execution time
    #                    (-a option) to be reached.
    #               S -  (Unicos only) job is suspend.
    case "$STATUS" in
        R|E|C|H|T|W) STATUS_INTERP="RUNNING"
        ;;
        Q) STATUS_INTERP="QUEUED"
        ;;
        *) STATUS_INTERP="UNKNOWN"
    esac

    if [[ "$G_JOBID" == "-x" || "$G_JOBID" == "$JOBID" ]] ; then
    	echo -e "$JOBID $STATUS_INTERP"
    fi    
done

unset IFS


