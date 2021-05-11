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
  
        exports_make.bash [-s <'Darwin'|'Linux'>] [-v <verbosityLevel>] \
                          [-n <numberOfExports>]                        \
                          <DIR1> <DIR2> ... <DIRn>

  DESC

        'exports_make.bash' generates and prints to stdout an exports
        file for either Darwin or Linux, exporting the <DIR> <DIR2>...
        to all the remote subnets that subserve the FNNDSC.

  ARGS
        
	-v <verbosityLevel> (Optional)
	Verbosity level. A value of '10' is a good choice here.

	-n <numberOfExports>
	Only generate a file for the first <numberOfExports> in the internal
	table. This is useful for using the same internal table in 
	different network locations.

        -s <'Darwin'|'Linux'>
        Style of /etc/exports to use. Will default to the style
        of the current host script is being run off.
        
  HISTORY
    
  26 April 2011
  o Initial design and coding.

  17 March 2013
  o Add -n <numberOfLocations>.

"

A_host="checking command line arguments"

EM_host="I couldn't identify the underlying env. Specify either '-s Linux' or '-s Darwin'."

EC_host=10

while getopts v:s:n: option ; do
    case "$option" 
    in
        v) Gi_verbose=$OPTARG   ;;
        s) G_STYLE=$OPTARG      ;;
	n) Gb_siteNum=1
	   G_siteNum=$OPTARG	;;
	\?) synopsis_show ; shut_down 10 ;;
    esac
done

G_STYLE=$(string_clean $G_STYLE)
if [[ $G_STYLE != "Linux" && $G_STYLE != "Darwin" ]] ; then fatal args;   fi

if (( Gb_siteNum )) ; then
    sitenum=$G_siteNum
else
    sitenum=67
fi

# Format: <label>;<netmask>
 NETMASK[0]="Local network;192.168.1.0"
 NETMASK[1]="1 Autumn Street, 6th floor;10.17.24.0"
 NETMASK[2]="1 Autumn Street, 4th floor;10.17.16.0"
 NETMASK[3]="Needham Data Center ('P2 CLUSTER');10.36.131.0"
 NETMASK[4]="Needham Data Center ('tautona');10.36.132.0"
 NETMASK[5]="Needham Data Center (PICES cluster);10.36.133.0"
 NETMASK[6]="Neuroradiology Reading Room;10.28.8.0"
 NETMASK[7]="Enders, 9th floor;10.7.34.0"
 NETMASK[8]="Waltham (0027 -GR);10.64.60.0"
 NETMASK[9]="Waltham (WL13W3 - subnet 1);10.64.4.0"
NETMASK[10]="Waltham (WL13W3 - subnet 2);10.64.5.0"
NETMASK[11]="Waltham (WL13W3 - subnet 3);10.64.84.0"
NETMASK[12]="Waltham (Read   - subnet 4);10.65.130.0"
NETMASK[13]="1 Autumn Street, TCHpeap subnet 1;10.23.50.0"
NETMASK[14]="1 Autumn Street, TCHpeap subnet 2;10.23.128.0"
NETMASK[15]="1 Autumn Street, TCHpeap subnet 3;10.23.129.0"
NETMASK[16]="1 Autumn Street, TCHpeap subnet 4;10.23.130.0"
NETMASK[17]="1 Autumn Street, TCHpeap subnet 5;10.23.131.0"
NETMASK[18]="1 Autumn Street, TCHpeap subnet 6;10.23.132.0"
NETMASK[19]="1 Autumn Street, TCHpeap subnet 7;10.23.133.0"
NETMASK[20]="1 Autumn Street, TCHpeap subnet 8;10.23.134.0"
NETMASK[21]="1 Autumn Street, TCHpeap subnet 9;10.23.135.0"
NETMASK[22]="1 Autumn Street, TCHpeap subnet 10;10.23.136.0"
NETMASK[23]="1 Autumn Street, TCHpeap subnet 11;10.23.137.0"
NETMASK[24]="1 Autumn Street, TCHpeap subnet 12;10.23.138.0"
NETMASK[25]="1 Autumn Street, TCHpeap subnet 13;10.23.139.0"
NETMASK[26]="1 Autumn Street, TCHpeap subnet 14;10.23.140.0"
NETMASK[27]="1 Autumn Street, TCHpeap subnet 15;10.23.141.0"
NETMASK[28]="1 Autumn Street, TCHpeap subnet 16;10.23.142.0"
NETMASK[29]="1 Autumn Street, TCHpeap subnet 17;10.23.143.0"
NETMASK[30]="Main CHB Campus, 3D Lab;10.3.2.0"
NETMASK[31]="Engels Lab;10.32.72.0"
NETMASK[32]="Main CHB Campus, Sanjay 1;10.6.60.0"
NETMASK[33]="Main CHB Campus, Sanjay 2;10.211.55.0"
NETMASK[34]="Main CHB Campus, Ed Wang;10.4.46.0"
NETMASK[35]="Main CHB Campus, CRIT-HPC;10.36.142.0"
NETMASK[36]="Main CHB Campus, CRIT-HPC-workers;10.36.149.0"
NETMASK[37]="1 Autumn Street, 5th floor;10.17.20.0"
NETMASK[38]="Binney Street, 7th Floor;10.30.14.0"
NETMASK[39]="Autumn Street, 1st Floor;10.17.4.0"
NETMASK[40]="Autumn Street, 6th Floor;10.23.48.0"
NETMASK[41]="Christos/etc;10.5.14.0"
NETMASK[42]="Christos/etc;10.5.13.0"
NETMASK[43]="1 Autumn Street, TCHpeap subnet 18;10.23.53.0"
NETMASK[44]="1 Autumn Street, TCHpeap subnet 19;10.23.54.0"
NETMASK[45]="Binney Street, 7th Floor;10.30.15.0"
NETMASK[46]="Binney Street, 7th Floor;10.4.44.0"
NETMASK[47]="1 Autumn Street, TCHpeap subnet 20;10.23.57.0"
NETMASK[48]="1 Autumn Street, TCHpeap subnet 21;10.17.12.0"
NETMASK[49]="1 Autumn Street, VPN;172.18.192.0"
NETMASK[50]="1 Autumn Street, TCHpeap subnet 22;10.23.106.0"
NETMASK[51]="7 Landmark, subnet 1;10.72.76.0"
NETMASK[52]="7 Landmark, subnet 2;10.72.77.0"
NETMASK[53]="7 Landmark, subnet 3;10.72.80.0"
NETMASK[54]="7 Landmark, subnet 4;10.72.81.0"
NETMASK[55]="7 Landmark, subnet 5;10.72.82.0"
NETMASK[56]="7 Landmark, subnet 6;10.72.83.0"
NETMASK[57]="7 Landmark, subnet 6;10.72.84.0"
NETMASK[58]="7 Landmark, subnet 7;10.72.85.0"
NETMASK[59]="7 Landmark, subnet 8;10.72.86.0"
NETMASK[60]="7 Landmark, wifi subnet 1;10.23.58.0"
NETMASK[61]="7 Landmark, wifi subnet 2;10.23.59.0"
NETMASK[62]="7 Landmark, wifi subnet 3;10.23.56.0"
NETMASK[63]="7 Landmark, wifi subnet 4;10.23.55.0"
NETMASK[64]="Sanjay 3D Lab;10.16.7.0"
NETMASK[65]="Sanjay 3D Lab;10.3.70.0"
NETMASK[66]="e2 cluster;10.36.172.0"
NETMASK[67]="6 Landmark, subnet 1; 10.72.9.0"
NETMASK[68]="6 Landmark, subnet 2; 10.72.8.0"

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
            printf "%-45s  " "$MOUNTPOINT"
            for SUBNET in $lst_SUBNET ; do
                echo -n "${SUBNET}/24(rw,insecure,root_squash,async,no_subtree_check) "
                #echo -n "${SUBNET}/24(rw,insecure,no_root_squash,async,no_subtree_check) "
            done
            echo ""
            echo ""
        done
    fi
fi




