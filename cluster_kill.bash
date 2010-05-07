#!/bin/bash
#
# cluster_kill.bash
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

        cluster_kill.bash

 SYNOPSIS

        cluster_kill.bash    -C     <clusterType>          \\
                             -J     <jobID>                \\
                             [-r    <remoteServerName>]
                                               
                            

 DESCRIPTION

        'cluster_kill.bash' is a script for killing a job by jobID.  Its purpose 
        it to be an abstraction on the underlying  clustering software.  It will 
        invoke <cluster_type>_kill.bash to kill the job. If you need to create a 
        new cluster type, simply add new bash scripts with the appropriate name.
        

 ARGUMENTS
        
        -C <clusterType>
        This is the name of the cluster for example 'mosix' or 'pbs'.  The
        script will attempt to execute '<clusterType>_kill.bash', for example
        'mosix_kill.bash'.  If you have your own clustering system, you can
        create new scripts with a new name and pass the <clusterType> argument
        specifying that name.

        -J <jobId>
        Specify a job ID for the cluster job.  This job ID must be supported
        by the underlying clustering software.

        -r <remoteServerName> (Optional)
        The remote name of the server to run the status command on (for example, the
        head node of the cluster).
               

 PRECONDITIONS

        o The appropriate clustering status script (e.g., mosix_status.bash) must exist.

 POSTCONDITIONS

        o The job will be killed

 HISTORY
        5 May 20010
        o Initial design and coding
"
###\\\
# Global variables --->
###///

# Actions
A_noClusterTypeArg="checking on the -C <clusterType> argument"
A_noJobIdArg="checking on the -J <JobId> argument"

# Error messages
EM_noClusterTypeArg="it seems as though you didn't specify a -C <clusterType>."
EM_noJobIdArg="it seems as though you didn't specify a -J <JobID>."

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

statusPrint "Checking on <clusterType>"
if [[ "$G_CLUSTERTYPE" == "-x" ]] ; then fatal noClusterTypeArg ; fi
ret_check $?

statusPrint "Checking on <jobId>"
if [[ "$G_JOBID" == "-x" ]] ; then fatal noJobIdArg ; fi
ret_check $?


###\\\
# Main --->
###///
ARGS="-J $G_JOBID"
if [[ "$G_REMOTESERVERNAME" != "-x" ]] ; then
	ARGS="$ARGS -r $G_REMOTESERVERNAME"
fi

# Execute the cluster script
STATUSCMD="${G_CLUSTERTYPE}_kill.bash $ARGS"
eval $STATUSCMD

shut_down $?

