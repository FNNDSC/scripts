#!/bin/bash
#
# pbsubdiff.sh
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# SPDX-License-Identifier: MIT
#

# "include" the set of common script functions
source common.bash

G_SCHEDULEFILE="-x"
G_PARENTID="00000"
G_CLUSTERTYPE="mosix"
G_JOBIDPREFIX=""
Gb_passJobID=0
Gb_watchDir=0
G_watchDir="/space/kaos/1/users/dicom/postproc/seychelles"
G_LOGFILE=${G_SELF}.log

G_SYNOPSIS="
 NAME

        pbsubdiff.sh

 SYNOPSIS

        pbsubdiff.sh    -f      <scheduleFile>                  \\
                        [-D]                                    \\
                        [-t     <tmpDir>]                       \\
                        [-c     <parentID>]                     \\
                        [-C     <clusterType>]                  \\
                        [-J]                                    \\
                        [-p     <jobIdPrefix>]

 DESCRIPTION

        'pbsubdiff' is a scheduling script designed to initiate
        reconstructions on the 'seychelles' cluster. It is called
        when an external trigger/poll process detects changes in 
        size to a master scheduling <scheduleFile>.

        This script tracks changes to <scheduleFile> by keeping
        snapshots of the <scheduleFile> and comparing changes. Changes
        between these states indicate changes to the master scheduling
        file.

        It is typically used in conjunction with 'filewatch', and expects
        its file argument to be formatted in a manner similar to the 
        stamp-log tracking of 'common.bash'.

        The optional <parentID> is a parameter passed over from the parent
        filewatch process and is appended to the state names, allowing 
        easy association between states and a parent filewatch.

 ARGUMENTS

        -f <scheduleFile>
        The scheduling file to monitor.

        -D (Optional)
        If true, use the dirname from <scheduleFile> as the watch directory.

        -t <tmpDir> (Optional: $G_watchDir)
        The directory to contain temporary state information.
        
        -c <parentID> (Optional)
        If specified, append this ID to state files.

        -C <clusterType> (Optional: $G_CLUSTERTYPE)
        If specified, run on this type of cluster (e.g., mosix, pbs)
        
        -J (Optional: default off)
        If specified, provide a JobID to the cluster run script.  The 
        job ID will be the line number of the command in the <scheduleFile>.
        If you need to prepend a string to the JobID, specify it in 
        the (-p) option.
        
        -p <jobIdPrefix> (Optional)
        If (-J) is specified, this string will be prepended to the job ID
        that is passed into the cluster run script.  For example, if you
        specify 'pbs' then the jobID will be 'pbs####' (where #### is the
        line number).

 PRECONDITIONS

        o The scheduling <scheduleFile> is 'stamplog' formatted.

 POSTCONDITIONS

        o Changes between <filename> derived states are executed on
          the cluster, in effect a command is parsed and 'exec'ed.

 HISTORY
        20 May 2008
        o Adapted from 'auddif.sh'
        
        14 July 2008
        o Addded <tmpDir> handling.

        17 March 2009
        o Removed the 'tail' comparisons, which suffer from maximum
          of ten scheduled events.

"
###\\\
# Global variables --->
###///

# Actions
A_comargs="checking command line arguments"
A_noScheduleFile="checking on the scheduling file"

# Error messages
EM_noScheduleFile="I couldn't access <scheduleFile>. Does it exist?"

# Error codes
EC_noScheduleFile=10

###\\\ 
# function definitions --->
###/// 


###\\\ 
# Process command options --->
###/// 

while getopts f:c:DC:Jp: option ; do
        case "$option" 
        in
                f)      G_SCHEDULEFILE=$OPTARG;;
                c)      G_PARENTID=$OPTARG;;
                D)      Gb_watchDir=1;;
                C)      G_CLUSTERTYPE=$OPTARG;;
                J)      Gb_passJobID=1;;
                p)      G_JOBIDPREFIX=$OPTARG;;
                \?)     synopsis_show;;
        esac
done

###\\\
# Some error checking --->
###///

statusPrint "Checking on <scheduleFile>"
fileExist_check $G_SCHEDULEFILE || fatal noScheduleFile

if (( Gb_watchDir )) ; then G_watchDir=$(dirname $G_SCHEDULEFILE) ; fi

###\\\
# Main --->
###///


FILEID=${G_SELF}-$(basename $G_SCHEDULEFILE)-$(hostname)-$G_PARENTID
OLDSTATE=${G_watchDir}/${FILEID}_state0
NEXTSTATE=${G_watchDir}/${FILEID}_state1

statusPrint "Checking on <OLDSTATE>"
fileExist_check "$OLDSTATE" || OLDSTATE=/dev/null

cp "$G_SCHEDULEFILE" "$NEXTSTATE"

statusPrint     "Constructing RUNCMD"
DIFFLINES=$(diff $OLDSTATE $NEXTSTATE) #| grep \>)
RUNCMD=$(diff $OLDSTATE $NEXTSTATE                      |\
         grep \>                                        |\
         gawk -F \| 'NF > 1  {print $3}'                |\
         sed 's/ Stage //')
ret_check $?

# For each new line in NEXSTATE, determine its line number and 
# extract the command to run.  Then, execute the command using 
# cluster_run.bash
while read line; do
        # Use the line number as (or part of) a unique job ID
        LINENUMBER=$(grep -n "$line" $NEXTSTATE | gawk -F":" '{print $1}')
        CMD=$(echo $line | gawk -F \| 'NF > 1  {print $3}' | sed 's/ Stage //')        
        SUBMITCMD="cluster_run.bash -c \"$CMD\" -C ${G_CLUSTERTYPE}"
        if (( Gb_passJobID )) ; then
        	SUBMITCMD="$SUBMITCMD -J ${G_JOBIDPREFIX}${LINENUMBER}"
        fi
                
        stage_stamp "$SUBMITCMD" ${G_watchDir}/${G_LOGFILE}
        eval "$SUBMITCMD" > ${G_watchDir}/${G_LOGFILE}.std \
                          2>${G_watchDir}/${G_LOGFILE}.err
    
done < <(diff $OLDSTATE $NEXTSTATE | grep \> | xargs -i% echo % | gawk -F'>' '{print $2}')
    
if [[ $OLDSTATE != /dev/null ]] ; then
    mv $NEXTSTATE $OLDSTATE
else
    mv $NEXTSTATE ${G_watchDir}/${FILEID}_state0
fi
shut_down 0

