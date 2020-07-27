#!/bin/bash

# "include" the set of common script functions
source common.bash

G_USERNAME="-x"
G_GROUPLIST="-x"

echo -n "Enter toor (admin) password:"
read -s LDAPPWD

LDIF=/tmp/LDIF.txt

declare -i b_changePasswdOnly=0
declare -i b_purge=0
declare -i b_deleteFromLDAP=0
declare -i b_OK=0
declare -i i=0
declare -i b_changeGroupOnly=0
declare -i b_createNewGroup=0
declare -i b_deleteFromGroup=0
declare -i b_forceUID=0

let Gi_verbose=1
verbosity_check
G_LC=70
G_RC=40

G_SYNOPSIS="

 NAME

        neuro-adduser.sh

 SYNOPSIS

        neuro-adduser.sh    -u <username>                      \\
			    -U <uid>			       \\
                            -g|-G <groupname>                  \\
			    -d -D 			       \\
			    -p				       \\
			    -N <newGroupName,newGroupID>

 DESCRIPTION

        'neuro-adduser.sh' is a general FNNDSC LDAP user administration
	script. In most cases it is used to add a user to the LDAP
	system and add the user to exist LDAP groups. It also sets up
	the user's directories, initialze the user's env and adds important
	symbolic links.

	It can also modify some attributes of an existing user and
	also create new groups from scratch.

	It can also be used to remove a used from LDAP (-d) and also
	purge the user's directories (-D).

	Finally, it can also be used to set/change the password for the
	user (-p).

 ARGUMENTS

        -u <username>
        The user name which should match the part of the BCH email before @.
        e.g. daniel.haehn

	-U <uid>
	If specified, force the user's uid to be <uid> instead of autogenerating.

        -g <groupname>
        The group that the user will be part of. Valid LDAP groups are:

		PRIMARY GROUPS:
		o grantlab
		o sheridanlab
		o gaablab
		o nelsonlab
		o meggp
		o cbdgp
		o collabs
		o visitors

		SECONDARY GROUPS:
		o mi2b2
		o chrisgp
		o (possibly others)

	This can be a comma separated list of groups as well. The first group
	in the list is considered the primary group and defines where the
	user's home directory will be created.

	If a secondary group is specified as the first argument to '-g' then
	the script will terminate with an error.

	The '-G' designates a modification on an existing user -- typically
	used when a user needs to be added to other groups after having
	already been created.

	-N <newGroupName,newGroupID>
	If specified will ignore all other flags and create a new LDAP
	called <newGroupName> with group ID <newGroupID>.

	-d
	Delete the user from the LDAP database (and also LDAP groups).

	-D
	Delete (purge!) the user's actual home diretory and associated symbolic
	links. Use with care!

	-p
	Only set the user's password.

 HISTORY

        21 Nov 2012
        o remove the toor username for ssh
        o should run the script as root to take advantage of the passwordless ssh

        30 May 2012
        o First version.

        08 Oct 2015
        o Major updates and refactoring.

        09 Jun 2020
        o Remove hard-coded LDAPPWD
        o Read password from stdin
            Type it in interactively, or you could use a here-string.
            Example: ./neuro-adduser.sh -u person.name -g grantlab <<< correct.horse.battery.staple
"
###\\\
# Global variables --->
###///

# Actions
A_notRoot="checking on EUID"
A_noUsernameArg="checking on the -u <username> argument"
A_noGrouplistArg="checking on the -g <groupname> argument"
A_invalidGroup="checking on groups"
A_invalidPrimaryGroup="specifiying homedir"
A_wrongHost="checking on the current host"
A_checkingOnExistingUsers="checking on existing users"
A_addUserToLDAP="adding user to LDAP"
A_addToChrisGroup="adding user to chrisgp"
A_couldNotSetPasswd="attempting to set user password"
A_performingFileOperation="performing a file-based operation"

# Error messages
EM_notRoot="this script MUST be run as root!"
EM_noUsernameArg="it seems as though you didn't specify a -u <username>."
EM_noGrouplistArg="it seems as though you didn't specify a -g <groupname>."
EM_invalidGroup="an invalid group was specified!"
EM_invalidPrimaryGroup="an invalid *primary* group was specified!"
EM_wrongHost="please run this script as 'root' on host 'fnndsc'."
EM_checkingOnExistingUsers="the user dump from LDAP was spurious."
EM_addUserToLDAP="I could not add the user for some reason."
EM_addToChrisGroup="I could not add the user to chrisgp"
EM_couldNotSetPasswd="I could not set the user's password"
EM_performingFileOperation="a failure was detected."

# Error codes
EC_notRoot=1
EC_noUsernameArg="666"
EC_noGrouplistArg="669"
EC_invalidGroup="600"
EC_invalidPrimaryGroup="601"
EC_wrongHost="700"
EC_checkingOnExistingUsers="800"
EC_addUserToLDAP="801"
EC_addToChrisGroup="802"
EC_couldNotSetPasswd="803"
EC_performingFileOperation="900"


function status
{
	COLOR="0;33"
	MSG=$1
	if (( ${#2} )) ; then
	    COLOR=$2
    	fi
        printf "\E[${COLOR}m%*s\E[0m" -$G_LC "$MSG"
}

function user_deleteFromLDAP
{
	echo "uid=$G_USERNAME,ou=people,dc=fnndsc
	" > $LDIF

	ldapdelete -x -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -h fnndsc -f $LDIF >/dev/null 2>/dev/null
	rm $LDIF
}

function LDAP_dump
{
	FILE=/tmp/LDAPdump.txt
	if (( ${#1} )) ; then FILE=$1; 	fi
	ldapsearch -b "dc=fnndsc" -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -h fnndsc > $FILE
}

function user_deleteFromGroup
{
	LDIF=/tmp/deleteUserFromGroupLDAP.txt
	group=$1

	echo "dn: cn=${group},ou=groups,dc=fnndsc
	changetype: modify
	delete: memberUid
	memberUid: $G_USERNAME" > $LDIF

	ldapmodify -x -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -h fnndsc -f $LDIF >/dev/null 2>/dev/null
	rm $LDIF
}

function user_deleteFromGroupList
{
	GROUPLIST=$1
	for group in $GROUPLIST ; do
		lprint "Deleting $G_USERNAME from LDAP group <$group>" "1;31" "-"
		user_deleteFromGroup $group 2>/dev/null >/dev/null
		ret_check $?
	done
}

function user_check
{
	ret=$1
	if [[ $ret != "0" ]]  ; then
	  while true; do
		read -p "Do you wish to: (a)bort; (d)elete the user and exit; (i)gnore and continue? " adi
		case $adi in
			[Aa]*) exit							;;
			[Dd]*) user_deleteFromLDAP; exit				;;
			[Ii]*) break							;;
			*)	echo "Please answer [a]bort, [d]elete or [i]gnore." 	;;
		esac
	  done
	fi

}

function group_createNewLDAP
{
	GROUP=$1
	GID=$2

	LDIF=/tmp/createNewGroupLDAP.txt

	echo "dn: cn=${GROUP},ou=groups,dc=fnndsc
	objectClass: top
	objectClass: posixGroup
	gidNumber: $GID" > $LDIF

	ldapadd -x -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -h fnndsc -f $LDIF >/dev/null 2>/dev/null
	rm $LDIF
}

function group_check
{
	ret=$1
	group=$2
	if [[ $ret != "0" ]]  ; then
	  while true; do
		read -p "Do you wish to: (a)bort; (d)elete the user from <${group}> and exit; (i)gnore and continue? " adi
		case $adi in
			[Aa]*) exit							;;
			[Dd]*) user_deleteFromGroup $group; exit 			;;
			[Ii]*) break							;;
			*)	echo "Please answer (a)bort, (d)elete, or (i)gnore." 	;;
		esac
	  done
	fi

}

function passwd_set
{

	status "--> Setting the user password"
	echo "" ; ldappasswd -h fnndsc -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -S "uid=$G_USERNAME,ou=people,dc=fnndsc"
	ret=$?

	ret_check $ret					\
		"Could not set user password"		\
		"User password successfully set"  ||	\
		fatal couldNotSetPasswd
}

function user_addToLDAP
{
	if (( ! ${#LASTNAME} )) ; then
	    LASTNAME=FIRSTNAME
	fi

	echo "dn: uid=$G_USERNAME,ou=people,dc=fnndsc
	objectClass: inetOrgPerson
	objectClass: posixAccount
	givenName: $FIRSTNAME
	sn: $LASTNAME
	cn: $G_USERNAME
	uid: $G_USERNAME
	userPassword: {MD5}1234
	uidNumber: $USERID
	gidNumber: $GROUPID
	homeDirectory: /neuro/users/$G_USERNAME
	loginShell:/bin/bash" > $LDIF
	ldapadd -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -h fnndsc -f $LDIF >/dev/null 2>/dev/null
}

function user_addToGroup
{
	group=$1

	echo "dn: cn=${group},ou=groups,dc=fnndsc
	changetype: modify
	add: memberuid
	memberuid: $G_USERNAME" > $LDIF
	ldapmodify -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -h fnndsc -f $LDIF >/dev/null 2>/dev/null
}

function user_addToGroupAndCheck {
	group=$1

	status "--> Adding $G_USERNAME to LDAP group <$group>"
	user_addToGroup $group

	ret=$?
	ret_check $ret					\
		"$G_USERNAME already in <$group>" \
		"$G_USERNAME added to <$group>"

	group_check $ret $group
}

function user_deleteFromLDAPConfirm
{
	status "About to DELETE user from LDAP" "1;31"
	echo ""

	while true; do
		read -p "Do you wish to: (a)bort or (d)elete the user from LDAP? "  ap
		case $ap in
			[Aa]*) 	exit							;;
			[Dd]*) 	status "Deleting from LDAP..."
				echo ""
				break 							;;
			*)	echo "Please answer (a)bort or (p)urge" 		;;
		esac
  	done
}

function user_purgeConfirm
{
	status "About to PURGE user home directory" "1;31"
	echo ""

	while true; do
		read -p "Do you wish to: (a)bort or (p)urge the user's home dirs? "  ap
		case $ap in
			[Aa]*) 	exit							;;
			[Pp]*) 	status "Purging..."
				echo ""
				break 							;;
			*)	echo "Please answer (a)bort or (p)urge" 		;;
		esac
  	done
}

function user_purge
{
	lprint "Deleting $HOMEDIR" "0;31" "-"
	ssh $REMOTEHOST rm -fr $HOMEDIR 2>/dev/null
	ret_check $?
	lprint "Removing link in /neuro/users/$G_USERNAME" "0;31" "-"
	rm /neuro/users/$G_USERNAME 2>/dev/null
	ret_check $?
}

function homedir_set
{
	# Sets the home directory based on the group spec
	group=$1
	case "$group"
	in
		"grantlab")
			REMOTEHOST=fnndsc
			HOMEDIR="/neuro/labs/grantlab/users/$G_USERNAME"
			NETHOME=$HOMEDIR
			GROUPID="1102"
			;;
		"gaablab")
			REMOTEHOST=fnndsc
			HOMEDIR="/neuro/labs/gaablab/users/$G_USERNAME"
			NETHOME=$HOMEDIR
			GROUPID="1102"
			;;
		"sheridanlab")
			REMOTEHOST=fnndsc
			HOMEDIR="/neuro/labs/sheridanlab/users/$G_USERNAME"
			NETHOME=$HOMEDIR
			GROUPID="1102"
			;;
		"nelsonlab")
			REMOTEHOST=fnndsc
			HOMEDIR="/neuro/labs/nelsonlab/users/$G_USERNAME"
			NETHOME=$HOMEDIR
			GROUPID="1102"
			;;
		"meggp")
			REMOTEHOST=zeus
			HOMEDIR="/local_mount/space/zeus/2/chb/meglab/users/$G_USERNAME"
			NETHOME="/neuro/labs/meglab/users/$G_USERNAME"
			GROUPID="1102"
			;;
		"cbdgp")
			REMOTEHOST=fnndsc
			GROUPID="1102"
			HOMEDIR="/neuro/labs/meglab/users/$G_USERNAME"
			NETHOME=$HOMEDIR
			;;
		* )	fatal invalidPrimaryGroup
	esac
	PRIMARYGROUP=$group
}

###\\\
# Process command options --->
###///

while getopts u:U:g:G:dDpN:r: option ; do
        case "$option"
        in
                u)      G_USERNAME=$OPTARG	;;
		U)	b_forceUID=1
			USERID=$OPTARG		;;
                g)      G_GROUPLIST=$OPTARG	;;
		G)	G_GROUPLIST=$OPTARG
			b_changeGroupOnly=1	;;
		r)	G_GROUPLIST=$OPTARG
			b_deleteFromGroup=1	;;
		d)	b_deleteFromLDAP=1
			b_deleteFromGroup=1	;;
		D)	b_purge=1		;;
		p)	b_changePasswdOnly=1	;;
		N)	b_createNewGroup=1
			NEWGROUPSPEC=$OPTARG	;;
                \?)     synopsis_show
			shut_down 1		;;
        esac
done

lprint "Am I root?" "0;35" "-"
ret_check $EUID "Not root" "ok" || fatal notRoot

# Are we running on the correct host?
lprint "Checking on <hostname>" "0;35" "-"
HOSTNAME=$(cat /etc/hostname | awk '{print $1}')
ret_check $?
if [[ "$HOSTNAME" != "fnndsc" ]] ; then fatal wrongHost ; fi

# First check on one-off functions:
if (( b_changePasswdOnly )) ; 	then	passwd_set; exit; 	fi

if (( b_createNewGroup )) ; then
	NEWGROUPNAME=$(echo $NEWGROUPSPEC 	| awk -F\, '{print $1}')
	NEWGROUPID=$(echo $NEWGROUPSPEC 	| awk -F\, '{print $2}')

	status "--> Creating new LDAP group" ""
	group_createNewLDAP $NEWGROUPNAME $NEWGROUPID
	ret=$?
	ret_check $ret 				\
		"Could not create new group -- already in LDAP"		\
		"new LDAP group, name <$NEWGROUPNAME>, gid <$NEWGROUPID>"
	exit
fi

###\\\
# Some error checking --->
###///
lprint "Checking on <userarg> " "0;35" "-"
if [[ "$G_USERNAME" == "-x" ]] ; then fatal noUsernameArg ; fi
ret_check $?

lprint "Checking on <grouparg>" "0;35" "-"
if [[ "$G_GROUPLIST" == "-x" ]] ; then fatal noGrouplistArg ; fi
ret_check $?

echo ""
# Now, check if target group spec is valid and set home dir based
# on *first* group spec
LDAPFILE=/tmp/LDAP.txt
LDAP_dump $LDAPFILE
LDAPGROUPLIST=$( cat $LDAPFILE  		|\
		 grep groups 			|\
		 awk '{if(NF==4) print $0;}'    |\
		 awk '{print $2}' 		|\
		 tr -d ',' | tr '\n' ' ')
GROUPLIST=$(echo $G_GROUPLIST | tr ',' ' ')
i=0
for group in $GROUPLIST ; do
	lprint "Checking on specified group <$group>" "1;35" "-"
	[[ $LDAPGROUPLIST =~ (^| )$group($| ) ]] && b_OK=1 || b_OK=0
	if (( b_OK )) ; then
		rprint "[ Valid group ]" "1;32"
		if (( !i && !b_changeGroupOnly && !b_deleteFromGroup )) ; then
			homedir_set $group
		fi

		if (( b_changeGroupOnly )) ; then
			user_addToGroupAndCheck $group
		fi
	else
		rprint "[ Invalid group ]" "1;31"
		fatal invalidGroup
	fi
	((i++))
done

if (( b_changeGroupOnly )) ; then exit;	fi

echo ""
if (( b_purge )) ; 		then
	user_purgeConfirm
	user_purge
	exit
fi

if (( b_deleteFromLDAP )) ; 	then
	user_deleteFromLDAPConfirm;
	lprint "Deleting primary user entry" "1;31" "-"
	user_deleteFromLDAP
	ret_check $?
fi

if (( b_deleteFromGroup )) ; then
	user_deleteFromGroupList "$GROUPLIST"
	exit 0
fi

############################
#                          #
# Primary LDAP Operations  #
#                          #
############################

###############################################
# get highest uidNumber and increment it by 1 #
###############################################
if (( !b_forceUID )) ; then
    status "--> Looking for next available user id"

    LDAP_dump $LDAPFILE
    ret_check $? 			\
	"LDAP user access error"	\
	"Found next LDAP uid" || 	\
		fatal checkingOnExistingUsers

    USERID=$(	cat $LDAPFILE 		| grep uidNumber 	|\
	     	awk '{print $2}'  	| sort -n -k 1 		|\
		tr -d '\r' 		| tail -n 1)
    USERID=$(expr $USERID + 1)
else
    status "--> Setting UID manually"
    ret_check $?
fi

lprint "$G_USERNAME" 	"1;32"
rprint "[ $USERID ]" 	"1;36"

#################################################
# add user with correct uid but dummmy password #
#################################################

status "--> Adding user to LDAP"

FIRSTNAME=$(echo $G_USERNAME | awk -F \. '{print $1}')
LASTNAME=$(echo $G_USERNAME  | awk -F \. '{print $2}')

user_addToLDAP

ret=$?
ret_check $ret 				\
	"Could not add user -- already in LDAP"		\
	"$G_USERNAME added to LDAP"
user_check $ret

# cleaning up tmp files
rm $LDIF

########################################
# add user to the each specified group #
########################################

for group in $GROUPLIST ; do
	user_addToGroupAndCheck $group
done

#######################
#                     #
# FILE SYSTEM ACTIONS #
#                     #
#######################

#########################################
# create the home directory and link it #
#########################################
status "--> Creating $HOMEDIR"
ssh $REMOTEHOST mkdir $HOMEDIR 2>/dev/null
ret_check $? || fatal performingFileOperation

status "--> Setting home access temporarily to 777"
ssh $REMOTEHOST chmod 777 $HOMEDIR 2>/dev/null
ret_check $? || fatal performingFileOperation

status "--> ln -s "$NETHOME" /neuro/users"
ln -s $NETHOME "/neuro/users/"
ret_check $? || fatal performingFileOperation

#################################
# Copy various bash env scripts #
#################################

status "--> Copying FNNDSC standard env scripts"
cp /neuro/sys/install/ubuntu/setup/customize_shells/.[a-z]* $NETHOME
ret_check $? || fatal performingFileOperation

########################
# set /neuro/arch link #
########################

status "--> Linking /neuro/arch to the user home directory"
ln -s /neuro/arch $NETHOME
ret_check $? || fatal performingFileOperation

#######################
# set the permissions #
#######################

status "--> Setting home directory access to 750"
ssh $REMOTEHOST chmod 750 $HOMEDIR 2>/dev/null
ret_check $? || fatal performingFileOperation

status "--> Setting home directory ownership to $USERID:$GROUPID"
ssh $REMOTEHOST chown -R ${USERID}:${GROUPID} $HOMEDIR 2>/dev/null
ret_check $? || fatal performingFileOperation

########################
# update user password #
########################

passwd_set

echo ""
status "-->All done!" "1;34"
echo ""
status "DO NOT FORGET TO ADD THIS USER TO RSNAPSHOT!" "1;31"
echo ""
status "DO NOT FORGET TO ADD THIS USER TO THE MAILING LIST!" "1;31"
echo ""


