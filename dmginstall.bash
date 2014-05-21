#!/bin/bash

# "include" the set of common script functions
source common.bash

declare -i      Gi_verbose=0
G_LC=65
G_RC=15

DESTINATIONDIR="/Applications"

G_SYNOPSIS="

 NAME

        $G_SELF

 SYNOPSIS

        $G_SELF [-d <destinationDir>] <file.dmg>

 DESCRIPTION

        '$G_SELF' installs a Mac OS X dmg file to <destinationDir>.

 ARGUMENTS

        -d <destinationDir>

	The destination directory for the DMG. Only applicable if DMG does
	not contain a pkg file.

        <file.dmg>

	File to install.

 PRECONDITIONS

        o Mac OS X envirnoment (obviously).

 POSTCONDITIONS

	o File is installed as specified.

 HISTORY

        20 September 2013
        o Initial development

 SEE ALSO

        o http://apple.stackexchange.com/questions/73926/is-there-a-command-to-install-a-dmg
        o https://gist.github.com/afgomez/4172338

"

# TODO
# - currently only handles .dmg with .app folders, not .pkg files
# - handle .zip files as well

# Actions
A_noMacOSX="checking environment"
A_noDestDir="checking on destination directory"
A_noDMG="checking on the dmg file"
A_appExists="attempting to install"
A_copyApp="copying app to destination"

# Error messages
EM_noMacOSX="it seems that you're not running on Mac OS X."
EM_noDestDir="it seems that the destination directory does not exist."
EM_noDMG="could not access/find file."
EM_appExists="this app seems to already be installed. You'll have to manually remove the older version first."
EM_copyApp="the copy failed. Perhaps a permissions issue?"

# Error codes
EC_noMacOSX=10
EC_noDestDir=11
EC_noDMG=12
EC_appExists=13
EC_copyApp=14

while getopts v:d: option ; do
        case "$option"
        in
                d) DESTINATIONDIR=$OPTARG		;;
                v) let Gi_verbose=$OPTARG       ;;
                \?) synopsis_show
                    exit 0;;
        esac
done

verbosity_check
topDir=$(pwd)


cprint "Destination directory <$DESTINATIONDIR>" "[ ok ]"
lprint "Checking on destination directory"
(cd $DESTINATIONDIR 2>/dev/null) || fatal noDestDir
rprint "[ ok ]"

lprint   "Checking for Mac OS X"
b_MacOSX=$(uname -a | grep Darwin | wc -l)
if (( !b_MacOSX )) ; then
        fatal noMacOSX
fi
ret_check $?

shift $(($OPTIND - 1))
DMGFILE=$*
b_DMGFILE=$(echo $DMGFILE | wc -w)

cprint "dmg file <$DMGFILE>" "[ ok ]"
lprint "Checking on dmg file..."
fileExist_check $DMGFILE || fatal noDMG

# url=$*
# # Generate a random file name
# tmp_file=/tmp/`openssl rand -base64 10 | tr -dc '[:alnum:]'`.dmg
# apps_folder='/Applications'
#
# # Download file
# echo "Downloading $url..."
# curl -# -L -o $tmp_file $url

lprint "Mounting image..."
volume=`hdiutil mount $DMGFILE | tail -n1 | perl -nle '/(\/Volumes\/[^ ]+)/; print $1'`
rprint "[ ok ]"
cprint "Volume mounted as $volume..." "[ ok ]"

# Locate .app folder and move to /Applications
b_canCopy=1
appFull=$(find $volume/. -name "*.app" -maxdepth 1 -type d -print0)
lprint "Already installed?"
app=$(echo $appFull | awk -F/ '{print $NF}')
dirExist_check ${DESTINATIONDIR}/$app "no" "yes" && b_canCopy=0

if (( b_canCopy )) ; then
#	cprint "Application name"  "[ $app ]"
	lprint "Copying <$app> into $DESTINATIONDIR..."
	cp -ir $appFull $DESTINATIONDIR 2>/dev/null
	ret_check $? || beware copyApp
fi

# Unmount volume, delete temporal file
lprint "Cleaning up..."
hdiutil unmount $volume -quiet
ret_check $?
# rm $tmp_file

if (( b_canCopy )) ; then
	cprint "Done!" "[ ok ]"
else
	beware appExists
fi
