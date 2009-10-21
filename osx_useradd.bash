#!/bin/bash
#
# osx_useradd.bash
#
# Copyright 2009 Rudolph Pienaar
# Childrens Hospital Boston
#
# GPL v2
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

	osx_useradd.bash

 SYNOPSIS

	osx_useradd.bash	-U <userName>				\\
				-u <uid>				\\
				-R <realName>				\\
				-g <gid>				\\
				[-G <groupName>]			\\
				[-S <shell>]				\\
				[-h <homeDir>]

 DESCRIPTION

	'osx_useradd.bash' adds a user with passed group membership to
	the system.

 ARGUMENTS

	-v <level> (Optional)
	Verbosity level. A value of '10' is a good choice here.

	-U <userName> (Required)
	The login (unix) name.

	-u <uid> (Required)
	The user's uid.

	-R <realName> (Required)
	The full (human) name.
	
	-g <gid> (Required)
	Assign the <userName> to <gid>.

	-G <groupName> (Optional)
	If specified, first create group <groupName> and assign it <gid>.
	Useful if <userName> is to belong to new <groupName>.
	
	-S <shell> (Optional)
	Assign <shell> to user.
	
	-h <homeDir> (Optional)
	If specified, create and set user home directory, otherwise
	default to /Users/<userName>.

 PRECONDITIONS

	o None	

 POSTCONDITIONS

        o A user with uid:gid as specified is created.
        o User password is *not* set by this script.

  SEE ALSO
  
	o osx_groupadd

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

# Defaults
D_whatever=

###\\\
# Function definitions
###///

###\\\
# Process command options
###///

while getopts U:u:R:G:g:S:h:v: option ; do
	case "$option"
	in
		v)	Gi_verbose=$OPTARG	;;
		U)	G_USERNAME=$OPTARG	;;
		u)	G_UID=$OPTARG		;;
		R)	G_REALNAME=$OPTARG	;;
		g)	G_GID=$OPTARG		;;
		G)	G_GROUPNAME=$OPTARG	;;
		S)	G_SHELL=$OPTARG		;;
		h)	G_HOMEDIR=$OPTARG	;;
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
if [[ $G_UID 		== "-x" ]] ; then fatal nouidArg;		fi
if [[ $G_REALNAME 	== "-x" ]] ; then fatal norealNameArg;		fi
if [[ $G_GID 		== "-x" ]] ; then fatal nogroupNameArg;		fi
if [[ $G_GROUPNAME 	!= "-x" ]] ; then let Gb_createGroup=1;		fi
if [[ $G_HOMEDIR 	== "-x" ]] ; then G_HOMEDIR="/Users/$G_USERNAME";fi

# cat <<EOM
# 
# Add following data to system:
# userName		$G_USERNAME
# uid			$G_UID
# realName		$G_REALNAME
# gid			$G_GID
# homeDir			$G_HOMEDIR
# EOM

lprint "Checking on the shell '$G_SHELL'"
fileExist_check $G_SHELL || fatal shell

if (( Gb_createGroup )) ; then 
  lprint "Create new groupName $G_GROUPNAME" ; 
  dscl . create /groups/$G_GROUPNAME name 	$G_GROUPNAME 	2>/dev/null 
  ret_check $? || fatal groupName
  lprint "Create new gid $G_GROUPNAME" ; 
  dscl . create /groups/$G_GROUPNAME gid 	$G_GID		2>/dev/null
fi

lprint "Create a new user entry, $G_USERNAME"
dscl . -create /Users/"$G_USERNAME" 				2>/dev/null
ret_check $? || fatal userName

lprint "Set the shell property, $G_SHELL"
dscl . -create /Users/$G_USERNAME UserShell $G_SHELL		2>/dev/null
ret_check $? || fatal shell

lprint "Set the user's real name, $G_REALNAME"
dscl . -create /Users/$G_USERNAME RealName "$G_REALNAME"	2>/dev/null
ret_check $? || fatal realName

lprint "Set the user's unique ID, $G_UID"
dscl . -create /Users/$G_USERNAME UniqueID $G_UID		2>/dev/null
ret_check $? || fatal uid

lprint "Set the user's group ID, $G_GID"
dscl . -create /Users/$G_USERNAME PrimaryGroupID $G_GID		2>/dev/null
ret_check $? || fatal gid

lprint "Set the home directory, $G_HOMEDIR"
dscl . -create /Users/$G_USERNAME NFSHomeDirectory $G_HOMEDIR	2>/dev/null
ret_check $? || fatal homeDir
mkdir -p $G_HOMEDIR
chown -R ${G_USERNAME}:${G_GID} $G_HOMEDIR

printf "\n***Remember to set the password with 'sudo passwd $G_USERNAME'!***"

printf "\n\n%40s" "Cleaning up"
ret_check $?
shut_down 0
