#!/bin/bash
#
# mcheck-ssh-crystal.bash
#
# Copyright 2010-2024 Rudolph Pienaar
# Children's Hospital Boston
#
# SPDX-License-Identifier: MIT
#

# "include" the set of common script functions
source common.bash

G_REPORTLOG=/tmp/${G_SELF}.reportLog.$G_PID
G_ADMINUSERS=rudolph.pienaar@childrens.harvard.edu

declare -i targetList
declare -i tunnelCount
declare -a TARGET_CHECK
declare -a TARGETACTION
declare -i b_forward=0
declare -i b_reverse=0
G_SYNOPSIS="

 NAME

       mcheckDSC.bash

 SYNOPSIS

       mcheckDSC.bash [-r|-f] [-c <CMD>]

 ARGS

    [-f]
    Perform a set of 'forward' connections.

    [-r]
    Perform a set of 'reverse' connections.

    [-c <CMD>]
    Check/restart the <CMD>.

 DESCRIPTION

    'mcheckDSC.sh' is used to check that certain script-defined conditions
    are true. If any of these conditions are false, it executes a set of
    corrective actions.

    It should typically be called from a cron process, and this particular
    version of 'mcheck' is tailored to monitoring ssh tunnels between this
    host and remote hosts.

    Additionally, this incarnation of 'mcheck' contains both the _forward_
    and _reverse_ web connection. The choice of which to us is controlled
    by the [-r|-f] flags.

 PRECONDITIONS

    o   Conditions to check are defined in the script code itself. These
        are specified in two arrays: the first describing (per condition)
        the command to check; the second describing (per condition) whatever
        corrective action to run should the check command be false.
    o   Conditions to check should be described in such a manner that, should
        the condition be false, the check command returns zero (0).

 POSTCONDITIONS

    o The corrective action (per condition) is executed if the check condition
      returns false (0).

 HISTORY
 24 April 2014
  o Adpated from mcheck-ssh-dreev.bash and opens reverse --sshArgs '-p 22022'
    tunnels directly to 'door.nmr.mgh.harvard.edu.

 07 December 2017
  o Added 'crystal' changes.

 03 January 2024
  o Revamp and update.

"

###\\\
# Global variables
###///

# Actions
A_badRestart="attempting a corrective action"
A_fileCheck="checking for a required file dependency"

# Error messages
EM_badRestart="the corrective action failed. Perhaps a target process failed?"
EM_fileCheck="it seems that a dependency is missing."

# Error codes
EC_badRestart=10
EC_fileCheck=1

GATE=10.0.0.180
H1=73.238.37.110
verbosity_check
REQUIREDFILES="common.bash tunnel.bash pgrep"

for file in $REQUIREDFILES ; do
    file_checkOnPath $file >/dev/null || fatal fileCheck
done


declare -i logCall=0
function log
{
    LOG=$*
    if ((!logCall)); then
        echo "$LOG" > /tmp/log.txt
        ((logCall++))
    else
        echo "$LOG" >> /tmp/log.txt
    fi
}
function reverseTunnelCmd
{
    fromHostPort=$1
    toHostPort=$2

    echo "tunnel.bash --reverse --sshArgs '-p 7778' --from $fromHostPort --to $toHostPort"
}

function forwardTunnelCmd
{
    fromPort=$1
    viaHost=$2
    toHostPort=$3
    sshArgs=$4

    if [[ -z "$sshArgs" ]] ; then
        sshArgs="-p 7778"
    else
        sshArgs="-p $sshArgs"
    fi
    echo "tunnel.bash --forward --sshArgs '"$sshArgs"' --from $fromPort --via $viaHost --to $toHostPort"
}

let tunnelCount=0
function monitorCmd
{
    CMD="$1"
    TARGET_CHECK[$tunnelCount]="$CMD"
    TARGETACTION[$tunnelCount]="$CMD"
    ((tunnelCount++))
}

function reverseTunnel_bore
{
    fromHostPort=$1
    toHostPort=$2
    TARGET_CHECK[$tunnelCount]="$(reverseTunnelCmd $fromHostPort $toHostPort) --isRunning"
    TARGETACTION[$tunnelCount]="$(reverseTunnelCmd $fromHostPort $toHostPort)"
    ((tunnelCount++))
}

function forwardTunnel_bore
{
    fromPort=$1
    viaHost=$2
    toHostPort=$3
    sshArgs=$4
    TARGET_CHECK[$tunnelCount]="$(forwardTunnelCmd $fromPort $viaHost $toHostPort $sshArgs) --isRunning"
    TARGETACTION[$tunnelCount]="$(forwardTunnelCmd $fromPort $viaHost $toHostPort $sshArgs)"
    ((tunnelCount++))
}
FROMWAYPOINT=rudolphpienaar@${GATE}
HOMEWAYPOINT=rudolphpienaar@${H1}
function fromPort
{
    port=$1
    echo "$FROMWAYPOINT:$port"
}

function viaCrystalPort
{
    port=$1
    echo "$port $FROMWAYPOINT"
}

function viaHomePort
{
    port=$1
    echo "$port $HOMEWAYPOINT"
}

function toGalena
{
    port=$1
    echo "$(fromPort $port) galena.tch.harvard.edu:$port"
}

function sshInto
{
    host=$1
    echo "${host}:22"
}

function toLocal
{
    hostPort=$1
    echo "localhost:$hostPort"
}

function reverseWeb_create
{
    reverseTunnel_bore $(fromPort 4216) $(sshInto pangea)
    reverseTunnel_bore $(fromPort 4217) $(sshInto rodinia)
    reverseTunnel_bore $(fromPort 4218) $(sshInto centurion)
    reverseTunnel_bore $(fromPort 4219) $(sshInto olympus)
    reverseTunnel_bore $(fromPort 4220) $(sshInto titan)
    reverseTunnel_bore $(toGalena 30104)
    reverseTunnel_bore $(toGalena 30031)
    reverseTunnel_bore $(toGalena 30101)
    forwardTunnel_bore $(viaHomePort 6812) $(sshInto localhost) 7778
    forwardTunnel_bore $(viaHomePort 6813) $(sshInto 192.168.1.200) 7778
}

function forwardWeb_create
{
    forwardTunnel_bore $(viaCrystalPort 4216) $(toLocal 4216)
    forwardTunnel_bore $(viaCrystalPort 4217) $(toLocal 4217)
    forwardTunnel_bore $(viaCrystalPort 4218) $(toLocal 4218)
    forwardTunnel_bore $(viaCrystalPort 4219) $(toLocal 4219)
    forwardTunnel_bore $(viaCrystalPort 4220) $(toLocal 4220)
    forwardTunnel_bore $(viaCrystalPort 30104) $(toLocal 30104)
    forwardTunnel_bore $(viaCrystalPort 30031) $(toLocal 30031)
    forwardTunnel_bore $(viaCrystalPort 30101) $(toLocal 30101)
}

# Process command line options
CMD=""
while getopts frhv:c: option ; do
    case "$option"
    in
        r)  b_reverse=1             ;;
        f)  b_forward=1             ;;
        c)  CMD="$OPTARG"       ;;
        v)  let Gi_verbose=$OPTARG  ;;
        h)  echo "$G_SYNOPSIS"
            shut_down 1             ;;
        \?) echo "$G_SYNOPSIS"
            shut_down 1             ;;
    esac
done

if ((b_reverse)) ; then
    reverseWeb_create
fi
if ((b_forward)) ; then
    forwardWeb_create
fi
if [[ ! -z "$CMD" ]] ; then
    monitorCmd "$CMD"
fi
rm -f $G_REPORTLOG
b_logGenerate=0
echo $TARGET_CHECK
for i in $(seq 0 $(expr $tunnelCount - 1)) ; do
    echo ${TARGET_CHECK[$i]}
    result=$(eval ${TARGET_CHECK[$i]})
    if (( result == 0 )) ; then
        lprintn "Restarting target action..."
        eval "${TARGETACTION[$i]} "
        ret_check $? || fatal badRestart
        TARGETRESTARTED="$TARGETRESTARTED $i"
        b_logGenerate=1
    fi
done

for i in $TARGETRESTARTED ; do
        echo ""
        echo -e "Failed:\t\t${TARGET_CHECK[$i]}"        >> $G_REPORTLOG
        echo -e "Executed:\t${TARGETACTION[$i]}"        >> $G_REPORTLOG
        echo ""
done

messageFile=/tmp/$SELF.message.$PID
if [ "$b_logGenerate" -eq "1" ] ; then
        message="

    $SELF

    Some of the events I am monitoring signalled a FAILED condition
    The events and the corrective action I implemented are:

$(cat $G_REPORTLOG)

        "
    echo "$message" > $messageFile
    mail -s "Failed conditions restarted" $G_ADMINUSERS < $messageFile
fi

if [[ -f $messageFile ]] ; then
    rm -f $messageFile 2>/dev/null
fi

# This is commented out otherwise cron noise becomes unbearable
#shut_down 0
