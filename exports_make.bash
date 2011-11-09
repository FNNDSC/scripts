#!/bin/bash
#
# Copyright 2011 Rudolph Pienaar, Dan Ginsburg, FNNDSC
# Childrens Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash
declare -i Gi_verbose=0

G_STYLE=$(uname)

G_HOST="-x"

G_SYNOPSIS="

  NAME

        exports_make.bash

  SYNOPSIS
  
        exports_make.bash -s <'Darwin'|'Linux'> [-v <verbosityLevel>]
                          <DIR1> <DIR2> ... <DIRn>

  DESC

        'exports_make.bash' generates and prints to stdout an exports
        file for either Darwin or Linux, exporting the <DIR> <DIR2>...
        to all the remote subnets that subserve the FNNDSC.

  ARGS
        
	-v <verbosityLevel> (Optional)
	Verbosity level. A value of '10' is a good choice here.

        -s <'Darwin'|'Linux'>
        Style of /etc/exports to use. Will default to the style
        of the current host script is being run off.
        
  HISTORY
    
  26 April 2011
  o Initial design and coding.

"

A_args="checking command line arguments"

EM_args="you *must* specify either '-s Linux' or '-s Darwin'."

EC_args=10

while getopts v:s: option ; do
    case "$option" 
    in
        v) Gi_verbose=$OPTARG   ;;
        s) G_STYLE=$OPTARG      ;;
	\?) synopsis_show ; shut_down 10 ;;
    esac
done

G_STYLE=$(string_clean $G_STYLE)
if [[ $G_STYLE != "Linux" && $G_STYLE != "Darwin" ]] ; then fatal args;   fi

sitenum=13

# Format: <label>;<netmask>
NETMASK[0]="1 Autumn Street, 6th floor;10.17.24.0"
NETMASK[1]="1 Autumn Street, 4th floor;10.17.16.0"
NETMASK[2]="Needham Data Center (PICES cluster);10.36.133.0"
NETMASK[3]="Neuroradiology Reading Room;10.28.8.0"
NETMASK[4]="Enders, 9th floor;10.7.34.0"
NETMASK[5]="Waltham (0027 -GR);10.64.60.0"
NETMASK[6]="Waltham (WL13W3 - subnet 1);10.64.4.0"
NETMASK[7]="Waltham (WL13W3 - subnet 2);10.64.5.0"
NETMASK[8]="Waltham (WL13W3 - subnet 3);10.64.84.0"
NETMASK[9]="1 Autumn Street, TCHpeap subnet 1;10.23.50.0"
NETMASK[10]="1 Autumn Street, TCHpeap subnet 2;10.23.130.0"
NETMASK[11]="1 Autumn Street, TCHpeap subnet 3;10.23.129.0"
NETMASK[12]="Main CHB Campus, 3D Lab;10.3.2.0"

shift $(($OPTIND - 1))
EXPORTLIST=$*

if (( ${#EXPORTLIST} )) ; then
    # On Darwin, we have all the mount points specified in one entry, but
    # only a single subnet per entry.
    if [[ $G_STYLE == "Darwin" ]] ; then
        for SITE in $(seq 0 $(expr $sitenum - 1)) ; do
            COMMENT=$(echo ${NETMASK[$SITE]} | awk -F \; '{print $1}')
            SUBNET=$(echo ${NETMASK[$SITE]} | awk -F \; '{print $2}')
            echo "# $COMMENT"
            echo "$EXPORTLIST     -alldirs -maproot=rudolphpienaar -network $SUBNET -mask 255.255.255.0"
            echo ""
        done
    fi

    # On Linux, we have all the subnets in one line, but only a single
    # mount entry.
    if [[ $G_STYLE == "Linux" ]] ; then
        # First collect all the subnets
        lst_SUBNET=""
        lst_LOOKUP=$(printf "%-40s%-35s" "# Site Description" "subnet")
        for SITE in $(seq 0 $(expr $sitenum - 1)) ; do
            COMMENT=$(echo ${NETMASK[$SITE]} | awk -F \; '{print $1}')
            SUBNET=$(echo ${NETMASK[$SITE]} | awk -F \; '{print $2}')
            lst_SUBNET=$(echo "$lst_SUBNET $SUBNET")
            lst_LOOKUP=$(printf "%s\n%-40s%-35s" "$lst_LOOKUP" "# $COMMENT" "$SUBNET")
        done
        echo "$lst_LOOKUP"
        echo "#"
        echo ""
        for MOUNTPOINT in $EXPORTLIST ; do
            printf "%-45s" "$MOUNTPOINT"
            for SUBNET in $lst_SUBNET ; do
                echo -n "${SUBNET}/24(rw,insecure,root_squash,async,no_subtree_check) "
            done
            echo ""
        done
    fi
fi




