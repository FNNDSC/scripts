#!/bin/bash
#
# Copyright 2010 Rudolph Pienaar, Dan Ginsburg, FNNDSC
# Childrens Hospital Boston
#
# SPDX-License-Identifier: MIT
#

# "include" the set of common script functions
source common.bash
declare -i Gi_verbose=0
declare -i Gb_getOnly=0

G_HOST="-x"

G_SYNPOSIS="

  NAME

        ubuntu_packageSynch.bash

  SYNOPSIS
  
        ubuntu_packageSynch.bash -h <remoteHost> [-g] [-v <verbosityLevel>]

  DESC

        'ubuntu_packageSynch.bash' is rather simple script that attempts
        to synchronize package states between the current machine and
        <remoteHost>.

        It essentially queries the <remoteHost> for its current package
        state, and then sets its own selection state to be the same.
        
        Finally, it runs apt-get on the package list.

  ARGS

        -h <remoteHost>
        The remote host to synchronize against.
        
        -g (Optional)
        If specified, perform a get-only. This queries the remote host
        for its package state, but does not synchronize the current machine.
        Useful mainly for debugging.
        
	-v <verbosityLevel> (Optional)
	Verbosity level. A value of '10' is a good choice here.
        
  HISTORY
    
  20 April 2011
  o Initial design and coding.

"

A_args="checking command line arguments"
A_packages="collecting package info from remote host"
A_release="checking release versions"

EM_args="you *must* specify a '-h <remoteHost>'."
EM_packages="I was not able to successfully collect the package state."
EM_release="the remote host and this host are not the same Ubuntu release."

EC_args=10
EC_packages=11
EC_release=12

while getopts h:gv: option ; do
    case "$option" 
    in
        v) Gi_verbose=$OPTARG   ;;
        h) G_HOST=$OPTARG       ;;
        g) Gb_getOnly=1         ;;
    esac
done

if [[ $G_HOST   == "-x" ]] ; then fatal args;   fi

REMOTESTATEFILE=/tmp/${G_SELF}_${G_PID}_${G_HOST}.pkg

lprint "Local release info"
LOCALRELEASE=$(cat /etc/issue)
rprint "[ $LOCALRELEASE ]"

lprint "Remote release info"
REMOTERELEASE=$(ssh $G_HOST cat /etc/issue)
rprint "[ $REMOTERELEASE ]"

lprint "Local and remote release"
if [[ "$LOCALRELEASE" == "$REMOTERELEASE" ]]  ; then
        rprint "[ ok ]"
else
        fatal release
fi

lprint "Querying remote host for package data..."
REMOTESELECTIONS=$(ssh $G_HOST dpkg --get-selections)
ret_check $? || fatal packages


echo "$REMOTESELECTIONS" > $REMOTESTATEFILE

if (( ! Gb_getOnly )) ; then
    echo 
    sudo dpkg --set-selections < $REMOTESTATEFILE
    sudo apt-get -u dselect-upgrade
fi

rm $REMOTESTATEFILE



