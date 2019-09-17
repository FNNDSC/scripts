#!/bin/bash 

# "include" the set of common script functions
source common.bash

declare -i ROWS=4
declare -i COLS=3
declare -i width=200
declare -i widthOffset=200
declare -i height=100
declare -i X=0
declare -i Y=0

declare -i b_tunnelUse=0
declare -i sleepBetweenLoop=0
declare -i b_continueProcessing=0
tunnelUser="rudolph"
tunnelHost="localhost"
tunnelPort=4216
hostIgnore=""
onlyTheseHosts=""

bg="black"
fg="purple"
user="rudolphpienaar"

GROUP=PICES

source machines.sh

G_SYNOPSIS="

  NAME

        net-xload.sh

  SYNOPSIS
  
        net-xload.sh    [-G <computeGroup>]                             \\
                        [-u <user>]                                     \\
                        [-U <tunnelUser>]                               \\
                        [-P <tunnelPort>]                               \\
                        [-H <tunnelHost>]                               \\
                        [-R <rows>]                                     \\
                        [-C <cols>]                                     \\
                        [-X <tableXOffset>]                             \\
                        [-Y <tableYOffset>]                             \\
                        [-w <xloadWidth>]                               \\
			[-W <xloadWidthOffset>]				\\
                        [-h <xloadHeight>]                              \\
                        [-b <xloadBg>]                                  \\
                        [-f <xloadFg>]                                  \\
			[-s <sleepBetweenLoop>]				\\
                        [-v <verbosityLevel>]

  DESC

        'net-xload.sh' simply opens up a grid of 'xload' instances
        running on each of the PICES hosts, organized into a grid of
        <rows> x <cols> with each xload having given geometry and
        property.

  ARGS
  
        [-G <group>]
        The computing group to monitor. Valid choices are PICES and FNNDSC.

        [-I <ignoreHostList>]
        A comma separated list of hosts in the compute group to ignore, i.e.
        these hosts are skipped during remote execution.
        
        [-O <onlyTheseHosts>]
        A comma separated list of hosts within a group to examine.

        [-u <user>]
        Remote ssh user -- typically the user on the remote host on 
        which the xload process will run.
        
        [-U <tunnelUser>]
        If access to the remote host is via an ssh tunnel, this 
        arg denotes the tunnel user name.
        
        [-H <tunnelHost>]
        If access to the remote host is via an ssh tunnel, this 
        arg denotes the tunnel origin host.
        
        [-P <tunnelPort>]
        If access to the remote host is via an ssh tunnel, this 
        arg denotes the tunnel port on <tunnelHost>.

        [-R <rows>]
        Number of rows in grid.
        
        [-C <cols>]
        Number of cols in grid.

        [-w <xloadWidth>]
        Width of individual xload panel.
	
	[-W <xloadWidthOffset>]
	Offset width for xload panels in per-row layout. Almost always this will be
	the same as <xloadWidth>. However, in some cases, like macOS, the XQuartz decorator
	places an ugly window decoration in the bottom right of the X11 window. By specifying
	a slightly-less <xloadwidthOffset>, adjacent panels can be rendered over that 
	decoration.
        
        [-h <xloadHeight>]
        Height of individual xload panel.

        [-b <xloadBg>]
        xload panel background color.

        [-f <xloadFg>]
        xload panel foreground color.

	[-s <sleepBetweenLoop>]
	If specified, sleep <sleepBetweenLoop> seconds during each program
	loop. This improves ssh tunnel performance.

"


while getopts u:R:C:w:W:h:b:f:v:X:Y:U:H:P:G:s:I:O: option ; do
    case "$option" 
    in
        u) user=$OPTARG                 ;;
        U) tunnelUser=$OPTARG
           b_tunnelUse=1                ;;
        H) tunnelHost=$OPTARG
           b_tunnelUse=1                ;;
        P) tunnelPort=$OPTARG
           b_tunnelUse=1                ;;
        G) GROUP=$OPTARG                ;;
        I) hostIgnore=$OPTARG           ;;
        O) onlyTheseHosts=$OPTARG       ;;
        v) Gi_verbose=$OPTARG           ;;
        R) ROWS=$OPTARG                 ;;
        C) COLS=$OPTARG                 ;;
        X) X=$OPTARG                    ;;
        Y) Y=$OPTARG                    ;;
        w) width=$OPTARG                
	   widthOffset=$width		;;
	W) widthOffset=$OPTARG		;;
        h) height=$OPTARG               ;;
        b) bg=$OPTARG                   ;;
        f) fg=$OPTARG                   ;;
	s) sleepBetweenLoop=$OPTARG	;;
        *) synopsis_show                ;;
    esac
done

case $GROUP
in 
        PICES)  a_HOST=("${a_PICES[@]}")        ;;
        FNNDSC) a_HOST=("${a_FNNDSC[@]}")       ;;
esac

declare -i i=0

XLOAD=xload
for row in $(seq 0 $((ROWS-1))) ; do
    for col in $(seq 0 $((COLS-1))) ; do
        host=${a_HOST[i]}
        if grep -q $host <<<"$hostIgnore" ; then
            continue
        fi
        if (( ${#onlyTheseHosts} )) ; then
            b_continueProcessing=0
            if grep -q $host <<<"$onlyTheseHosts" ; then 
                    b_continueProcessing=1
            fi
        else
            b_continueProcessing=1
        fi
        if (( b_continueProcessing )) ; then
            x=$((col*widthOffset+X))
            if (( x>=0 )) ; then x="+${x}";  fi
            y=$((row*height+Y))
            if (( y>=0 )) ; then y="+${y}";  fi
	    if [[ "$host" == "tautona" ]] ; then
		    user=rpienaar
	    else
		    user=rudolphpienaar
	    fi
	    if [[ "$host" == "centauri" ]] ; then
		XLOAD=/opt/local/bin/xload	
	    else
		XLOAD=xload
	    fi
            CMD="ssh -X $user@$host $XLOAD -g ${width}x${height}${x}${y} -bg \"$bg\" -fg \"$fg\" &"
	    #echo "b_tunnelUse=$b_tunnelUse"
            if (( b_tunnelUse )) ; then
                CMD="ssh -X -p $tunnelPort ${tunnelUser}@${tunnelHost} $CMD"
            fi
            echo $CMD
            eval "$CMD" &        
	    if (( sleepBetweenLoop )) ;  then
	        sleep $sleepBetweenLoop
	    fi
	fi
        ((i++))
    done
done





