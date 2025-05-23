#!/bin/bash
#
# osx_useradd.bash
#
# Copyright 2009 Rudolph Pienaar
# Childrens Hospital Boston
#
# SPDX-License-Identifier: MIT
#

# "include" the set of common script functions
source common.bash

declare -i Gi_verbose=0
declare -i Gb_createGroup=0

G_USERNAME="-x"
G_UID="-x"
G_REALNAME="-x"
G_GROUPNAME="-x"
G_GID="-x"
G_HOMEDIR="-x"
G_SHELL=/bin/bash

G_SYNOPSIS="

 NAME

	osx_groupadd.bash

 SYNOPSIS

	osx_groupadd.bash	-U <userName>				\\
				-G <groupName>				\\
				[-g <gid>]				\\
				[-v <verbosity>]

 DESCRIPTION

	'osx_useradd.bash' adds <userName> to <groupName>. If the <groupName>
	doesn't exist, pass a -g <gid> to create the group with <gid> and
	<groupName>.

 ARGUMENTS

	-v <level> (Optional)
	Verbosity level. A value of '10' is a good choice here.

	-U <userName> (Required)
	The login (unix) name.
	
	-G <groupName> (Required)
	Assign user to group <groupName>.

	-g <gid> (Optional)
	If specified, create group <groupName> and assign gid <gid>.

 PRECONDITIONS

	o None	

 POSTCONDITIONS

        o A user with uid:gid as specified is created.
        o User password is *not* set by this script.

 HISTORY

	15 May 2009
	o Initial design and coding.
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///


# Actions
A_nouserNameArg="checking on -U <userName> argument"
A_nouidArg="checking on -u <uid> argument"
A_norealNameArg="checking on -R <realName> argument"
A_nogidArg="checking on -g <gid> argument"
A_nogroupNameArg="checking on the -G <groupName> arg"
A_userName="creating the specified <userName>"
A_uid="creating the specified <uid>"
A_realName="creating the specified <realName>"
A_gid="assigning the specified <gid>"
A_groupName="creating the specified <groupName>"
A_homeDir="creating the specified <homeDir>"
A_shell="checking on the <shell>"
A_append="appending the <userName> to <groupName>"

# Error messages
EM_nouserNameArg="you *must* specify a login name for this user."
EM_nouidArg="you *must* specify a <uid> for this user."
EM_norealNameArg="you *must* specify a real name for this user."
EM_nogidArg="you *must* specify a <gid> for this user to belong to."
EM_nogroupNameArg="you *must* specify a <groupName> for this user."
EM_userName="some error was detected."
EM_uid="some error was detected."
EM_realName="some error was detected."
EM_gid="some error was detected."
EM_groupName="some error was detected."
EM_homeDir="some error was detected."
EM_shell="I couldn't seem to find the specified shell."
EM_append="some error was detected."

# Error codes
EC_nouserNameArg="10"
EC_nouidArg="11"
EC_norealNameArg="12"
EC_nogidArg="13"
EC_nogroupNameArg="14"
EC_userName="21"
EC_uid="22"
EC_realName="23"
EC_gid="24"
EC_groupName="25"
EC_homeDir="26"
EC_shell="27"
EC_append="30"

# Defaults
D_whatever=

###\\\
# Function definitions
###///

###\\\
# Process command options
###///

while getopts U:G:g:v: option ; do
	case "$option"
	in
		v)	Gi_verbose=$OPTARG	;;
		U)	G_USERNAME=$OPTARG	;;
		g)	G_GID=$OPTARG		;;
		G)	G_GROUPNAME=$OPTARG	;;
		\?) synopsis_show
		    exit 0;;
	esac
done

verbosity_check

echo ""
cprint  "hostname"      "[ $(hostname) ]"

## Check on script preconditions
REQUIREDFILES="dscl"

for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file"
        file_checkOnPath $file || fatal fileCheck
done

if [[ $G_USERNAME 	== "-x" ]] ; then fatal nouserNameArg; 		fi
if [[ $G_GID 		!= "-x" ]] ; then let Gb_createGroup=1;		fi
if [[ $G_GROUPNAME 	== "-x" ]] ; then fatal nogroupNameArg;		fi

if (( Gb_createGroup )) ; then 
  lprint "Create new groupName $G_GROUPNAME" ; 
  dscl . create /groups/$G_GROUPNAME name 	$G_GROUPNAME 	2>/dev/null 
  ret_check $? || fatal groupName
  lprint "Create new gid $G_GROUPNAME" ; 
  dscl . create /groups/$G_GROUPNAME gid 	$G_GID		2>/dev/null
  ret_check $? || fatal gid
fi

lprint "Append the user to group $G_GROUPNAME"
dscl . -append /Groups/$G_GROUPNAME GroupMembership $G_USERNAME		2>/dev/null
ret_check $? || fatal append

printf "\n\n%40s" "Cleaning up"
ret_check $?
shut_down 0
