#!/bin/bash


# "include" the set of common script functions
source common.bash

G_STAGES="1"

G_SYNOPSIS="
  
  NAME

  	staleNFS_fix.sh -t <stages> <hungFileSysRegex>

  DESC

  	'staleNFS_fix.sh' is a simple script that attempts to flush
  	stale file handles from the system. Typically these occur if
  	a NFS location has been changed, or the remote host is not
  	online. 

  	Two levels of 'fixes' are available. A more benign first 
  	attempt that uses lsof to find any open files on the passed
  	filesystems, and tries to kill them. A more aggressive fix
  	attempts to find any users with a working directory on the
  	hung filesystem. If found, that process is killed.

  STAGES

  	Typical workflow is to only run stage 1. If that doesn't
  	work, run stage 2.

  	1 - lsof 
  		This stage attempts to find any processes with
  		files open on the partition and then kills those
  		files.
  	2 - user wd
  		This stage attempts to find any users with current
  		working directories on the hung filesystem and
  		if found, kills them.

  ARGS

  	-t <stages>
  	The stages to run. In this case, either '1' or '2'.

  	<hungFileSysRegex>
  	An egrep friendly regex that defines the filesystems that 
  	are stale.

  ACKNOWLEDGEMENTS

  	o http://joelinoff.com/blog/?p=356

  EXAMPLE

  	o staleNFS_fix.sh -v 1 \"/neuro|/net/fnndsc\"
  	This will search for any hung processes accessing any dirs in
  	either the '/neuro' or '/net/fnndsc' trees.

"

G_SELF=`basename $0`
G_PID=$$

A_noFS="checking command line options"
A_fileCheck="checking for a required file dependency"

EM_noFS="I couldn't find a filesystem specifier. Did you forget?"
EM_fileCheck="it seems that a dependency is missing."

EC_noFS=10
EC_fileCheck=1


while getopts v:t: option ; do
        case "$option"
        in
        	t) G_STAGES=$OPTARG		;;
                v) let Gi_verbose=$OPTARG       ;;
                \?) synopsis_show
                    exit 0;;
        esac
done

shift $(($OPTIND - 1))
STALEMOUNTS=$*
b_STALEMOUNTS=$(echo $STALEMOUNTS | wc -w)

if (( ! b_STALEMOUNTS )) ; then fatal noFS ; fi

## Check on script preconditions
REQUIREDFILES="common.bash egrep pgrep awk"       

for file in $REQUIREDFILES ; do
    lprint "Checking for $file"
    file_checkOnPath $file || fatal fileCheck
done


## Check which stages to process
statusPrint     "Checking which stages to process"
barr_stage=([1]=0 [2]=0)
for i in $(seq 1 3) ; do
        b_test=$(expr index $G_STAGES "$i")
        if (( b_test )) ; then b_flag="1" ; else b_flag="0" ; fi
        barr_stage[$i]=$b_flag
done
ret_check $?


if (( ${barr_stage[1]} )) ; then
	LSOF="kill -9 \$(lsof 		|\
	    egrep '$STALEMOUNTS'	|\
	    awk '{print \$2;}' 		|\
	    sort -fu )"

	echo $LSOF | sh -v

	statusPrint "Stopping autofs and waiting for 5 secs"
	service autofs stop
	sleep 5
	statusPrint "Restarting autofs"
	service autofs start
fi

if (( ${barr_stage[2]} )) ; then
	UCWD="  for u in $( who | awk '{print $1;}' | sort -fu ) ; do \
    			kill -9 $(pgrep -u $u) |\
    			awk -F: '{print $1;}' ; \
		done"

	echo $UCWD | sh -v 

	statusPrint "Stopping autofs and waiting for 5 secs"
	service autofs stop
	sleep 5
	statusPrint "Restarting autofs"
	service autofs start
fi



