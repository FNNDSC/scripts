#!/bin/bash
#
# pbs_kill.bash
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

        pbs_kill.bash

 SYNOPSIS

        pbs_kill.bash        -J     <jobID>                \\
                             [-r    <remoteServerName>]
                                               
                            

 DESCRIPTION

        'pbs_kill.bash' is a script for killing a running or queued job on the cluster.
        

 ARGUMENTS
        
        -J <jobId>
        Specify a job ID for the cluster job.  This job ID must be supported
        by the underlying clustering software.
        
        -r <remoteServerName> (Optional)
        The remote name of the server to run the status command on (for example, the
        head node of the cluster).
  
               

 PRECONDITIONS

        o The appropriate clustering sofrtware must exist.

 POSTCONDITIONS

        o The job will be killed.

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


statusPrint "Checking on <jobId>"
if [[ "$G_JOBID" == "-x" ]] ; then fatal noJobIdArg ; fi
ret_check $?

###\\\
# Main --->
###///
IFS=''
QUEUELIST=""
if [[ "$G_REMOTESERVERNAME" == "-x" ]] ; then
    QUEUELIST=$(qstat)
else
    QUEUELIST=$(ssh -n ${G_REMOTESERVERNAME} "qstat")
fi
JOBNAME=$(echo -e $QUEUELIST | awk 'NR > 2 {print $1" "$2}' | grep ${G_JOBID} | awk '{print $1'})
if [[ "$JOBNAME" != "" ]] ; then
    if [[ "$G_REMOTESERVERNAME" == "-x" ]] ; then
       RESULT=$(qdel ${JOBNAME})
    else
       RESULT=$(ssh ${G_REMOTESERVERNAME} "qdel ${JOBNAME}")
    fi
fi
