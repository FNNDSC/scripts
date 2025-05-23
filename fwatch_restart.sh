#!/bin/bash
#
# mcheck-fs_meta.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# SPDX-License-Identifier: MIT
#

# "include" the set of common script functions
source /homes/9/rudolph/arch/scripts/common.bash

let Gi_verbose=1

G_watchDir="/space/kaos/1/users/dicom/postproc/seychelles"
#G_watchList="Magnet1.txt Magnet2.txt Magnet3.txt Magnet6.txt"
G_watchList="schedule.log"
G_watchExecProc=/homes/9/rudolph/src/devel/filewatch/filewatch.tcl
G_watchExecFile=/homes/9/rudolph/arch/scripts/pbsubdiff.sh

G_synopsis="

 NAME

	fwatch_restart.sh

 SYNOPSIS

	fwatch_restart.sh	[-d <watchDir>]			\\
				[-e <watchExecProcess>]		\\
				[-f <watchExecFile>]		\\
				[-v <verbosity>]		\\
				WATCHFILE1 WATCHFILE2 ...

 DESCRIPTION

	'fwatch_restart.sh' is a rather blunt tool that when called 
	kills any tcl processes running in the background and then
	restarts all the filewatch.tcl processes for monitoring 
	changes in specific text files.

	It is really just a wrapper about 'filewatch.tcl' with some
	additional error checking.

 ARGUMENTS

	-d <watchDir> (Optional: default $G_watchDir)
	The base directory containing watch files.

	-e <watchExecProcess> (Optional: default $G_watchExecProc)
	Process that watches for changes to trigger files.

	-f <watchExecFile> (Optional: default $G_watchExecFile)
	The process that is called when any trigger events have occurred.

	-v <verbosity> (Optional: default $G_verbose)

 HISTORY
 20 May 2008
 o Cluster-based deployment
"

###\\\
# Global variables --->
###///

# Actions
A_comargs="checking command line arguments"
A_badWatchDir="checking on <watchDir>"

# Error messages
EM_nofile="I couldn't find a target file!"
EM_badWatchDir="I couldn't access the <watchDir>. Does it exist?"

# Error codes
EC_nofile=1
EC_badWatchDir=10

###\\\ 
# function definitions --->
###/// 


###\\\ 
# Process command options --->
###/// 

while getopts v:d:e: option ; do
	case "$option" 
	in
		v)	let Gi_verbose=$OPTARG	;;
		d)	G_watchDir=$OPTARG	;;
		e)	G_watchExecProc=$OPTARG	;;
		f)	G_watchExecFile=$OPTARG	;;
		\?) 	synopsis_show
			exit 0			;;
	esac
done
verbosity_check

###\\\
# Some error checking --->
###///

statusPrint	"Checking on <watchDir>"
dirExist_check $G_watchDir || fatal badWatchDir

REQUIREDFILES="$G_watchExecProc $G_watchExecFile"
for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file..."
        file_checkOnPath $file || fatal fileCheck
done

###\\\
# Main --->
###///

shift $(($OPTIND - 1))
G_watchList=$*

topDir=$(pwd)
for FILE in $G_watchList ; do
	statusPrint	"Searching for monitor on $FILE..."
	b_RUNNING=$(ps -Af | grep $FILE | grep -v grep | grep -v $G_SELF | wc -l)
	if (( b_RUNNING )) ; then
		statusPrint 	"[ running ]" "\n"
		statusPrint	"Stopping monitor..."
		process_kill $FILE
		ret_check $?
	else
		statusPrint	"[ not running ]" "\n"
	fi
	statusPrint	"Starting monitor..."
# 	cd $(dirname $G_watchExecProc)
	cd $G_watchDir
	nohup $G_watchExecProc --tmp $G_watchDir --verbose --interval 60 --file $G_watchDir/$FILE --optargs -f__#file__-c__%pid --execute $G_watchExecFile&
	ret_check $?
done

shut_down 0

