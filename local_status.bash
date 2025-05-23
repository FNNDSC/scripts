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
G_CMD="-x"

G_SYNOPSIS="
 NAME

        local_status.bash

 SYNOPSIS

        local_status.bash    -J     <jobID>                \\
                             -c     <cmd>                  \\
                             [-r    <remoteServerName>]
                                               
                            

 DESCRIPTION

        'local_status.bash' is a script for determing the status of the job
        on a local machine.  
        

 ARGUMENTS
        
        -J <jobId>
        Specify a job ID for the cluster job.  This job ID must be supported
        by the underlying clustering software.
 
        -c <cmd>
        The command that was executed (Job ID is ignored for local processes).
        
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
                c)      G_CMD=$OPTARG;;
                \?)     synopsis_show;;
        esac
done

###\\\
# Some error checking --->
###///


###\\\
# Main --->
###///
found=$(eval "psa "$G_CMD"  | grep $(whoami) | grep -v grep | grep -v _status.bash |  wc -l")
if (( found != 0 )) ; then
    echo -e "$G_JOBID RUNNING"
fi



