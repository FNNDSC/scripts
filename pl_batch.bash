#!/bin/bash
#
# pl_batch.bash
#
# Copyright 2008 Rudolph Pienaar
# Massachusetts General Hospital
#
# SPDX-License-Identifier: MIT
#
source common.bash

declare -i Gi_verbose=0
declare -i Gb_forceStage=1
declare -i Gb_loopOverride=0

G_TABLEFILE="-x"
G_PIPELINETYPE="-x"
G_DICOMINPUTDIR="-x"
G_DICOMINPUTFILE="-x"
G_LOOPCOUNT="1"

G_SYNOPSIS="

 NAME

	pl_batch.bash

 SYNOPSIS

	pl_batch.bash           -t <batchTableFile>                   	\\
                                -T <pipelineType>                       \\
				[-l <loopOverride>]			\\
                                [-v <verbosity>]

 DESCRIPTION

	'pl_batch.bash' is a batch controller for a set of '*_meta.bash'
        runs. Given a <batchTableFile> that contains a set of runs to process,
        step through each run in the table, using the pipeline <pipelineType>.

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

              <DICOMDIR>;<dcmSeriesFile>;<outputSuffix>;<DIRsuffix>;<AdditionalArgs>

        where <DICOMDIR> is the directory within DEFAULTDIR to process,
        <dcmSeriesFile> is a file in the series to process, and <outputSuffix>
        a descriptive text for the run (this should NOT contain any spaces).
        The <DIRsuffix> denotes a descriptive suffix for the acutal directory
        housing the final post-processing run, typically <MRID><DIRsuffix>.
        <AdditionalArgs> is an optional way to specify any additional arguments
        to the script.  Note that <AdditionalArgs> need to have the character
        ':' in place of spaces which will get substituted at runtime with
        ' '.

 ARGUMENTS

	-v <level> (Optional)
	Verbosity level. A value of '10' is a good choice here.

	-l <loopOverride> (Optional)
	If specified, only loop over the first <loopOverride> entries
	in the <batchTable>. This is provided so that new entries to
	an already processed <batchTableFile> can be selected, provided
	of course that these new entries appear at the *beginning* of the
	process specification.

        -T <pipelineType>
        The pipeline batch to create. Currently 'FS' (for FreeSurfer),  'Tract'
        (for tractography), 'Fetal' (for Fetal), 'dcmanon' (which anonymizes
        whole directories), 'dcmsend' (which sends directories), and
        'connectome' (for connectivity matrices) are understood.
	
	-t <batchTableFile>
        The table file to process.

 PRECONDITIONS
	
	o A FreeSurfer 'std' or 'dev' environment.

        o 'tract_meta.bash', 'fs_meta.bash' and related.

 POSTCONDITIONS

        o Each line of the batch table is interpreted and passed to a 
          spawned 'tract_meta.bash' process.

 HISTORY

	15 August 2008
	o Initial design and coding.

        28 July 2009
        o Consolidation of separate fs_meta and tract_meta pipelines.

	23 December 2009
	o Added 'dcmanon' as meta pipeline.

"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///


# Actions
A_noTableFileArg="checking on -t <batchTableFile> argument"
A_noTypeFileArg="checking on -T <pipelineType> argument"
A_noTableFile="checking on the table file"
A_noDicomDir="checking on input DICOM directory"
A_noDicomFile="checking on input DICOM directory / file"
A_stageRun="running a stage in the processing pipeline"

# Error messages
EM_noTableFileArg="it seems as though you didn't specify a -t <batchTableFile>."
EM_noTypeFileArg="it seems as though you didn't specify a -T <pipelineType>."
EM_noTableFile="I couldn't access the file. Does it exist? Do you have access rights?"
EM_noDicomDir="I couldn't access the input DICOM dir. Does it exist?"
EM_noDicomFile="I couldn't find any DICOM *dcm files. Do any exist?"
EM_stageRun="I encountered an error processing this stage."

# Error codes

EC_noTableFile=41
EC_noTypeFile=42
EC_noDicomDir=50
EC_noTableFileArg=51
EC_noDicomFile=52
EC_stageRun=30

# Defaults
D_whatever=

###\\\
# Function definitions
###///

###\\\
# Process command options
###///

while getopts v:t:T:l: option ; do
	case "$option"
	in
		v) 	Gi_verbose=$OPTARG		;;
		t)	G_TABLEFILE=$OPTARG		;;
                T)      G_PIPELINETYPE=$OPTARG          ;;
		l)	G_LOOPCOUNT=$OPTARG
			let Gb_loopOverride=1		;;
		\?) synopsis_show
		    exit 0;;
	esac
done

verbosity_check

echo ""
cprint  "hostname"      "[ $(hostname) ]"

## Check on script preconditions
REQUIREDFILES="common.bash tract_meta.bash fs_meta.bash" 

for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file"
        file_checkOnPath $file || fatal fileCheck
done

## Check on input table file 
statusPrint     "Checking -t <batchTableFile>"
if [[ "$G_TABLEFILE" == "-x" ]] ; then fatal noTableFileArg ; fi
ret_check $?
statusPrint     "Checking <batchTableFile>"
fileExist_check $G_TABLEFILE || fatal noTableFile


statusPrint     "Checking -T <pipelineType>"
if [[ "$G_PIPELINETYPE" == "-x" ]] ; then fatal noTypeFileArg ; fi
ret_check $?

case "$(echo $G_PIPELINETYPE | tr '[A-Z]' '[a-z]')" 
    in
        "fs")           PIPELINE="fs"           ;;
        "tract")        PIPELINE="tract"        ;;
        "fetal")        PIPELINE="fetal"        ;;
        "dcmanon")      PIPELINE="dcmanon"      ;;
        "dcmsend")      PIPELINE="dcmsend"      ;;
        "connectome")   PIPELINE="connectome"   ;;
esac

topDir=$(pwd)
G_LOGDIR=$(dirname $G_TABLEFILE)
cd ${topDir}/${G_LOGDIR}
G_LOGDIR=$(pwd)
G_TABLEFILE=${G_LOGDIR}/$G_TABLEFILE
BASETABLE=$(basename $G_TABLEFILE)
cd $LOGDIR

DATE=$(date)

## Main processing start
STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($(pwd); $BASETABLE) $G_SELF $*" $STAMPLOG

G_TABLEFILEPARSED=$(cat $G_TABLEFILE | grep -v \#)

DEFAULTDIR=$(echo "$G_TABLEFILEPARSED"   | grep DEFAULTDIR       | awk -F \= '{print $2}')
DEFAULTCOM=$(echo "$G_TABLEFILEPARSED"   | grep DEFAULTCOM       | awk -F \= '{print $2}')
DEFAULTMAIL=$(echo "$G_TABLEFILEPARSED"  | grep DEFAULTMAIL      | awk -F \= '{print $2}')
TABLE=$(cat $G_TABLEFILE | grep -v \# | grep -v DEFAULT | sed '/^$/d' )

MAILCOM=""
if (( ${#DEFAULTMAIL} )) ; then
  MAILCOM="-M $DEFAULTMAIL"
fi
declare -i lineNum=1
declare -i totalLines=0
declare -i b_OKDIR
declare -i b_OKFILE
totalLines=$(echo "$TABLE" | wc -l)
if (( Gb_loopOverride )) ; then
    let totalLines=$G_LOOPCOUNT
fi
for LINE in $TABLE ; do
  b_OKDIR=1
  b_OKFILE=1
  cprint        "Preparing run"         "[ $lineNum / $totalLines ]"
  STAGE="batchRun_$lineNum/$totalLines"
  RUNDIR=$(echo $LINE | awk -F \; '{print $1}')
  G_DICOMINPUTDIR=${DEFAULTDIR}/$RUNDIR
  G_DICOMINPUTFILE=$(echo $LINE | awk -F \; '{print $2}')
  SUFFIX=$(echo $LINE | awk -F \; '{print $3}')
  DIRSUFFIX=$(echo $LINE | awk -F \; '{print $4}')
  ADDITIONALARGS=$(echo $LINE | awk -F \; '{print $5}' | sed 's/:/ /g')
  statusPrint     "Checking on <dicomInputDir>"
  dirExist_check $G_DICOMINPUTDIR || b_OKDIR=0
  statusPrint     "Checking on <dicomFile>"
  fileExist_check ${G_DICOMINPUTDIR}/${G_DICOMINPUTFILE} || b_OKFILE=0
  if (( b_OKDIR && b_OKFILE )) ; then
    STAGECMD="${PIPELINE}_meta.bash                     \
              $DEFAULTCOM                               \
              $MAILCOM                                  \
              -o $SUFFIX                                \
              -R $DIRSUFFIX                             \
              -D $G_DICOMINPUTDIR                       \
              -d $G_DICOMINPUTFILE                      \
              $ADDITIONALARGS"
#     echo $STAGECMD
    echo ""
    stage_run "$STAGE" "$STAGECMD"                      \
        "${G_LOGDIR}/${G_SELF}.std"                     \
        "${G_LOGDIR}/${G_SELF}.err"			\
#       || fatal stageRun
  else
    statusPrint "Invalid run spec"
  fi
  lineNum=$(expr $lineNum + 1)
  if (( Gb_loopOverride && lineNum > G_LOOPCOUNT )) ; then break; fi
done

lineNum=$(expr $lineNum - 1)
STAGE="($BASETABLE) Normal termination -- processed $lineNum / $totalLines"
stage_stamp "$STAGE" $STAMPLOG

printf "%40s" "Cleaning up"
shut_down 0

