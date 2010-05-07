#!/bin/bash
#
# cluster_status.bash
#
# Copyright 2010 Dan Ginsburg
# Children's Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

G_LOGFILE=${G_SELF}.log
G_CLUSTERTYPE="-x"
G_JOBID="-x"
G_REMOTESERVERNAME="-x"

G_SYNOPSIS="
 NAME

        cluster_status.bash

 SYNOPSIS

        cluster_status.bash  -C     <clusterType>          \\
                             [-J     <jobID>]              \\
                             [-r    <remoteServerName>]
                                               
                            

 DESCRIPTION

        'cluster_status.bash' is a script for determing the status of the job
        on a cluster.  Its purpose it to be an abstraction on the underlying 
        clustering software.  It will invoke <cluster_type>_status.bash to get
        the status on the cluster.  If you need to create a new cluster type, simply 
        add new bash scripts with the appropriate name.
        

 ARGUMENTS
        
        -C <clusterType>
        This is the name of the cluster for example 'mosix' or 'pbs'.  The
        script will attempt to execute '<clusterType>_status.bash', for example
        'mosix_status.bash'.  If you have your own clustering system, you can
        create new scripts with a new name and pass the <clusterType> argument
        specifying that name.

        -J <jobId> (Optional)
        Specify a job ID to get the status of.  If not specified, returns the status
        of all jobs in the queue.

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
A_noClusterTypeArg="checking on the -C <clusterType> argument"

# Error messages
EM_noClusterTypeArg="it seems as though you didn't specify a -C <clusterType>."

# Error codes
EC_noClusterTypeArg=10
EC_noJobIdArg=11

###\\\ 
# function definitions --->
###/// 


###\\\ 
# Process command options --->
###/// 

while getopts r:C:J: option ; do
        case "$option" 
        in
                C)      G_CLUSTERTYPE=$OPTARG;;
                J)      G_JOBID=$OPTARG;;
                r)      G_REMOTESERVERNAME=$OPTARG;;
                \?)     synopsis_show;;
        esac
done

###\\\
# Some error checking --->
###///

if [[ "$G_CLUSTERTYPE" == "-x" ]] ; then fatal noClusterTypeArg ; fi


###\\\
# Main --->
###///
ARGS=""
if [[ "$G_JOBID" != "-x" ]] ; then
    ARGS="-J $G_JOBID"
fi
if [[ "$G_REMOTESERVERNAME" != "-x" ]] ; then
	ARGS="$ARGS -r $G_REMOTESERVERNAME"
fi

# Execute the cluster script
STATUSCMD="${G_CLUSTERTYPE}_status.bash $ARGS"
eval $STATUSCMD


