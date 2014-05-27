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

echo "$G_USERNAME will be part of the ${G_GROUPNAME} group (gid: ${GROUPID})"

#########################
#
# ADD USER IN THE LDAP
#
#########################

############################################
#get highest uidNumber and increment it by 1

echo -e "\E[33m--> Looking for next available user id\E[0m"

ldapsearch -b "dc=fnndsc" -D "cn=admin,dc=fnndsc" -W -h fnndsc > /tmp/userslist.txt

OUT=$?
if [ $OUT -eq 0 ];then
   echo "previous users id found"
else
   echo -e "\E[1;31msomething went wrong"
   echo -e "EXITING NOW\E[0m"
   exit
fi

USERID=$( cat /tmp/userslist.txt | grep uidNumber | awk '{print $2 | "sort -nk2"}' | awk 'END{print}' | tr -d '\r')
USERID=$(expr $USERID + 1)

echo "user will be assigned id: ${USERID}"

###############################################
# add user with correct uid but dummmy password

echo -e "\E[33m--> Adding user in the LDAP (passwd: 1234)\E[0m"

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

ldapadd -D "cn=admin,dc=fnndsc" -W -h fnndsc -f /tmp/addusertoldap.txt

OUT=$?
if [ $OUT -eq 0 ];then
   echo "user successfully added to the LDAP"
else
   echo -e "\E[1;31msomething went wrong"
   echo -e "EXITING NOW\E[0m"
   exit
fi

# cleaning up tmp files
rm /tmp/addusertoldap.txt

#############################
# add user to the chris group

echo -e "\E[33m--> Adding user to the chris group\E[0m"

echo "dn: cn=chrisgp,ou=groups,dc=fnndsc
changetype: modify
add: memberuid
memberuid: $G_USERNAME" > /tmp/addusertochrisgp.txt

ldapmodify -D "cn=admin,dc=fnndsc" -W -h fnndsc -f /tmp/addusertochrisgp.txt

OUT=$?
if [ $OUT -eq 0 ];then
   echo "user successfully added to the the chris group"
else
   echo -e "\E[1;31msomething went wrong"
   echo -e "EXITING NOW\E[0m"
   exit
fi

# cleaning up tmp files
rm /tmp/addusertochrisgp.txt

######################################
# add users to the meg group if needed

if [[ "$G_GROUPNAME" == "meg" ]]; then
  echo -e "\E[33m--> Adding user to the meg group \E[0m"

  echo "dn: cn=meglab,ou=groups,dc=fnndsc
changetype: modify
add: memberuid
memberuid: $G_USERNAME" > /tmp/addusertomeggp.txt

  ldapmodify -D "cn=admin,dc=fnndsc" -W -h fnndsc -f /tmp/addusertomeggp.txt

  OUT=$?
  if [ $OUT -eq 0 ];then
     echo "User successfully added to the the meg group!"
  else
     echo -e "\E[1;31msomething went wrong"
     echo -e "EXITING NOW\E[0m"
     exit
  fi
  
  # cleaning up tmp files
  rm /tmp/addusertomeggp.txt
fi

#####################
#
# FILE SYSTEM ACTIONS
#
#####################

HOMEFOLDER="/neuro/labs/"$G_GROUPNAME"lab/users"
if [[ "$G_GROUPNAME" == "collabs" || "$G_GROUPNAME" == "visitors" ]]; then
  HOMEFOLDER="/neuro/labs/grantlab/"$G_GROUPNAME
fi

# home directory
HOMEFOLDER=$HOMEFOLDER"/"$G_USERNAME

echo -e "\E[33m--> Creating "$HOMEFOLDER"\E[0m"

#######################################
# create the home directory and link it
sudo mkdir $HOMEFOLDER
sudo chmod 777 $HOMEFOLDER

echo -e "\E[33m--> Creating symlink from "$HOMEFOLDER" to /neuro/users\E[0m"
ln -s $HOMEFOLDER "/neuro/users/"

# create the link
echo -e "\E[33m--> Copying .bash* and .git* over the user home directory\E[0m"
cp /neuro/sys/install/ubuntu/setup/customize_shells/.bash* $HOMEFOLDER/
cp /neuro/sys/install/ubuntu/setup/customize_shells/.git* $HOMEFOLDER/
echo -e "\E[33m--> Linking /neuro/arch/ to the user home directory\E[0m"
ln -s /neuro/arch $HOMEFOLDER/

#####################
# set the permissions 

echo -e "\E[33m--> Setting home directory permissions to "$USERID":"$GROUPID"\E[0m"
  
sudo chmod 770 $HOMEFOLDER
sudo chown -R $USERID:$GROUPID $HOMEFOLDER

######################
# update user password

echo -e "\E[33m--> Setting the user password\E[0m"
ldappasswd -h fnndsc -D "cn=admin,dc=fnndsc" -W -S "uid=$G_USERNAME,ou=people,dc=fnndsc"

OUT=$?
if [ $OUT -eq 0 ];then
   echo "password successfully updated"
else
   echo -e "\E[1;31msomething went wrong"
   echo -e "EXITING NOW\E[0m"
   exit
fi

echo -e "\E[1;32mAll done\E[0m"
echo -e "\E[1;31mDO NOT FORGET TO ADD THIS USER TO RSNAPSHOT!\E[0m"
echo -e "\E[1;31mDO NOT FORGET TO ADD THIS USER TO THE MAILING LIST!\E[0m"
