#!/bin/bash
#
# Copyright 2010 Rudolph Pienaar, Dan Ginsburg, FNNDSC
# Childrens Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash
declare -i Gi_verbose=1
declare -i Gb_queryOnly=0
declare -i Gb_final=0
declare -i Gb_metaInfoPrinted=0

declare -i Gb_dateSpecified=0

# User searchable fields
# Fields initialised with "-x" must be specified by the user
# when running this script
G_PATIENTID="-x"
G_QUERYRETRIEVELEVEL=""
G_MODALITY="MR"
G_PATIENTSNAME=""
G_SERIESDESCRIPTION=""
G_STUDYINSTANCEUID=""
G_SCANDATE=""



G_FINDSCUSTUDYSTD=/tmp/${G_SELF}_${G_PID}_findscu_study.std
G_FINDSCUSTUDYERR=/tmp/${G_SELF}_${G_PID}_findscu_study.err
G_FINDSCUSERIESSTD=/tmp/${G_SELF}_${G_PID}_findscu_series.std
G_FINDSCUSERIESERR=/tmp/${G_SELF}_${G_PID}_findscu_series.err

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

        It is usually driven by specifying an MRN, with an optional <scandate>
        and <seriesDescription>. If all three tags are specified, a single
        series is requested. If the <seriesDescription> is omitted, then
        all series corresponding to the <MRN> and <scandate> are retrieved.
        If in addition the <scandate> is omitted, then all series on all
        dates are retrieved. If only the <MRN> and <seriesDescription> are
        specified, then only that series but across all available dates
        is retrieved.

  ARGS

        -M <MRN>
        MRN to query.
        
        -Q
        If specified, query only and do not retrieve.
        
        -D <scandate>
        Scan date. If not specified, will collect *all* matches. Use with
        some care.

        -a <aetitle> (Optional $G_AETITLE)
        Local AETITLE. This is the only field that the CHB PACS seems to care 
        about. Queries are retrieved to the host:port that is associated
        with this <aetitle>.
                
        -P <PACShost> (Optional $G_QUERYHOST)
        The PACS host to query.

        -p <PACSport> (Optional $G_QUERYPORT)
        The port on <PACShost>.        
        
	-v <verbosityLevel> (Optional)
        This script defaults to a verbosityLevel of '1'. To be most
        verbose, use a level of '10'.
        
  HISTORY
    
  20 April 2011
  o Initial design and coding.

"

A_MRN="checking command line args"

EM_MRN="I couldn't find -M <MRN>. This is a required key.'"

EC_MRN=10

# DICOM tag label
G_QueryRetrieveLevel="0008,0052"
G_PatientsName="0010,0010"
G_SeriesDescription="0008,103e"
G_StudyInstanceUID="0020,000d"
G_PatientID="0010,0020"
G_Modality="0008,0060"
G_StudyDate="0008,0020"
G_PatientAge="0010,1010"
G_PatientBirthDate="0010,0030"

function bracket_find
{
    TEXT=$1
    FIND=$(echo $TEXT | sed -e 's/.*\[\([^]]*\)\].*/\1/g')
    echo $FIND
}

function PACSdata_size
{
  seriesSize=$(/bin/ls -l $G_FINDSCUSERIESSTD | awk '{printf $5}')
  studySize=$(/bin/ls -l $G_FINDSCUSTUDYSTD | awk '{printf $5}')
  cprint "Size of Study MetaInfo" "[ $studySize ]"
  cprint "Size of Series MetaInfo" "[ $seriesSize ]"
}

function DICOMline_scanFor
{
    line="$1"
    scanFor="$2"
    echo "$line"
    echo "$scanFor"
    FOUND=$(echo "$line"        | grep "$scanFor")
    if (( ${#FOUND} )) ; then
        HIT=$(bracket_find "$FOUND")
        echo $HIT
    fi
}

while getopts M:QD:a:c:l:P:p:v: option ; do
    case "$option" 
    in
        v) Gi_verbose=$OPTARG   ;;
        M) G_PATIENTID=$OPTARG  ;;
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

if [[ $G_PATIENTID == "-x"      ]] ; then fatal MRN;            fi
if (( ${#G_SCANDATE}            )) ; then Gb_dateSpecified=1;   fi

cprint "Querying for MRN" "[ $G_PATIENTID ]"

if (( Gb_dateSpecified )) ; then
    cprint "Querying for SCANDATE" "[ $G_SCANDATE ]" 
else
    cprint "Querying for SCANDATE" "[ unspecified ]"
fi

statusPrint "" "\n"


# We perform two queries off 'findscu'. The first at the STUDY level
# collects the StudyInstanceUID. The second, at the SERIES level,
# collects all the SeriesDescriptions.

# First, query the PACS for StudyInstanceUID. This is a unique tag, and
# in this case the combination of MRN:SCANDATE is a unique specifier. If
# the date is not specified, then multiple StudyInstanceUIDs are returned.
QUERYSTUDY="findscu -xi -S --aetitle $G_AETITLE                         \
         -k $G_QueryRetrieveLevel=STUDY                                 \
         -k $G_PatientID=$G_PATIENTID                                   \
         -k $G_Modality=$G_MODALITY                                     \
         -k $G_StudyDate=$G_SCANDATE                                    \
         -k $G_PatientsName=$G_PATIENTSNAME                             \
         -k $G_StudyInstanceUID=                                        \
         $G_QUERYHOST $G_QUERYPORT > $G_FINDSCUSTUDYSTD 2> $G_FINDSCUSTUDYERR"

QUERY="$QUERYSTUDY"
eval "$QUERY"
UILINE=$(cat $G_FINDSCUSTUDYSTD| grep StudyInstanceUID)
# echo "UILINE=$UILINE"
UI=$(echo "$UILINE" | awk '{print $3}')
# echo "UI=$UI"

# Now collect the Series information
rm -f $G_FINDSCUSERIESSTD
rm -f $G_FINDSCUSERIESERR
if (( ${#UI} )) ; then
  printf "StudyInstanceUID hits:\n"
  for currentUIb in $UI ; do
    currentUI=$(bracket_find $currentUIb)
    statusPrint "Collecting series information for $currentUI" "\n"
    QUERYSERIES="findscu -v -S --aetitle $G_AETITLE                     \
         -k $G_QueryRetrieveLevel=SERIES                                \
         -k $G_PatientID=$G_PATIENTID                                   \
         -k $G_Modality=$G_MODALITY                                     \
         -k $G_StudyDate=$G_SCANDATE                                    \
         -k $G_PatientsName=$G_PATIENTSNAME                             \
         -k $G_PatientBirthDate=                                        \
         -k $G_StudyInstanceUID=$currentUI                              \
         -k $G_SeriesDescription=\"$G_SERIESDESCRIPTION\"               \
         $G_QUERYHOST $G_QUERYPORT >> $G_FINDSCUSERIESSTD 2>> $G_FINDSCUSERIESERR"
    eval "$QUERYSERIES"
  done
  echo ""
  PACSdata_size    
else
  echo ""
  statusPrint "No hits returned for MRN $G_PATIENTID."
  echo ""
  shut_down 1
fi

lprint "Cleaning Series MetaInfo"
cp $G_FINDSCUSERIESSTD $G_FINDSCUSERIESSTD.bak
blockFilter.py -f $G_FINDSCUSERIESSTD.bak -s Unknown -u Dicom-Data > $G_FINDSCUSERIESSTD
rm $G_FINDSCUSERIESSTD.bak
rprint "[ ok ]"
lprint "Filtering down UI list"
UILINE=$(cat $G_FINDSCUSERIESSTD| grep StudyInstanceUID | uniq)
UI=$(echo "$UILINE" | awk '{print $3}')
rprint "[ ok ]"
PACSdata_size
echo ""

if (( Gi_verbose == 10 )) ; then
    echo -e "QUERYSERIES: "
    echo $QUERYSERIES
    cat $G_FINDSCUSERIESSTD
fi
Gb_final=$(( Gb_final || $? ))

b_dateHit=0
for currentUIb in $UI ; do
  currentUI=$(bracket_find $currentUIb)
  statusPrint "$currentUI" "\n"
  Gb_metaInfoPrinted=0
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
    UILINE=$(echo "$line"       | grep "$G_StudyInstanceUID")
    STUDYUID=$(bracket_find "${UILINE}")

    tBIRTHDATE=$(echo "$line"   | grep "$G_PatientBirthDate")
    if (( ${#tBIRTHDATE} )) ; then BIRTHDATE=$(bracket_find "$tBIRTHDATE"); fi

    tNAME=$(echo "$line"        | grep "$G_PatientsName")
    if (( ${#tNAME} )) ; then   NAME=$(bracket_find "$tNAME");    fi

    tSERIES=$(echo "$line"      | grep "$G_SeriesDescription")
    if (( ${#tSERIES} )) ; then
        SERIES=$(bracket_find "$tSERIES")
        b_seriesOK=$(echo "$SERIES" | grep -v "no value" | wc -l)
    fi
    if [[ ${STUDYUID} == $currentUI && $b_dateHit == 1 && $b_seriesOK == 1 ]] ; then
        if (( !Gb_metaInfoPrinted )) ; then
            cprint "Patient Name"       "$NAME"
            cprint "Patient MRN"        "$G_PATIENTID"
            cprint "Scan Date"          "$STUDYDATE"
            cprint "Patient Birthdate"  "$BIRTHDATE"
            cprint "Patient Age"        "$(age_calc.py $STUDYDATE $BIRTHDATE)"
            echo ""
            Gb_metaInfoPrinted=1
            if (( !Gb_queryOnly )) ; then
                lprint "Starting PACS retrieve..."
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
        fi
        cprint "Series" "$SERIES"
        b_dateHit=0
    fi
  done < $G_FINDSCUSERIESSTD
done

rm $G_FINDSCUSTUDYERR
rm $G_FINDSCUSTUDYSTD
rm $G_FINDSCUSERIESERR
rm $G_FINDSCUSERIESSTD

exit $Gb_final



