#!/bin/bash

# "include" the set of common script functions
source common.bash

G_USERNAME="-x"
G_GROUPNAME="-x"

LDAPPWD="xzaq!@#$"

declare -i b_changePasswdOnly
declare -i b_purge
declare -i b_deleteFromLDAP

b_deleteFromLDAP=0	# -d
b_purge=0		# -D 
b_changePasswdOnly=0	# -p

G_SYNOPSIS="

 NAME

        neuro-adduser.sh

 SYNOPSIS

        neuro-adduser.sh    -u <username>                      \\
                            -g <groupname>                     \\
			    -d -D 			       \\
			    -p

 DESCRIPTION

        'neuro-adduser.sh' is a general FNNDSC LDAP user administration
	script. In most cases it is used to add a user to the LDAP
	system and setup the user's directories, initialze the user's
	env and add important symbolic links.

	It can also be used to remove a used from LDAP (-d) and also
	purge the user's directories (-D).

	Finally, it can also be used to set/change the password for the
	user (-p).

 ARGUMENTS                                

        -u <username>
        The user name which should match the part of the BCH email before @.
        e.g. daniel.haehn
        
        -g <groupname>
        The group name.
        e.g. grant || sheridan || gaab || meg || collabs || visitors

	-d
	Delete the user from the LDAP database (and also LDAP groups).

	-D
	Delete the user's actual home diretory and associated symbolic links.

	-p
	Only set the user's password.
        
 HISTORY

        21 Nov 2012
        o remove the toor username for ssh
        o should run the script as root to take advantage of the passwordless ssh 

        30 May 2012
        o First version.
	
	08 Oct 2015
	o Updates.
"
###\\\
# Global variables --->
###///

# Actions
A_noUsernameArg="checking on the -u <username> argument"
A_noGroupnameArg="checking on the -g <groupname> argument"
A_wrongHost="checking on the current host"
A_checkingOnExistingUsers="checking on existing users"
A_addUserToLDAP="adding user to LDAP"
A_addToChrisGroup="adding user to chrisgp"
A_couldNotSetPasswd="attempting to set user password"

# Error messages
EM_noUsernameArg="it seems as though you didn't specify a -u <username>."
EM_noGroupnameArg="it seems as though you didn't specify a -g <groupname>."
EM_wrongHost="please run this script as 'root' on host 'fnndsc'."
EM_checkingOnExistingUsers="the user dump from LDAP was spurious."
EM_addUserToLDAP="I could not add the user for some reason."
EM_addToChrisGroup="I could not add the user to chrisgp"
EM_couldNotSetPasswd="I could not set the user's password"

# Error codes
EC_noUsernameArg=666
EC_noGroupnameArg=669
EC_wrongHost=700
EC_checkingOnExistingUsers=800
EC_addUserToLDAP=801
EC_addToChrisGroup=802
EC_couldNotSetPasswd=803

function status
{
	COLOR="0;33"
	MSG=$1
	if (( ${#2} )) ; then
	    COLOR=$2
    	fi
        printf "\E[${COLOR}m%*s\E[0m" -$G_LC "$MSG"
}

function delete_user
{
	LDIF=/tmp/deleteUserFromLDAP.txt
	
	# echo "dn: uid=$G_USERNAME,ou=people,dc=fnndsc
	# changetype: delete
	# " > $LDIF

	echo "uid=$G_USERNAME,ou=people,dc=fnndsc
	" > $LDIF

	ldapdelete -x -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -h fnndsc -f $LDIF >/dev/null 2>/dev/null
	rm $LDIF
}

function delete_userFromGroup
{
	LDIF=/tmp/deleteUserFromGroupLDAP.txt
	group=$1
		
	echo "dn: cn=${group},ou=groups,dc=fnndsc
	changetype: modify
	delete: memberUid
	memberUid: $G_USERNAME" > $LDIF

	ldapmodify -x -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -h fnndsc -f $LDIF 
	# rm $LDIF
}

function user_check
{
	ret=$1
	if [[ $ret != "0" ]]  ; then
	  while true; do
		read -p "Do you wish to: (a) abort; (d)elete the user and exit; (i) ignore and continue " adi
		case $adi in 
			[Aa]*) exit							;;
			[Dd]*) delete_user; exit 					;;
			[Ii]*) break							;;
			*)	echo "Please answer [a]bort, [d]elete or [i]gnore." 	;;
		esac
	  done
	fi

}

function group_check
{
	ret=$1
	group=$2
	if [[ $ret != "0" ]]  ; then
	  while true; do
		read -p "Do you wish to: (a) abort; (d)elete the user from ${group} and exit; (i) ignore and continue " adi
		case $adi in 
			[Aa]*) exit							;;
			[Dd]*) delete_userFromGroup $group; exit 			;;
			[Ii]*) break							;;
			*)	echo "Please answer [a]bort, [d]elete or [i]gnore." 	;;
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

function user_deleteFromLDAP
{
	G_LC=65
	G_RC=15
	status "About to DELETE user from LDAP" "1;31"
	echo ""
	
	while true; do
		read -p "Do you wish to: (a) abort; (d)elete the user from LDAP? "  ap
		case $ap in 
			[Aa]*) 	exit							;;
			[Dd]*) 	status "Deleting from LDAP..." 
				echo ""
				break 							;;
			*)	echo "Please answer [a]bort, [p]urge" 			;;
		esac
  	done
	status "Deleting user entry"
	delete_user	
	ret_check $?

	status "Deleting user from group <chrisgp>"
	delete_userFromGroup chrisgp 2>/dev/null >/dev/null	
	ret_check $?

	status "Deleting user from group <$G_GROUPNAME>"
	delete_userFromGroup ${G_GROUPNAME}gp 2>/dev/null >/dev/null
	ret_check $?
	
	exit
}

function user_purge
{
	G_LC=65
	G_RC=15
	status "About to PURGE user home directory" "1;31"
	echo ""
	
	while true; do
		read -p "Do you wish to: (a) abort; (p)urge the user's home dirs? "  ap
		case $ap in 
			[Aa]*) 	exit							;;
			[Pp]*) 	status "Purging..." 
				echo ""
				break 							;;
			*)	echo "Please answer [a]bort, [p]urge" 			;;
		esac
  	done
	status "Deleting $HOMEFOLDER"
	ssh $REMOTEHOST rm -fr $HOMEFOLDER 2>/dev/null
	ret_check $?
	status "Removing link in /neuro/users/$G_USERNAME"
	rm /neuro/users/$G_USERNAME 2>/dev/null
	ret_check $?

	exit
}

###\\\ 
# Process command options --->
###/// 

let Gi_verbose=1
verbosity_check
G_LC=70
G_RC=30

while getopts u:g:dDp option ; do
        case "$option" 
        in
                u)      G_USERNAME=$OPTARG	;;
                g)      G_GROUPNAME=$OPTARG	;;
		d)	b_deleteFromLDAP=1	;;
		D)	b_purge=1		;;
		p)	b_changePasswdOnly=1	;;
                \?)     synopsis_show		;;
        esac
done        

# home directory
HOMEFOLDER="/neuro/labs/${G_GROUPNAME}lab/users/$G_USERNAME"
NETHOME=$HOMEFOLDER
if [[ "$G_GROUPNAME" == "collabs" || "$G_GROUPNAME" == "visitors" ]]; then
  	HOMEFOLDER="/neuro/labs/grantlab/"$G_GROUPNAME
fi
REMOTEHOST="fnndsc"
if [[ $G_GROUPNAME == 'meg' ]] ; then 
	REMOTEHOST="zeus" 
	HOMEFOLDER=/local_mount/space/zeus/2/chb/meglab/users/$G_USERNAME
fi

if (( b_purge )) ; then
	user_purge
fi

if (( b_deleteFromLDAP )) ; then
	user_deleteFromLDAP
fi

if (( b_changePasswdOnly )) ; then
	passwd_set	
	exit
fi

###\\\
# Some error checking --->
###///
statusPrint "Checking on <username>"
if [[ "$G_USERNAME" == "-x" ]] ; then fatal noUsernameArg ; fi
ret_check $?

statusPrint "Checking on <groupname>"
if [[ "$G_GROUPNAME" == "-x" ]] ; then fatal noGroupnameArg ; fi
ret_check $?

# 
# CHECK ON THE HOSTNAME
#
statusPrint "Checking on <hostname>"
HOSTNAME=$(cat /etc/hostname | awk '{print $1}')
ret_check $?
if [[ "$HOSTNAME" != "fnndsc" ]] ; then fatal wrongHost ; fi

#
# GET THE GROUP IDS
#

GROUPID="1102" #standard ellengp

if [[ "$G_GROUPNAME" == "gaab" ]]; then
  	GROUPID="1103"
fi

if [[ "$G_GROUPNAME" == "sheridan" ]]; then
  	GROUPID="1104"
fi

echo "$G_USERNAME will be part of the ${G_GROUPNAME} group (gid: ${GROUPID})"

####################
#                  #
# ADD USER TO LDAP #
#                  #
####################

###############################################
# get highest uidNumber and increment it by 1 #
###############################################

status "--> Looking for next available user id"

ldapsearch -b "dc=fnndsc" -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -h fnndsc > /tmp/userslist.txt
ret_check $? 				\
	"No users found"		\
	"Found existing users" || 	\
		fatal checkingOnExistingUsers

USERID=$( cat /tmp/userslist.txt | grep uidNumber | awk '{print $2 | "sort -n -k 1"}' | awk 'END{print}' | tr -d '\r')
USERID=$(expr $USERID + 1)

status "$G_USERNAME id:" "1;32"
ret_check $? "" "$USERID"

#################################################
# add user with correct uid but dummmy password #
#################################################

status "--> Adding user to LDAP"

FIRSTNAME=$(echo $G_USERNAME | awk -F \. '{print $1}')
LASTNAME=$(echo $G_USERNAME | awk -F \. '{print $2}')

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
loginShell:/bin/bash" > /tmp/addusertoldap.txt

ldapadd -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -h fnndsc -f /tmp/addusertoldap.txt >/dev/null 2>/dev/null
ret=$?
ret_check $ret 				\
	"Could not add user -- already in LDAP"		\
	"User successfully added" 
user_check $ret

# cleaning up tmp files
rm /tmp/addusertoldap.txt

###############################
# add user to the chris group #
###############################

status "--> Adding user to the chris group  "

echo "dn: cn=chrisgp,ou=groups,dc=fnndsc
changetype: modify
add: memberuid
memberuid: $G_USERNAME" > /tmp/addusertochrisgp.txt

ldapmodify -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -h fnndsc -f /tmp/addusertochrisgp.txt >/dev/null 2>/dev/null

ret=$?
ret_check $ret					\
	"Could not add user to <chrisgp> -- already exists in group" \
	"User added to <chrisgp>"	

group_check $ret chrisgp

# cleaning up tmp files
rm /tmp/addusertochrisgp.txt

######################################## 
# add users to the meg group if needed #
########################################

if [[ "$G_GROUPNAME" == "meg" ]]; then
    status "--> Adding user to the meg group "

    echo "dn: cn=meggp,ou=groups,dc=fnndsc
changetype: modify
add: memberuid
memberuid: $G_USERNAME" > /tmp/addusertomeggp.txt

    ldapmodify -D "cn=admin,dc=fnndsc" -w "$LDAPPWD" -h fnndsc -f /tmp/addusertomeggp.txt >/dev/null 2>/dev/null
    ret=$?
    ret_check $ret				\
    	"Could not add user to <meggp> -- already exists in group" \
    	"User added to <meggp>"	
    
    group_check $ret meggp

  # cleaning up tmp files
  rm /tmp/addusertomeggp.txt
fi

#######################
#		      #	
# FILE SYSTEM ACTIONS #
#                     #
#######################

#########################################
# create the home directory and link it #
#########################################
status "--> Creating $HOMEFOLDER"
ssh $REMOTEHOST mkdir $HOMEFOLDER 2>/dev/null
ret_check $?

status "--> Setting home access temporarily to 777"
ssh $REMOTEHOST chmod 777 $HOMEFOLDER 2>/dev/null
ret_check $?

status "--> ln -s "$NETHOME" /neuro/users"
ln -s $NETHOME "/neuro/users/"
ret_check $?

#################################
# Copy various bash env scripts #
#################################

status "--> Copying FNNDSC standard env scripts"
cp /neuro/sys/install/ubuntu/setup/customize_shells/.[a-z]* $NETHOME
ret_check $?

########################
# set /neuro/arch link #
########################

status "--> Linking /neuro/arch to the user home directory"
ln -s /neuro/arch $NETHOME
ret_check $?

#######################
# set the permissions #
#######################

status "--> Setting home directory access to 770"
ssh $REMOTEHOST chmod 770 $HOMEFOLDER 2>/dev/null
ret_check $?

status "--> Setting home directory ownership to $USERID:$GROUPID"
ssh $REMOTEHOST chown -R ${USERID}:${GROUPID} $HOMEFOLDER 2>/dev/null
ret_check $?

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


