#!/bin/bash
#
# tunnel.bash
#
# Copyright 2011 Rudolph Pienaar
# Children's Hospital Boston
#
# SPDX-License-Identifier: MIT
#

# "include" the set of common script functions
source common.bash
source shflags

let Gi_verbose=1
G_DISPLAY="void"
G_SYNOPSIS="

 NAME

	xvfb.sh

 SYNOPSIS

        xvfb.sh         [--display <display>]                           \\
                        [--isRunning]                                   \\
                        [--verbosity <verbosity>]

 DESCRIPTION

	'xvfb.sh' intelligently checks on, and starts, if specified,
        an Xvfb on the given <display>.

        If called with the '--isRunning' option, the script will only
        check if the underlying Xvfb is active on the passed <display>,
        returing a '1' if active, '0' if not.

        If called with just the '--display <display>' option, the script
        will start a new Xvfb on the given display. If an instance of Xvfb
        is already active, it will kill that instance in favour of a new
        Xvfb.

        The script will also handle /tmp/X<display>.lock files.

 ARGUMENTS

        --display <display>
        The display to run the Xvfb on.

	--isRunning (boolean)
	If specified, does not start a new instance, but merely checks
        if an Xvfb is active on the <display>. If active, return a '1'
        otherwise return a '0'.


 NOTE

	o On Darwin hosts, need to install the 'proctools' MacPort.

 HISTORY
 21 Dec 2015
 o Initial design and coding.

"

###\\\
# Global variables --->
###///

# Actions
A_comargs="parsing the command line arguments with shflags"
A_noDisplay="checking the command line arguments"

# Error messages
EM_comargs="some error occured."
EM_noDisplay="it seems that the '--display' spec is missing or incorrect.\n\tUse --usage for more information."

# Error codes
EC_comargs=1
EC_noDisplay=10

###\\\
# function definitions --->
###///


###\\\
# Process command options --->
###///

DEFINE_string 	'display' 	$G_DISPLAY 				\
		'the <display> to use for Xvfb' 	                'd'
DEFINE_boolean	'usage'		false					\
		'show detailed usage help'				'm'
DEFINE_boolean	'x'		false					\
                'show detailed usage help'				'x'
DEFINE_boolean	'isRunning'	false					\
		'check if Xvfb is running on <display>.'                'r'
DEFINE_boolean	'kill'	          false					\
		'gracefully kill Xvfb'                                 'k'

FLAGS "$@" || fatal comargs
eval set -- "${FLAGS_ARGV}"

if [[ $FLAGS_usage == $FLAGS_TRUE || $FLAGS_x == $FLAGS_TRUE ]] ; then
    synopsis_show
    shut_down 1
fi

if [[ $FLAGS_display == "void" ]] ;             then fatal noDisplay;   fi

###\\\
# Main --->
###///
XVFB="Xvfb :${FLAGS_display}"
PID_running=$(pgrep -f "$XVFB")

# Remember "true" and "false" are inverted in shell!

if (( $FLAGS_isRunning )) ; then

    cprint	"display"	        "[ $FLAGS_display ]"

    statusPrint	"Searching for Xvfb on display..."

    if (( ${#PID_running} )) ; then
	statusPrint 	"[ running:$PID_running ]" "\n"
	statusPrint	"Stopping Xvfb..."
	echo "$PID_running" | awk '{printf("kill -9 %s\n", $1);}' | sh
	ret_check $?
    else
	statusPrint	"[ not running ]" "\n"
    fi
    if [[ -f /tmp/.X${FLAGS_display}-lock ]] ; then
            lprint "Removing legacy .X${FLAGS_display}-lock..."
            rm -f /tmp/.X${FLAGS_display}-lock
            ret_check $?
    fi
fi

if (( $FLAGS_kill && $FLAGS_isRunning )) ; then
    lprint	"Starting Xvfb..."
    $XVFB >/dev/null 2>/dev/null &
    ret_check $?
    lprint      "Xvfb running"
    ret_check $?
fi

if (( ! $FLAGS_isRunning )) ; then
    RUNNING=0
    if (( ${#PID_running} )) ; then
        RUNNING=$(echo $PID_running | wc -l)
    fi
    echo $RUNNING
    exit $RUNNING
fi

shut_down 0
