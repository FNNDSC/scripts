#!/bin/bash
#
# cluster_run.bash
#
# Copyright 2010 Dan Ginsburg
# Children's Hospital Boston
#
# SPDX-License-Identifier: MIT
#

# "include" the set of common script functions
source common.bash

G_LOGFILE=${G_SELF}.log
G_CMD="-x"
G_CLUSTERTYPE="-x"
G_JOBID="-x"

G_SYNOPSIS="
 NAME

        cluster_run.bash

 SYNOPSIS

        cluster_run.bash    -c      <cmd>                  \\
                            -C      <clusterType>          \\
                            [-J     <jobID>]               \\
                            

 DESCRIPTION

        'cluster_run.bash' is a scheduling script designed to initiate
        running commands on the cluster.  Its purpose it to be an
        abstraction on the underlying clustering software.  It will invoke
        <cluster_type>_run.bash to run on the cluster.  If you need to
        create a new cluster type, simply add new bash scripts with the
        appropriate name.
        

 ARGUMENTS

        -c <cmd>
        The command to run on the cluster.

        -C <clusterType>
        This is the name of the cluster for example 'mosix' or 'pbs'.  The
        script will attempt to execute '<clusterType>_run.bash', for example
        'mosix_run.bash'.  If you have your own clustering system, you can
        create new scripts with a new name and pass the <clusterType> argument
        specifying that name.

        [-J <jobId>]
        Specify a job ID for the cluster job.  This job ID must be supported
        by the underlying clustering software.
               

 PRECONDITIONS

        o The appropriate clustering run script (e.g., mosix_run.bash) must exist.

 POSTCONDITIONS

        o The command will be queued for execution on the cluster.

 HISTORY
        5 May 20010
        o Initial design and coding
"
###\\\
# Global variables --->
###///

# Actions
A_noCmdArg="checking on the -c <cmd> argument"
A_noClusterTypeArg="checking on the -C <clusterType> argument"

# Error messages
EM_noCmdArg="it seems as though you didn't specify a -c <cmd>."
EM_noClusterTypeArg="it seems as though you didn't specify a -C <clusterType>."

# Error codes
EC_noCmdArge=10
EC_noClusterTypeArg=11

###\\\ 
# function definitions --->
###/// 


###\\\ 
# Process command options --->
###/// 

while getopts c:C:J: option ; do
        case "$option" 
        in
                c)      G_CMD=$OPTARG;;
                C)      G_CLUSTERTYPE=$OPTARG;;
                J)      G_JOBID=$OPTARG;;
                \?)     synopsis_show;;
        esac
done

###\\\
# Some error checking --->
###///

statusPrint "Checking on <cmd>"
if [[ "$G_CMD" == "-x" ]] ; then fatal noCmdArg ; fi
ret_check $?

statusPrint "Checking on <clusterType>"
if [[ "$G_CLUSTERTYPE" == "-x" ]] ; then fatal noClusterTypeArg ; fi
ret_check $?
		

###\\\
# Main --->
###///
ARGS="-c \"${G_CMD}\""
if [[ "$G_CMD" != "-x" ]] ; then
	ARGS="$ARGS -J $G_JOBID"
fi

# Execute the cluster script
CLUSTERCMD="${G_CLUSTERTYPE}_run.bash $ARGS"
eval $CLUSTERCMD 

shut_down $?

