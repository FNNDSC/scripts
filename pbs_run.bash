#!/bin/bash
#
# pbs_run.bash
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
G_JOBID="-x"

G_SYNOPSIS="
 NAME

        pbs_run.bash

 SYNOPSIS

        pbs_run.bash      -c      <cmd>                  \\                            
                            [-J     <jobID>]               \\
                            

 DESCRIPTION

        'pbs_run.bash' is a scheduling script designed to initiate
        running commands on the cluster using PBS.  It is invoked
        by 'cluster_run.bash'.
        

 ARGUMENTS

        -c <cmd>
        The command to run on the cluster.       

        [-J <jobId>]
        Specify a job ID for the cluster job.  This job ID must be supported
        by the underlying clustering software.
               

 PRECONDITIONS

        o Working PBS installation.

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

# Error messages
EM_noCmdArg="it seems as though you didn't specify a -c <cmd>."

# Error codes
EC_noCmdArge=10

###\\\ 
# function definitions --->
###/// 


###\\\ 
# Process command options --->
###/// 

while getopts c:J: option ; do
        case "$option" 
        in
                c)      G_CMD=$OPTARG;;                
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

###\\\
# Main --->
###///

# Use pbsubmit to execute job on cluster
PBS_ARGS=""

# Provide a job ID if it was specified on the command line
if [[ "$G_JOBID" != "-x" ]] ; then
	PBS_ARGS="-o \"-N ${G_JOBID}\""
fi
CMD="pbsubmit -c \"${G_CMD}\" ${PBS_ARGS}"
eval $CMD
shut_down $?

