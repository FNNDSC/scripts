#!/bin/bash
#
# tractBatch_create.bash
#
# Copyright 2009 Rudolph Pienaar
# Childrens Hospital Boston
#
# SPDX-License-Identifier: MIT
#

# "include" the set of common script functions
source common.bash

declare -i Gi_verbose=0
declare -i Gb_forceStage=1
declare -i Gb_loopOverride=0
declare	-i Gb_printNullEntries=0
declare -i Gb_fuzzySearch=0

G_LOGDIR=$(pwd)
G_TABLEFILE="-x"
G_DEFAULTDIR="/space/kaos/1/users/dicom/files"
G_DEFAULTCOM="-v 10 -t 12"
G_SERIESLIST="ISODIFFUSION,ISODIFFUSIONTRUEAXIAL,DIFFUSION"
G_OUTPUTSUFFIX=""
G_DIRSUFFIX=""
G_DCMMRIDTABLE=${G_DEFAULTDIR}/dcm_MRID_age.log

G_SYNOPSIS="

 NAME

	tractBatch_create.bash

 SYNOPSIS

	tractBatch_create.bash  -t <batchTableFile>                   	\\
                                [-C <DEFAULTCOM>] 			\\
                                [-D <DEFAULTDIR>]                       \\
                                [-S <SERIESLIST>]                       \\
                                [-o <outputSuffix>]                     \\
                                [-R <DIRSUFFIX>]                        \\
				[-A]					\\
                                [-z]                                    \\
                                [-v <verbosity>]                        \\
                                <MRID1>... <MRIDn>

 DESCRIPTION

	'tractBatch_create.bash' builds a <batchTableFile> that contains 
        a set of runs to process for the passed <MRID1>... <MRIDn>. 

 BATCH TABLE
 
        The <batchTable> contains a table denoting a set of runs.

        A set of common command line arguments can be defined in a line
        starting with the text 'DEFAULTCOM', followed by a '=',
        followed by the command line options themselves.
        
        Usually the DICOM data to be processed is grouped together as a
        set of study-specific directories stored in a base directory. This
        base directory can be specified with the command 'DEFAULTDIR'.

        The table itself comprises a semi-colon delimted set of four
        columns:

              <DICOMDIR>;<dcmSeriesFile>;<outputSuffix>;<DIRsuffix>

        where <DICOMDIR> is the directory within DEFAULTDIR to process,
        <dcmSeriesFile> is a file in the series to process, and <outputSuffix>
        a descriptive text for the run (this should NOT contain any spaces).
        The <DIRsuffix> denotes a descriptive suffix for the acutal directory
        housing the final post-processing run, typically <MRID><DIRsuffix>.

 ARGUMENTS

	-v <level> (Optional)
	Verbosity level. A value of '10' is a good choice here.

	-t <batchTableFile>
        The table file to create.
    
        -z (Optional)
        If specified, use a 'fuzzy' search as opposed to an exact match.
        The fuzzy search is essentially a 'grep -i' substring search.
	
	-A
	If specified, turn ON printing null entries to the table. Null entries
	are directories that contain the passed MRID, but do not contain any
	studies in the SERIESLIST. These are preceded by a comment char and
	are not processed. Useful mainly for debugging/testing.

        -C <DEFAULTCOM>
        The default command line string.
        
        -D <DEFAULTDIR>
        The default dicom files directory.
        
        -S <SERIESLIST>
        A comma-separated list of sequence series names to batch process. If
        multiple hits are found in the study, these are appended to the 
        <DIRSUFFIX>.

        -o <outputSuffix>
        The output suffix to add to each volume file. Note that the subject
        age is appended automatically.

        -R <DIRSUFFIX>
        The output dir suffix to add to each processed directory. Note that the
        subject age is appended automatically.

 PRECONDITIONS
	
	o A FreeSurfer 'std' or 'dev' environment.

        o 'tract_meta.bash' and related.

 POSTCONDITIONS

        o A table file suitable for processing by 'tract_batch.bash' is created.

 HISTORY

	11 May 2009
	o Initial design and coding.
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///


# Actions
A_noTableFileArg="checking on -t <batchTableFile> argument"
A_noTableFile="checking on the table file"
A_noDicomDir="checking on input DICOM directory"
A_noDicomFile="checking on input DICOM directory / file"
A_stageRun="running a stage in the processing pipeline"
A_fileCheck="checking the processing environment"
A_noMRID="checking on passed MRID list"

# Error messages
EM_noTableFileArg="it seems as though you didn't specify a -t <batchTableFile>."
EM_noTableFile="I couldn't access the file. Does it exist? Do you have access rights?"
EM_noDicomDir="I couldn't access the input DICOM dir. Does it exist?"
EM_noDicomFile="I couldn't find any DICOM *dcm files. Do any exist?"
EM_stageRun="I encountered an error processing this stage."
EM_fileCheck="I couldn't find one of the required files."
EM_noMRID="I couldn't find any MRIDs."

# Error codes

EC_noTableFile=41
EC_noDicomDir=50
EC_noTableFileArg=51
EC_noDicomFile=52
EC_stageRun=30
EC_fileCheck=40
EC_noMRID=41

# Defaults
D_whatever=

###\\\
# Function definitions
###///

###\\\
# Process command options
###///

while getopts v:t:C:D:S:o:R:Az option ; do
	case "$option"
	in
		v) 	Gi_verbose=$OPTARG		;;
		t)	G_TABLEFILE=$OPTARG		;;
                C)      G_DEFAULTCOM=$OPTARG            ;;
                D)      G_DEFAULTDIR=$OPTARG            ;;
                S)      G_SERIESLIST=$OPTARG            ;;
                o)      G_OUTPUTSUFFIX=$OPTARG          ;;
                R)      G_DIRSUFFIX=$OPTARG             ;;
                A)	Gb_printNullEntries=1		;;
                z)      Gb_fuzzySearch=1                ;;
		\?) synopsis_show
		    exit 0;;
	esac
done

verbosity_check

echo ""
cprint  "hostname"      "[ $(hostname) ]"

## Check on script preconditions
REQUIREDFILES="common.bash tract_meta.bash"

for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file"
        file_checkOnPath $file || fatal fileCheck
done

statusPrint     "Checking on table-of-contents lookup"
fileExist_check $G_DCMMRIDTABLE || fatal fileCheck

## Check on input table file 
statusPrint     "Checking -t <batchTableFile>"
if [[ "$G_TABLEFILE" == "-x" ]] ; then fatal noTableFileArg ; fi
ret_check $?

## Create table intro

INTRO="
# 
# This table defines a batch run geared towards processing
# several file sets concurrently on the 'launchpad' cluster
#
# The format of each run specification is:
#
#       <DICOMDIR>;<dcmSeriesFile>;<outputSuffix>;<DIRsuffix>
#
# where:
#
#       <DICOMDIR>      : The directory containing the study.
#       <dcmSeriesFile> : A single file in the target series.
#       <outputSuffix>  : Some output suffix describing the
#                         processing run. This is appended to
#                         actual processed *filenames*.
#       <DIRsuffix>     : An output suffix that is appended
#                         to processed *dirnames*.
#
# NOTE!
#       To run multiple analyses on a single <DICOMDIR> be sure
#       to specify a <DIRsuffix>, otherwise different runs will
#       result in log-file interference.
#
#

# The DEFAULTCOM line defines command line options used for each
# run.
DEFAULTCOM=$G_DEFAULTCOM

# The DEFAULTDIR line specifies the base directory containing
# all the DICOM studies
DEFAULTDIR=$G_DEFAULTDIR

# The following lines are the actual batch set specifications,
# one per line.
"

ARGLIST=$*
shift $(($OPTIND - 1))
MRIDLIST=$*
if (( ! ${#MRIDLIST} )) ; then fatal noMRID ; fi

DATE=$(date)

## Main processing start
STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($(pwd) $G_SELF $ARGLIST" $STAMPLOG

SPCSUB="-={GR}=-"
echo "$INTRO" > $G_TABLEFILE
for MRID in $MRIDLIST ; do
  cprint "MRID" "[ $MRID ]"
  DIRTABLE=$(cat $G_DCMMRIDTABLE | grep $MRID | sed 's/ /$SPCSUB/g')
  let dirCount=1
  for line in $DIRTABLE ; do
    line=$(echo $line | sed 's/$SPCSUB/ /g')
    STUDYDIR=$(echo $line | awk '{print $1}')
    STUDYAGE=$(echo $line | awk '{print $3}')
    lprint $STUDYDIR
    WD=${G_DEFAULTDIR}/$STUDYDIR
    echo "" >> $G_TABLEFILE
    echo "# $MRID"      >> $G_TABLEFILE
    if [[ ! -f ${WD}/toc.txt ]] ; then
      rprint "[ No toc.txt ]"
      echo "# $MRID -- no toc.txt file found!" >> $G_TABLEFILE
    else
      rprint "[ toc.txt ]"
      let seriesCount=1
      SCANDATE=$(cat ${WD}/toc.txt | grep Date | awk '{print $NF}')
      exec <${WD}/toc.txt
      b_tocHit=0
      while read tocLine ; do
        DCM=$(echo $tocLine | grep "dcm")
        if (( ${#DCM} )) ; then
          SCANDESC=$(echo $tocLine | awk '{for(i=3; i<=NF; i++) printf("%s", $i);}')
          lprint "Testing $SCANDESC"
          b_hit=0
          for targetScan in $(echo $G_SERIESLIST | tr ',' ' ') ; do
            if (( !Gb_fuzzySearch )) ; then 
                if [[ $targetScan == $SCANDESC ]] ; then
                    b_hit=1
                    break
                fi
            else
                echo ""
                echo "targetScan = " $targetScan
                echo "SCANDESC   = " $SCANDESC
                b_hit=$(echo $SCANDESC | grep -i $targetScan | wc -l)
                echo "b_hit      = " $b_hit
            fi
          done
          if (( b_hit == 1 )) ; then
            b_tocHit=1
            SCANFILE=$(echo $tocLine | awk '{print $2}')
            ENTRY="$STUDYDIR;$SCANFILE;-${SCANDATE}_$STUDYAGE-D$dirCount-S$seriesCount$G_OUTPUTSUFFIX;-${SCANDATE}_$STUDYAGE-D$dirCount-S$seriesCount$G_DIRSUFFIX"
            echo $ENTRY >> $G_TABLEFILE
            rprint "[ $SCANFILE-$seriesCount ]"
            seriesCount=$(expr $seriesCount + 1)
          else
            rprint "[ Not tagged ]"
          fi
        fi
      done
      if (( ! b_tocHit )) ; then 
        if (( Gb_printNullEntries )) ; then
	    echo "#$STUDYDIR;-no scan found-;;" >> $G_TABLEFILE 
	fi
      fi
    fi
  dirCount=$(expr $dirCount + 1)
  done
done

printf "%40s" "Cleaning up"
shut_down 0

