#!/bin/bash


# "include" the set of common script functions
source common.bash

G_STAGES="12"
DENSITYLIST="AreaDensity.txt ParticleDensity.txt"
TOKEN="cloudCoreOverlap"
OUTDIR="./"

FILTER="le5"
PREFIXLIST=""
let b_prefixList=0


G_SYNPOSIS="

  NAME

        dty_analyze.sh

  SYNOPSIS
  
        dty_analyze.sh		-s <substringFilter>			\
				-p <substringPrefixList>		\
				-t <splitToken>				\
				-o <outputDir>


  DESC

        'dty_analyze.sh' creates grouped summaries of a set of density
	files that have been tagged by the p-test <subscringFilter>.

  ARGS

        -s <substringFilter>
	The p-test substring filter to process. This is usually one of
	'le5' or 'le1', corresponding to 'less-than-equal to 5%' or 
	'less-than-equal-to 1%' confidence threshold.
	
	Defaults to 'le5'.
	
	-p <substringPrefixList>
	A prefix string to be added to the main search pattern. Each 
	item in this comma separated list is used to prefix a find search, 
	i.e. for an argument \"-p prefix1,prefix2,prefix3,...,prefixN\"
 	
		find . -iname \"*prefix1*<substringFilter>*\"
		find . -iname \"*prefix2*<substringFilter>*\"
					...
		find . -iname \"*prefixN*<substringFilter>*\"
		
	
	-t <splitToken>
	The string token to split output filenames on. Probably this
	shouldn't be changed from the default.
	
	Defaults to 'cloudCoreOverlap'.
	
	-o <outputDir>
	The directory to contain output text files.
	
	Defaults to './'

  STAGES

	1 - summarize
		Build the density table files by filtering the space
		of outputs conforming to a filter.
        2 - threshold
		Parse the density table files and determine a new
		threshold cut off to parse all density files.


  HISTORY
  
  	10-Jan-2014
	o Initial design and coding.
"

G_SELF=`basename $0`
G_PID=$$

A_noOutRunDir="checking on output run directory"
EM_noOutRunDir="I couldn't access the output run dir. Does it exist?"
EC_noOutRootDir=54

while getopts v:s:p:o: option ; do
        case "$option"
        in
		o) OUTDIR=$OPTARG		;;
		p) PREFIXLIST=$OPTARG			
		   b_prefixList=${#PREFIXLIST}	;;
                s) FILTER=$OPTARG		;;
                t) G_STAGES="$OPTARG"		b;;
                v) let Gi_verbose=$OPTARG       ;;
                \?) synopsis_show
                    exit 0;;
        esac
done

verbosity_check
topDir=$(pwd)

# Are we on a Mac with installed MacPorts?
EXPR=expr
fileExist_check /opt/local/bin/gexpr && EXPR=/opt/local/bin/gexpr

echo "expr = $EXPR"
exit 0

printf "\n"
cprint  "hostname"      "[ $(hostname) ]"

G_LOGDIR=$OUTDIR
lprint          "Checking on output root dir"
dirExist_check ${G_LOGDIR} "not found - creating"  \
              || mkdir -p ${G_LOGDIR}              \
              || fatal noOutRootDir
cd $OUTDIR >/dev/null
G_LOGDIR=$(pwd)
cd $topDir >/dev/null

if (( b_prefixList )) ; then
	PREFIXLIST=$(echo "$PREFIXLIST" | tr "," " ")
else
	PREFIXLIST="*"
fi

## Check which stages to process
statusPrint     "Checking which stages to process"
barr_stage=([0]=0 [1]=0)
for i in $(seq 1 2) ; do
        b_test=$(expr index $G_STAGES "$i")
        if (( b_test )) ; then b_flag="1" ; else b_flag="0" ; fi
        barr_stage[$i]=$b_flag
done
ret_check $?

STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($(pwd)) $G_SELF $*" $STAMPLOG

STAGENUM="1-dty_analyze"
STAGEPROC="summaryTables"
STAGE=${STAGENUM}-${STAGEPROC}
STAGE1RELDIR=${G_OUTRUNDIR}/${STAGE}
STAGE1FULLDIR=${OUTDIR}/${STAGE}
statusPrint     "Checking stage 1 output dir"
dirExist_check ${OUTDIR}/${STAGE} "not found - creating"        \
            || mkdir -p ${OUTDIR}/${STAGE}                      \
            || fatal noOutRunDir
if (( ${barr_stage[1]} )) ; then
	statusPrint "$(date) | Processing Stage $STAGENUM" "\n"
	ALLHITS=""
	b_removeResultFiles=0
	for PREFIX in $PREFIXLIST; do 
		if (( b_prefixList )) ; then
			PREFIXHITS=$(find . -iname "*$PREFIX*$FILTER*")
		else
			PREFIXHITS=$(find . -iname "*$FILTER*")
		fi
		b_HITS=$(echo "$HITS" | wc -l)
		b_removeResultFiles=$(( b_HITS || b_removeResultFiles))
		ALLHITS=$(printf "%s\n%s" "$ALLHITS" "$PREFIXHITS")
		if (( !b_prefixList )) ; then 
			break
		fi
	done
	if [[ b_removeResultFiles ]] ; then
		rm -f $DENSITYLIST
	fi

	for HIT in $ALLHITS ; do
		DIR=$(echo $HIT   | gxargs -i% echo "dirname %"   | sh)
		FILE=$(echo $HIT  | gxargs -i% echo "basename %"  | sh)
		for DTY in $DENSITYLIST ; do
			STEM=$(echo $FILE | sed 's/\(.*\)'${TOKEN}'\(.*\)/\1'${TOKEN}${DTY}'/')
			if (( Gi_verbose )); then
				printf "%s    %s  %s \n" $DIR $FILE $STEM
			fi
			CONTENTS=$(cat $DIR/$STEM)
			echo -e "$CONTENTS\t$DIR/$STEM" >> $DTY
		done
	done

fi

