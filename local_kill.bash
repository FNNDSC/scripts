#!/bin/bash
#
# mosix_kill.bash
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

        local_kill.bash

 SYNOPSIS

        local_kill.bash      -J     <jobID>                \\
                             -c     <cmd>                  \\
                             [-r    <remoteServerName>]
                                               
                            

 DESCRIPTION

        'local_kill.bash' is a script for killing a running job on the local machine.
        

 ARGUMENTS
        
        -J <jobId>
        Specify a job ID for the cluster job.  This job ID must be supported
        by the underlying clustering software.

        -c <cmd>
        Command that was run.
        
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
A_noCmdArg="checking on the -c <cmd> argument"

# Error messages
EM_noJobIdArg="it seems as though you didn't specify a -J <JobID>."
EM_noCmdArg="it seems as though you didn't specify a -c <cmd>."

# Error codes
EC_noJobIdArg=11
EC_noCmdArg=12

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
                c)      G_CMD=$OPTARG;;
                r)      G_REMOTESERVERNAME=$OPTARG;;
                \?)     synopsis_show;;
        esac
done

###\\\
# Some error checking --->
###///


statusPrint "Checking on <cmd>"
if [[ "$G_CMD" == "-x" ]] ; then fatal noCmdArg ; fi
ret_check $?

###\\\
# Main --->
###///
if [[ "$G_REMOTESERVERNAME" == "-x" ]] ; then
    mkill "$G_CMD"
fi

shut_down $?
