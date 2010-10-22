#!/bin/bash
#
# mosix_run.bash
#
# Copyright 2010 Dan Ginsburg
# Children's Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

G_LOGFILE=${G_SELF}.log
G_CMD="-x"
G_JOBID="-x"

G_SYNOPSIS="
 NAME

        mosix_run.bash

 SYNOPSIS

        mosix_run.bash      -c      <cmd>                  \\
                            [-J     <jobID>]               \\


 DESCRIPTION

        'mosix_run.bash' is a scheduling script designed to initiate
        running commands on the cluster using MOSIX.  It is invoked
        by 'cluster_run.bash'.


 ARGUMENTS

        -c <cmd>
        The command to run on the cluster.

        [-J <jobId>]
        Specify a job ID for the cluster job.  This job ID must be supported
        by the underlying clustering software.


 PRECONDITIONS

        o Working MOSIX installation.

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

#
# For now, invoke MOSIX with the following options:
# -b = best node
# -E = non-migratable Linux
# -e = unsupported system calls fail
# -q = add to the queue
#
# Other options to consider:
# -m<mb> = we might want to use this to request a large number of MB be available for a freesurfer job
# -P<#> = we can also specify the number of parallel threads that might be spawned to influence queuing.

# Because of problems with Xvfb, only run tract runs on node 2 which is ipmi
FS_MB_REQ="2500"
CLUSTER_SCRIPT=$(echo ${G_CMD} | awk '{print $1}' | xargs basename)
MOSIX_ARGS="-E -e -q"
case "$CLUSTER_SCRIPT" in
    tract-cluster.sh)
        MOSIX_ARGS="$MOSIX_ARGS -b -P4"
    ;;
    fs-cluster.sh)
        MOSIX_ARGS="$MOSIX_ARGS -b -m$FS_MB_REQ"
    ;;
    connectome-cluster.sh)
        MOSIX_ARGS="$MOSIX_ARGS -b -m$FS_MB_REQ"
    ;;
    *)
        MOSIX_ARGS="$MOSIX_ARGS -b"
    ;;
esac

if [[ "$G_JOBID" != "-x" ]] ; then
	MOSIX_ARGS="$MOSIX_ARGS -J${G_JOBID}"
fi
CMD="mosrun $MOSIX_ARGS ${G_CMD} &"
eval $CMD
shut_down $?

