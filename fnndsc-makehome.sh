#!/bin/bash

# "include" the set of common script functions
source common.bash

G_USERNAME="-x"
G_GROUPNAME="-x"



G_SYNOPSIS="

 NAME

        fnndsc-makehome.bash

 SYNOPSIS

        fnndsc-makehome.bash    -u <username>                      
                                -g <groupname>                    

 DESCRIPTION

        'fnndsc-makehome.bash' creates the home folder depending on the group 
        with presets of .bashrc etc. and the famous /chb/arch link.
        
 ARGUMENTS                                

        -u <username>
        The user name which should match the part of the CHB email before @.
        e.g. daniel.haehn
        
        -g <groupname>
        The group name.
        e.g. ellengp || sheridangp || gaapgp
        
 HISTORY
 
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
# SELECT THE HOMEFOLDER LOCATION
#
USERID=`id $G_USERNAME | sed 's/^uid=//;s/(.*$//'`
HOMEFOLDER="/chb/users"
LINKFOLDER=$HOMEFOLDER"/"$G_USERNAME
GROUPID="1102" #standard ellengp
USE_KHAN=0

if [[ "$G_GROUPNAME" == "sheridangp" || "$G_GROUPNAME" == "sheridan" ]]; then
  HOMEFOLDER="/mnt/DMC-Sheridan2/users"
  LABNAME="sheridanlab"
  GROUPID="1104"
  USE_KHAN=1
fi

if [[ "$G_GROUPNAME" == "gaabgp" || "$G_GROUPNAME" == "gaab" ]]; then
  HOMEFOLDER="/mnt/DMC-Gaab2/users"
  LABNAME="gaablab"
  GROUPID="1103"
  USE_KHAN=1
fi

# append the username
HOMEFOLDER=$HOMEFOLDER"/"$G_USERNAME

echo "Creating "$HOMEFOLDER

#
# USE KHAN IF REQUIRED
#
if [[ "$USE_KHAN" -eq 1 ]]; then

  # create everything on khan
  ssh fnndsc@khan -t sudo mkdir $HOMEFOLDER
  ssh fnndsc@khan -t sudo chmod 777 $HOMEFOLDER
  
  echo "And linking "$LINKFOLDER" to "/chb/$LABNAME/users/$G_USERNAME/
  
  # and link from pretoria
  ssh toor@pretoria -t sudo ln -s /chb/$LABNAME/users/$G_USERNAME/ $LINKFOLDER

else

  # just create the folder on pretoria
  ssh toor@pretoria -t sudo mkdir $LINKFOLDER
  ssh toor@pretoria -t sudo chmod 777 $LINKFOLDER

fi;

echo "Copying .bash* and .git* over.."
ssh toor@pretoria -t cp /chb/install/ubuntu/setup/customize_shells/.bash* $LINKFOLDER/
ssh toor@pretoria -t cp /chb/install/ubuntu/setup/customize_shells/.git* $LINKFOLDER/
echo "Linking /chb/arch/"
ssh toor@pretoria -t ln -s /chb/arch/ $LINKFOLDER/arch

#
# Now reset the permissions 
#
echo "Reset permissions to "$USERID":"$GROUPID
if [[ "$USE_KHAN" -eq 1 ]]; then

  # on khan
  ssh fnndsc@khan -t sudo chmod 770 $HOMEFOLDER
  ssh fnndsc@khan -t sudo chown -R $USERID:$GROUPID $HOMEFOLDER

else

  # just on pretoria
  ssh toor@pretoria -t sudo chmod 770 $HOMEFOLDER
  ssh toor@pretoria -t sudo chmod -R $USERID:$GROUPID $HOMEFOLDER

fi;

echo "All done - sayonara.."
