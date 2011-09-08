#!/bin/bash
#
# tunnel.bash
#
# Copyright 2011 Rudolph Pienaar
# Children's Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash
source shflags

let Gi_verbose=1

G_FROM="unspecified"
G_TO="unspecified"
G_VIA="unspecified"
G_DIRECTION="unspecified"
G_REMOTEUSER="unspecified"
G_SSHARGS=" "

G_SYNOPSIS="

 NAME

	tunnel.bash

 SYNOPSIS

	tunnel.bash 	[--reverse] --from [[<user>@]<fromHost>:]<fromPort> \\
			--to <toHost>:<toPort>			  	  \\
			[--forward --via <user>@<intermediateHost>]	  \\
			[--sshArgs <sshArgs>]				  \\
			[--verbosity <verbosity>]			  \\
			[--usage]			
	
 DESCRIPTION

	'tunnel.bash' creates an ssh tunnel as specified in its command
	line options. The meanings of <from> and <to> as relates to 
	concepts of local and remote depend on the direction of the
	tunnel.

	For a *reverse* tunnel, the '--from' spec should start with a
	'<user>@' since the 'from' host acts as the intermediary. For
	a *forward* tunnel, the '--via' flag is required to specify
	the intermediary between this host and the remote host.

	Forward tunnels do not require (and in fact ignore) the 'fromHost'
	specifier, assuming all forward tunnels start from 'localhost'.

	When called, the script kills any existing ssh processes that conforms
	to the tunnel spec, and then creates a new tunnel according to:

	reverse tunnel:
	    ssh -g -f -N -X -R <fromPort>:<toHost>:<toPort> <user>@<fromHost>

	forward tunnel:
	
	    ssh -g -f -N -X -L <fromPort>:<toHost>:<toPort> <user>@<intermediateHost>

	The actual ssh tunnel string spec is returned by this script on stderr.

 ARGUMENTS

	--from [<user>]@<fromHost>:<fromPort>
	The host and port specifiers 'from' which a tunnel is made. If the
	tunnel is a reverse tunnel, then the [<user>@] spec is also required.

	--to <toHost>:<toPort>
	The host and port specifiers 'to' which a tunnel is opened.

	--via <userName>@<intermediateHost>
	The intermediate host and user id through which a forward tunnel is 
	routed.

	--forward || --reverse
	The direction information flows in the tunnel.

	--sshArgs <sshArgs>
	Any additional args to pass to the underlying ssh process.

	--usage (boolean)
	If specified, show this help page.

 HISTORY
 26 May 2009
 o Initial design and coding.

 07 September 2011
 o Updating / revamping 
 
"

###\\\
# Global variables --->
###///

# Actions
A_comargs="parsing the command line arguments with shflags"
A_noFrom="checking the command line arguments"
A_badFrom="checking the '--from' spec"
A_noTo="checking the command line arguments"
A_badTo="checking the '--to' spec"
A_noDirection="checking the command line arguments"
A_noUser="checking the command line arguments"

# Error messages
EM_comargs="some error occured"
EM_noFrom="it seems that the '--from' spec is missing or incorrect.\n\tUse --usage for more information."
EM_badFrom="the --from spec cannot be 'localhost' for reverse tunnels."
EM_noTo="it seems that the '--to' spec is missing or incorrect.\n\tUse --usagep for more information."
EM_badTo="you need to specify a <host>:<port>, i.e. shaka:22."
EM_noDirection="it seems that the direction spec is missing or incorrect.\n\tUse --usage for more information."
EM_noVia="it seems that the '--via' spec which is required for forward tunnels is missing or incorrect.\n\tUse --help for more information."

# Error codes
EC_comargs=1
EC_noFrom=10
EC_noTo=20
EC_badTo=21
EC_noDirection=30
EC_noVia=40

###\\\ 
# function definitions --->
###/// 


###\\\ 
# Process command options --->
###/// 

DEFINE_string 	'from' 		$G_FROM 				\
		'the <from> tunnel endpoint, in form <host>:<port>' 	'f'
DEFINE_string 	'to'		$G_TO 					\
		'the <to> tunnel endpoint, in form <host>:<port>' 	't'
DEFINE_string	'asUser'	$G_USER					\
		'the user name on the nexus host'			'u'
DEFINE_boolean	'usage'		false					\
		'show detailed usage help'				'm'
DEFINE_boolean	'forward'	false					\
		'create a forward tunnel'				'F'
DEFINE_boolean	'reverse'	false					\
		'create a reverse tunnel'				'R'
DEFINE_string	'sshArgs'	"$G_SSHARGS"				\
		'additional args to the underlying ssh process'		'a'
DEFINE_string	'via'		$G_VIA					\
		'intermediate host connection spec'			'v'

FLAGS "$@" || fatal comargs
eval set -- "${FLAGS_ARGV}"

if [[ $FLAGS_usage == $FLAGS_TRUE ]] ; then
    synopsis_show
    shut_down 1
fi

if (( $FLAGS_forward && $FLAGS_reverse )) ; 	then fatal noDirection;	fi

if [[ $FLAGS_from == "unspecified" ]] ; 	then fatal noFrom; 	fi
if [[ $FLAGS_to == "unspecified" ]] ; 		then fatal noTo; 	fi

FROMHOST=$(echo $FLAGS_from | awk -F \: '{print $1}')
FROMPORT=$(echo $FLAGS_from | awk -F \: '{print $2}')
if (( ! ${#FROMPORT} )) ; then
    # The $FLAGS_from string does not contain a ':'. Assume
    # that the string denotes only a FROMPORT
    FROMPORT=$FROMHOST
    FROMHOST=localhost
fi

TOHOST=$(echo $FLAGS_to | awk -F \: '{print $1}')
TOPORT=$(echo $FLAGS_to | awk -F \: '{print $2}')
if (( ! ${#TOPORT} )) ; 			then fatal badTo; 	fi

if (( ! $FLAGS_forward )) ; then 
    if [[ $FLAGS_via == "unspecified" ]] ; 	then fatal noVia; 	fi
    G_VIA=$FLAGS_via
    DIRECTION=forward
    SSHDIR="-L"
fi
if (( ! $FLAGS_reverse )) ; then 
    G_VIA=$FROMHOST
    if [[ $G_VIA == 'localhost' ]] ; 		then fatal badFrom;	fi
    FROMHOST=$(echo $FROMHOST | awk -F \@ '{print $2}')
    DIRECTION=reverse
    SSHDIR="-R"
fi

###\\\
# Main --->
###///

cprint	"tunnel direction"	"[ $DIRECTION ]"
cprint 	"from host"		"[ $FROMHOST ]"
cprint 	"from port"		"[ $FROMPORT ]"
cprint 	"to host"		"[ $TOHOST ]"
cprint 	"to port"		"[ $TOPORT ]"
cprint  "via"			"[ $G_VIA ]"
cprint "sshArgs"		"[ $FLAGS_sshArgs ]"

statusPrint	"Searching for monitor on ports..."

PID_running=$(psa $FROMPORT 			 | grep $TOPORT 	|\
			 grep -v grep | grep ssh | grep -v $G_SELF 	|\
			awk '{print $2}')

if (( ${#PID_running} )) ; then
	statusPrint 	"[ running:$PID_running ]" "\n"
	statusPrint	"Stopping monitor..."
	echo "$PID_running" | awk '{printf("kill -9 %s\n", $1);}' | sh
	ret_check $?
else
	statusPrint	"[ not running ]" "\n"
fi
lprint	"Starting monitor..."

SSH="ssh ${FLAGS_sshArgs} -g -f -N -X $SSHDIR ${FROMPORT}:${TOHOST}:${TOPORT} $G_VIA"

$SSH >/dev/null 2>/dev/null
ret_check $?

echo "$SSH" 1>&2

shut_down 0

