#!/bin/bash

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

  HISTORY
  
  	10-Jan-2014
	o Initial design and coding.
"

DENSITYLIST="AreaDensity.txt ParticleDensity.txt"
TOKEN="cloudCoreOverlap"
OUTDIR="./"

FILTER="le5"
PREFIXLIST=""
let b_prefixList=0

while getopts v:s:p:o: option ; do
        case "$option"
        in
		o) OUTDIR=$OPTARG		;;
		p) PREFIXLIST=$OPTARG			
		   b_prefixList=${#PREFIXLIST}	;;
                s) FILTER=$OPTARG		;;
                v) let Gi_verbose=$OPTARG       ;;
                \?) synopsis_show
                    exit 0;;
        esac
done

if (( b_prefixList )) ; then
	PREFIXLIST=$(echo "$PREFIXLIST" | tr "," " ")
else
	PREFIXLIST="*"
fi
	
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
