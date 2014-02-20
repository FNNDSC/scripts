#!/bin/bash
#
# retina_fix.bash
#
# Copyright 2013 Rudolph Pienaar
# Childrens Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

declare -i Gi_verbose=0

G_SYNOPSIS="

 NAME

	retina_fix.bash

 SYNOPSIS

	retina_fix.bash <osxapp> [<osxapp1> ... <osxappN>]

 DESCRIPTION

	'retina_fix.bash' adds some text to the Info.plist file
	of each passed <osxapp> allowing the app to run properly
	on retina displays.
	
	If any of the <osxapp> applications have already been made
	retina-ready, then the script exits.

 ARGUMENTS

	-v <level> (Optional)
	Verbosity level. A value of '10' is a good choice here.

 PRECONDITIONS

	o None	

 POSTCONDITIONS

        o <osxapp> is backed up to <osxapp>.orig
	o <osxapp> has the following added to its Info.plist:
		
        <key>NSPrincipalClass</key>
        <string>NSApplication</string>
        <key>NSHighResolutionCapable</key>
        <true/>		
 
 SEE ALSO
  
 HISTORY

	25 Oct 2013
	o Initial design and coding.
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///


# Actions
A_InfoCheck="checking on Info.plist"
A_alreadyRetina="checking on app"
A_noApp="checking on app directory"

# Error messages
EM_InfoCheck="the app seems malformed."
EM_alreadyRetina="this app already seems retina-ready."
EM_noApp="the housing directory was not found."

# Error codes
EC_InfoCheck="5"
EC_alreadyRetina="10"
EC_noApp="15"

# Defaults
D_whatever=

###\\\
# Function definitions
###///

###\\\
# Process command options
###///

while getopts v: option ; do
	case "$option"
	in
		v)	Gi_verbose=$OPTARG	;;
		\?) synopsis_show
		    exit 0;;
	esac
done

verbosity_check

echo ""
cprint  "hostname"      "[ $(hostname) ]"

shift $(($OPTIND - 1))
lst_APP=$*

topDir=$(pwd)
for file in "$lst_APP" ; do
	lprint "Checking on app dir"
	dirExist_check "$file" || fatal noApp
	lprint "Checking for alreadyRetina on app"
	cd "$file"/Contents >/dev/null 2>/dev/null || fatal InfoCheck
	b_alreadyRetina=$(grep NSHighResolutionCapable Info.plist | wc -l)
	if (( b_alreadyRetina )) ; then fatal alreadyRetina ; fi
	rprint "[ not retina ready ]"
	cd $topDir
	gcp -pvrdi $file /tmp >/dev/null
	rm -fr "$file".orig 2>/dev/null
	mv "$file" "$file".orig
	baseFile=$(basename $file)
	cd /tmp/${baseFile}/Contents
	lprint "Make updates to Info.plist"
	gsed -i.orig 's|</dict>|\t<key>NSPrincipalClass</key>\n\t<string>NSApplication</string>\n\t<key>NSHighResolutionCapable</key>\n\t<true/>\n</dict>|'	Info.plist
	rprint "[ ok ]"
	lprint "Refreshing app cache"
	gcp -pvrdi /tmp/${baseFile} ${topDir}/"$file" >/dev/null
	rprint "[ ok ]"
	rm -fr /tmp/${baseFile}
done

shut_down 0
