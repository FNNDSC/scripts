#!/bin/bash
#
# asladcBatch_create.bash
#
# Copyright 2009 Rudolph Pienaar
# Childrens Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

declare -i Gi_verbose=0
declare -i Gb_forceStage=1
declare -i Gb_loopOverride=0
declare	-i Gb_printNullEntries=0

G_LOGDIR=$(pwd)
G_TABLEFILE="-x"
G_DEFAULTDIR="/chb/users/dicom/files"
G_DEFAULTCOM="-v 10 -t 12"
G_SERIESLIST="ADC,ASLCBF,ZERO-B"
G_OUTPUTSUFFIX=""
G_DIRSUFFIX=""
G_DCMMRIDTABLE=${G_DEFAULTDIR}/dcm_MRID_age.log

G_SYNOPSIS="

 NAME

	asladcBatch_create.bash

 SYNOPSIS

	asladcBatch_create.bash  -t <batchTableFile>                   	\\
                                [-C <DEFAULTCOM>] 			\\
                                [-D <DEFAULTDIR>]                       \\
                                [-S <SERIESLIST>]                       \\
                                [-R <DIRSUFFIX>]                        \\
				[-A]					\\
                                [-v <verbosity>]                        \\
                                <MRID1>... <MRIDn>

 DESCRIPTION

	'asladcBatch_create' builds a <batchTableFile> that contains 
        a set of runs to process for the passed <MRID1>... <MRIDn>. 

 BATCH TABLE
 
        The <batchTable> contains a table denoting a set of runs.

        A set of common command line arguments can be defined in a line
        starting with the text 'DEFAULTCOM', followed by a '=',
        followed by the command line options themselves.
        
        Usually the DICOM data to be processed is grouped together as a
        set of study-specific directories stored in a base directory. This
        base directory can be specified with the command 'DEFAULTDIR'.

        The table itself comprises a semi-colon delimted set of six 
        columns:

    <DICOMDIR>;<ASLseriesFile>;<ADCseriesFile>;<B0seriesFile>;<DIRsuffix>

        where <DICOMDIR> is the directory within DEFAULTDIR to process,
	the <ASLseriesFile>, <ADCseriesFile>, and <B0seriesFile> input vols,
        <DIRSUFFIX> is a descriptive text suffix for the run (this 
        should NOT contain any spaces) that defines a suffix for processed
        directories.

 ARGUMENTS

	-v <level> (Optional)
	Verbosity level. A value of '10' is a good choice here.

	-t <batchTableFile>
        The table file to create.
	
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

        -R <DIRSUFFIX>
        The output dir suffix to add to each processed directory. Note that the
        subject age is appended automatically.

 PRECONDITIONS
	
	o A FreeSurfer 'std' or 'dev' environment.

        o 'asladc_b0_process.bash' and related.

 POSTCONDITIONS

        o A table file suitable for processing by 'asladc_batch.bash' is created.

 HISTORY

	11 May 2009
	o Initial design and coding.
	
	18 May 2009
	o Update and removed '-o'.
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

while getopts v:t:C:D:S:R:A option ; do
	case "$option"
	in
		v) 	Gi_verbose=$OPTARG		;;
		t)	G_TABLEFILE=$OPTARG		;;
                C)      G_DEFAULTCOM=$OPTARG            ;;
                D)      G_DEFAULTDIR=$OPTARG            ;;
                S)      G_SERIESLIST=$OPTARG            ;;
                R)      G_DIRSUFFIX=$OPTARG             ;;
                A)	Gb_printNullEntries=1		;;
		\?) synopsis_show
		    exit 0;;
	esac
done

verbosity_check

echo ""
cprint  "hostname"      "[ $(hostname) ]"

## Check on script preconditions
REQUIREDFILES="common.bash asladc_batch.bash"

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
# several file sets concurrently on the seychelles cluster
#
# The format of each run specification is:
#
#       <DICOMDIR>;<ASLseriesFile>;<ADCseriesFile>;<B0seriesFile>;<DIRsuffix>
#
# where:
#
#       <DICOMDIR>      : The directory containing the study.
#       <ASLseriesFile> : A single file in the ASL series.
#       <ADCseriesFile> : A single file in the ADC series.
#       <B0seriesFile>  : A single file in the B0  series.
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

SPCSUB=".={GR}=."
echo "$INTRO" > $G_TABLEFILE
for MRID in $MRIDLIST ; do
  cprint "MRID" "[ $MRID ]"
  DIRTABLE=$(cat $G_DCMMRIDTABLE | grep $MRID | sed 's/^ *//;s/ *$//;s/[ \t] \+/'$SPCSUB'/g')
  let dirCount=1
  for line in $DIRTABLE ; do
    line=$(echo $line | sed 's/'$SPCSUB'/ /g')
    STUDYDIR=$(echo "$line" | awk '{print $1}')
    STUDYAGE=$(echo "$line" | awk '{print $3}')
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
      b_ADChit=0
      b_ASLhit=0
      b_B0hit=0
      while read tocLine ; do
        DCM=$(echo $tocLine | grep "dcm")
        if (( ${#DCM} )) ; then
          SCANDESC=$(echo $tocLine | awk '{for(i=3; i<=NF; i++) printf("%s", $i);}')
          lprint "Testing $SCANDESC"
          b_hit=0

          b_hit=$(echo "$SCANDESC" | grep -i "ADC" | wc -l)
          if (( b_hit )) ; then
                SCANFILEADC=$(echo $tocLine | awk '{print $2}')	
		rprint "[$SCANFILEADC-D$dirCount-S$seriesCount]"
		b_ADChit=1
		continue
          fi 
          
          b_hit=$(echo "$SCANDESC" | grep -i "ASLCBF" | wc -l)
          if (( b_hit )) ; then
                SCANFILEASL=$(echo $tocLine | awk '{print $2}')	
		rprint "[$SCANFILEASL-D$dirCount-S$seriesCount]"
		b_ASLhit=1
		continue
          fi          

          b_hit=$(echo "$SCANDESC" | grep -i "ZERO-B" | wc -l)
          if (( b_hit )) ; then
                SCANFILEB0=$(echo $tocLine | awk '{print $2}')	
		rprint "[$SCANFILEB0-D$dirCount-S$seriesCount]"
		b_B0hit=1
		continue
          fi
	  b_hit=$(( b_ADChit && b_ASLhit && b_B0hit ))
	  if (( !b_hit )) ; then rprint "[ Not tagged ]"; fi
	fi
      done
      if (( b_hit == 1 )) ; then
            b_tocHit=1
            ENTRY="$STUDYDIR;$SCANFILEADC;$SCANFILEASL;$SCANFILEB0;-${SCANDATE}_$STUDYAGE-D$dirCount-S$seriesCount$G_DIRSUFFIX"
            echo $ENTRY >> $G_TABLEFILE
            seriesCount=$(expr $seriesCount + 1)
      fi
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

