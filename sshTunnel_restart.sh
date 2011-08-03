#!/bin/bash
#
# ssh_restart.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# GPL v2
#

# "include" the set of common script functions
source ~/arch/scripts/common.bash

let Gi_verbose=1
let G_REMOTEPORT=8888
let G_LOCALPORT=22

let Gb_direction=0
let Gb_remoteConnect=0

G_HOST=osx1927.tch.harvard.edu
G_REMOTEHOST=dreev.tch.harvard.edu
G_REMOTEUSER=ch137123

G_SYNOPSIS="

 NAME

	sshTunnel_restart.sh

 SYNOPSIS

	sshTunnel_restart.sh	[-R <remotePort>]		\\
				[-H <host>]			\\
				[-L <localPort>]		\\
				[-u <remoteUser>]		\\
				[-h <remoteHost>]		\\
				[-F] | [-B]			\\
				[-v <verbosity>]		\\
				[-g]
	
 DESCRIPTION

	'sshTunnel_restart.sh' is a rather blunt tool that when called 
	kills any ssh processes that has either <remotePort> or
	<localPort> open, and then creates tunnel according to:

	    ssh -X -R <remotePort>:<host>:<localPort> <user>@<remoteHost>

	or, if '-F' is specified:
	
	    ssh -X -L <localPort>:<host>:<remotePort> <user>@<remoteHost>

 ARGUMENTS

	-R <remotePort> (Optional: default $G_REMOTEPORT)
	The remote endpoint port of the tunnel to <host>.

	-H <host> (Optional: default $G_HOST)
	The host to tunnel to.

	-L <localPort> (Optional: default $G_LOCALPORT)
	The local endpoint port of the tunnel on <host>.

	-u <remoteUser> (Optional: default $G_REMOTEUSER)
	The user credential on the <remoteHost>.

	-h <remoteHost> (Optional: default $G_REMOTEHOST)
	The remote host that carries the remote tunnel
	endpoint.

	-F or -B (Optional: default -B)
	Specify the direction of the tunnel. The default is '-B',
	i.e. a reverse (or back) tunnel. To specify a forward 
	tunnel, use -F.

	-v <verbosity> (Optional: default $G_verbose)

	-g (Optional)
	If specified, the '-g' option will be passed to ssh 
	which allows remote hosts to connect to local
	forwarded ports.

 HISTORY
 26 May 2009
 o Initial design and coding.
 
"

###\\\
# Global variables --->
###///

# Actions
A_comargs="checking command line arguments"

# Error messages
A_comargs="I couldn't find a required parameter!"

# Error codes
EC_comargs=1

###\\\ 
# function definitions --->
###/// 


###\\\ 
# Process command options --->
###/// 

while getopts v:R:H:L:h:u:FBg option ; do
	case "$option" 
	in
		v)	let Gi_verbose=$OPTARG	;;
		R)	G_REMOTEPORT=$OPTARG	;;
		H)	G_HOST=$OPTARG		;;
		L)	G_LOCALPORT=$OPTARG	;;
		u)	G_REMOTEUSER=$OPTARG	;;
		h)	G_REMOTEHOST=$OPTARG	;;
		F)	let Gb_direction=1	;;
		B)	let Gb_direction=0	;;
		g)	let Gb_remoteConnect=1	;;
		\?) 	synopsis_show
			exit 0			;;
	esac
done
verbosity_check

###\\\
# Some error checking --->
###///

cprint	"remote port"	"[ $G_REMOTEPORT ]"
cprint 	"host"		"[ $G_HOST ]"
cprint 	"local port"	"[ $G_LOCALPORT ]"
cprint	"remote host"	"[ $G_REMOTEHOST ]"
cprint	"remote user"	"[ $G_REMOTEUSER ]"

###\\\
# Main --->
###///

statusPrint	"Searching for monitor on ports..."

b_RUNNING=$(psa $G_REMOTEPORT 			 | grep $G_LOCALPORT 	|\
			 grep -v grep | grep ssh | grep -v $G_SELF 	|\
			 wc -l)
if (( b_RUNNING )) ; then
	statusPrint 	"[ running ]" "\n"
	statusPrint	"Stopping monitor..."
	process_kill $G_REMOTEPORT
	ret_check $?
else
	statusPrint	"[ not running ]" "\n"
fi
lprint	"Starting monitor..."

SSH_ARGS=""
if (( Gb_remoteConnect )) ; then
	SSH_ARGS="-g"
fi

if (( Gb_direction )) ; then
  SSH="ssh ${SSH_ARGS} -f -N -X -L ${G_LOCALPORT}:${G_HOST}:${G_REMOTEPORT} ${G_REMOTEUSER}@${G_REMOTEHOST}"
else
  SSH="ssh ${SSH_ARGS} -f -N -X -R ${G_REMOTEPORT}:${G_HOST}:${G_LOCALPORT} ${G_REMOTEUSER}@${G_REMOTEHOST}"
fi

echo "$SSH"
exec $SSH

shut_down 0

