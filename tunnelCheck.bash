#!/bin/bash

G_PORT="-x"

G_SYNOPSIS="

NAME

	tunnelOpen.bash

SYNOPSIS

	tunnelOpen.bash -p <port>

DESCRIPTION

	'tunnelOpen.bash' is a simple script that attempts to check if 
	an ssh tunnel is open on a given port. If open, it returns a '1',
	otherwise, it returns '0'.

HISTORY

    7 September 2011
    o Initial design and coding.



Copyright 2011 Rudolph Pienaar
Children's Hospital Boston, GPL v2

"

# "include" the set of common script functions
source common.bash

A_args="checking command line arguments"

EM_args="you *must* specify a '-p <port>'."

EC_args=10


# Process command line options
while getopts hp: option ; do
        case "$option"
        in
                h)      echo "$G_SYNOPSIS"
		        shut_down 1 		;;
		p)	G_PORT=$OPTARG		;;
                \?)     echo "$G_SYNOPSIS"
                        shut_down 1 		;;
        esac
done

if [[ $G_PORT == "-x" ]] ; then fatal args ; fi

RET=$(psa $G_PORT | grep ssh  | grep $(whoami) | grep -v grep | grep ssh | wc -l)
echo $RET
exit $RET



