#!/bin/bash

# "include" the set of common script functions
source common.bash

G_USERNAME="-x"
G_GROUPNAME="-x"



G_SYNOPSIS="

 NAME

        neuro-adduser.sh

 SYNOPSIS

        neuro-adduser.sh    -u <username>                      
                                -g <groupname>                    

 DESCRIPTION

        'neuro-adduser.bash' creates the home folder depending on the group 
        with presets of .bashrc etc. and the /neuro/arch link.
        
 ARGUMENTS                                

        -u <username>
        The user name which should match the part of the CHB email before @.
        e.g. daniel.haehn
        
        -g <groupname>
        The group name.
        e.g. grant || sheridan || gaab || meg || collabs || visitors
        
 HISTORY

        21 Nov 2012
        remove the toor username for ssh
        should run the script as root to take advantage of the passwordless ssh 
        30 May 2012
        o First version.
"
###\\\
# Global variables --->
###///

# Actions
A_noUsernameArg="checking on the -u <username> argument"
A_noGroupnameArg="checking on the -g <groupname> argument"

# Error messages
EM_noUsernameArg="it seems as though you didn't specify a -u <username>."
EM_noGroupnameArg="it seems as though you didn't specify a -g <groupname>."

# Error codes
EC_noUsernameArg=666
EC_noGroupnameArg=669

###\\\ 
# Process command options --->
###/// 

while getopts u:g: option ; do
        case "$option" 
        in
                u)      G_USERNAME=$OPTARG;;
                g)      G_GROUPNAME=$OPTARG;;
                \?)     synopsis_show;;
        esac
done        


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
if [[ "$HOSTNAME" != "fnndsc" ]] ; then echo "Please run this script from the fnndsc machine."; exit; fi

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

#########################
#
# ADD USER IN THE LDAP
#
#########################

#get highest uidNumber and increment it by 1
USERID=$( ldapsearch -b "dc=fnndsc" -D "cn=admin,dc=fnndsc" -W -h zulu-ldap | grep uidNumber | awk '{print $2 | "sort -nk2"}' | awk 'END{print}' | tr -d '\r')

USERID=$(expr $USERID + 1)

# add user with correct uid but dummmy password
FIRSTNAME=$(echo $G_USERNAME | awk -F \. '{print $1}')
LASTNAME=$(echo $G_USERNAME | awk -F \. '{print $2}')
echo "dn: uid=$G_USERNAME,ou=people,dc=fnndsc
objectClass: inetOrgPerson
objectClass: posixAccount
givenName: $FIRSTNAME
sn: $LASTNAME
cn: $G_USERNAME
uid: $G_USERNAME
userPassword: {MD5}$1234
uidNumber: $USERID
gidNumber: $GROUPID
homeDirectory: /neuro/users/$G_USERNAME
loginShell:/bin/bash" > /tmp/addusertoldap.txt

ldapadd -D "cn=admin,dc=fnndsc" -W -h zulu-ldap -f /tmp/addusertoldap.txt

rm /tmp/addusertoldap.txt

# add user to the chris group
echo "dn: cn=chrisgp,ou=groups,dc=fnndsc
changetype: modify
add: memberuid
memberuid: $G_USERNAME" > /tmp/addusertochrisgp.txt

ldapmodify -D "cn=admin,dc=fnndsc" -W -h zulu-ldap -f /tmp/addusertochrisgp.txt

rm /tmp/addusertochrisgp.txt

# add meg users to the meg group
if [[ "$G_GROUPNAME" == "meg" ]]; then
  echo "dn: cn=meglab,ou=groups,dc=fnndsc
  changetype: modify
  add: memberuid
  memberuid: $G_USERNAME" > /tmp/addusertomeggp.txt

  ldapmodify -D "cn=admin,dc=fnndsc" -W -h zulu-ldap -f /tmp/addusertomeggp.txt

  rm /tmp/addusertomeggp.txt
fi

#########################
#
# SELECT THE HOMEFOLDER LOCATION
#
#########################

HOMEFOLDER="/neuro/labs/"$G_GROUPNAME"lab/users"
if [[ "$G_GROUPNAME" == "collabs" || "$G_GROUPNAME" == "visitors" ]]; then
  HOMEFOLDER="/neuro/labs/grantlab/"$G_GROUPNAME
fi

# home directory
HOMEFOLDER=$HOMEFOLDER"/"$G_USERNAME

echo "Creating "$HOMEFOLDER

# just create the folder and link it
sudo mkdir $HOMEFOLDER
sudo chmod 777 $HOMEFOLDER
ln -s $HOMEFOLDER "/neuro/users/"

# create the link
echo "Copying .bash* and .git* over.."
cp /neuro/sys/install/ubuntu/setup/customize_shells/.bash* $HOMEFOLDER/
cp /neuro/sys/install/ubuntu/setup/customize_shells/.git* $HOMEFOLDER/
echo "Linking /neuro/arch/"
ln -s /neuro/arch/ $HOMEFOLDER/arch

#
# Now reset the permissions 
#
echo "Reset permissions to "$USERID":"$GROUPID
  
sudo chmod 770 $HOMEFOLDER
sudo chown -R $USERID:$GROUPID $HOMEFOLDER

# update user passowrd
ldappasswd -h zulu-ldap -D "cn=admin,dc=fnndsc" -W -S "uid=$G_USERNAME,ou=people,dc=fnndsc"

echo "All done - sayonara.."

echo "DO NOT FORGET TO ADD THIS USER TO RSNAPSHOT!"
