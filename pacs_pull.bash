#!/bin/bash
#
# Copyright 2010 Rudolph Pienaar, Dan Ginsburg, FNNDSC
# Childrens Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash
declare -i Gi_verbose=0
declare -i Gb_queryOnly=0
declare -i Gb_final=0

declare -i Gb_dateSpecified=0

MRN="-x"

G_SCANDATE=""
G_FINDSCUSTD=/tmp/${G_SELF}_${G_PID}_findscu.std
G_FINDSCUERR=/tmp/${G_SELF}_${G_PID}_findscu.err

G_AETITLE=rudolphpienaar
G_QUERYHOST=134.174.12.21
G_QUERYPORT=104
G_CALLTITLE=osx1927
G_RCVPORT=11112

G_SYNOPSIS="

  NAME

        pacs_pull.bash

  SYNOPSIS
  
        pacs_pull.bash  -M <MRN>                                        \\
                        [-Q]                                            \\
                        [-D <scandate>]                                 \\
                        [-a <aetitle>]                                  \\
                        [-P <PACShost>]                                 \\
                        [-p <PACSport>]                                 \\
                        [-v <verbosityLevel>]

  DESC

        'pacs_pull.bash' queries and pulls studies of interest from a 
        PACS, pulling DICOM data to <calltitle>:<localPort>.

  ARGS

        -M <MRN>
        MRN to query.
        
        -Q
        If specified, query only and do not retrieve.
        
        -D <scandate>
        Scan date. If not specified, will collect *all* matches. Use with
        some care.

        -a <aetitle> (Optional $G_AETITLE)
        Local AETITLE.
        
        -c <calltitle> (Optional $G_CALLTITLE)
        
        
        -l <localPort> (Optional $G_RCVPORT)
        The port on 
        
        -P <PACShost> (Optional $G_QUERYHOST)
        The PACS host to query.

        -p <PACSport> (Optional $G_QUERYPORT)
        The port on <PACShost>.        
        
	-v <verbosityLevel> (Optional)
	Verbosity level. A value of '10' is a good choice here.
        
  HISTORY
    
  20 April 2011
  o Initial design and coding.

"

A_MRN="checking command line args"

EM_MRN="I couldn't find -M <MRN>. This is a required key.'"

EC_MRN=10

function bracket_find
{
    TEXT=$1
    FIND=$(echo $TEXT | sed -e 's/.*\[\([^]]*\)\].*/\1/g')
    echo $FIND
}

while getopts M:QD:a:c:l:P:p:v: option ; do
    case "$option" 
    in
        v) Gi_verbose=$OPTARG   ;;
        M) MRN=$OPTARG          ;;
        Q) let Gb_queryOnly=1   ;;
        D) G_SCANDATE=$OPTARG   ;;
        a) G_AETITLE=$OPTARG    ;;
        c) G_CALLTITLE=$OPTARG  ;;
        l) G_RCVPORT=$OPTARG    ;;
        P) G_QUERYHOST=$OPTARG  ;;
        p) G_QUERYPORT=$OPTARG  ;;
        *) synopsis_show        ;;
    esac
done

if [[ $MRN == "-x"      ]] ; then fatal MRN;            fi
if (( ${#G_SCANDATE}    )) ; then Gb_dateSpecified=1;   fi

cprint "Querying for MRN" "[ $MRN ]" 

if (( Gb_dateSpecified )) ; then
    cprint "Querying for SCANDATE" "[ $G_SCANDATE ]" 
else
    cprint "Querying for SCANDATE" "[ unspecified ]"
fi

statusPrint "" "\n"



# Query the PACS for MRN and modality MR, 
# returning dates and studyinstanceUID
findscu -xi -S --aetitle $G_AETITLE -k 0008,0052=STUDY -k 0010,0020=$MRN \
         -k 0008,0060="MR"                                               \
         -k 0008,0020=                                                   \
         -k 0020,000d                                                    \
         $G_QUERYHOST $G_QUERYPORT > $G_FINDSCUSTD 2> $G_FINDSCUERR

Gb_final=$(( Gb_final || $? ))

b_dateHit=0
while read line ; do
    DA=$(echo "$line" | grep "0008,0020")
    if (( ${#DA} )) ; then
        STUDYDATE=$(bracket_find "$DA")
        if (( !Gb_dateSpecified )) ; then
            b_dateHit=1
        elif [[ $G_SCANDATE == $STUDYDATE ]] ; then
            b_dateHit=1    
        fi
    fi
    UI=$(echo "$line" | grep "0020,000d")
    if (( ${#UI} && b_dateHit )) ; then
        cprint "Found hit at StudyDate" "[ $STUDYDATE ]"
        if (( !Gb_queryOnly )) ; then
            lprint "Starting PACS retrieve..."
            STUDYUID=$(bracket_find "$UI")
   	    # Grab the result from the PACS
            PULL="movescu  --aetitle ${G_AETITLE}                             \
                           --move $G_AETITLE --study                          \
                           -k 0008,0052=STUDY                                 \
                           -k 0020,000D=${STUDYUID}                           \
                           $G_QUERYHOST $G_QUERYPORT"
            eval "$PULL"
            rprint "[ $? ]"
            Gb_final=$(( Gb_final || $? ))
        fi
        b_dateHit=0
    fi
done < $G_FINDSCUSTD

rm $G_FINDSCUERR
rm $G_FINDSCUSTD

exit $Gb_final



