#!/bin/bash
# NAME
#
#	tping.sh
#
# SYNOPSIS
#
#	tping.sh [-i <pauseInterval>] [-c <count>] <-h host>
#
# DESCRIPTION
#
#	`tping.sh' pings a host with a set of count pings, waiting pauseInterval
#	seconds between sets.
#
# HISTORY
# -------
#
# 7-15-1998
# o	Initial design and coding

# /\/\/\/\/\/\/\/\
# Global variables
# \/\/\/\/\/\/\/\/
SELF=`basename $0`
Interval=300
Count=5
Host=gate

# /\/\/\/\/\/\/\/\/\/\
# function definitions
# \/\/\/\/\/\/\/\/\/\/

function shut_down
# $1: Exit code
{
	echo -e "$SELF:\n\tShutting down with code $1.\n" 
	exit $1
}

function show_synopsis
{
	echo "USAGE:"
	echo -e "\t$SELF [-i <pauseInterval>] [-c <count>] <-h host>"
	shut_down 0
}

function error
# $1: Action
# $2: Error string
# $3: Exit code
{
        echo "$SELF:\n\tSorry, but there seems to be an error."	>&2 
        echo "\tWhile $1," 					>&2
        echo "\t$2\n" 						>&2
        shut_down $3
}


# /\/\/\/\/\/\/\/\/\/\/\/
# Process command options
# \/\/\/\/\/\/\/\/\/\/\/\

while getopts i:c:h: option ; do
	case "$option" 
	in
		i)	Interval=$OPTARG
			;;
		c)	Count=$OPTARG
			;;
		h)	Host=$OPTARG
			;;
		\?) 	show_synopsis;;
	esac
done

# /\/\
# main
# \/\/

while [ 1 = 1 ] ; 
do
	echo "Pinging $Host at `date`..."
	ping -c $Count $Host 
	echo -e "Sleeping for $Interval...\n"
	sleep $Interval
done

shut_down 0

