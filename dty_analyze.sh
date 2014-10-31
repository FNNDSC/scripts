#!/bin/bash


# "include" the set of common script functions
source common.bash

G_LC=60
G_RC=20

G_STAGES="123"
G_DENSITYLIST="AreaDensity ParticleDensity"
G_TOKEN="cloudCoreOverlap"
G_OUTDIR="./"
G_FILTER="le5"
G_HEMI=lh
G_SURFACE=smoothwm


PREFIXLIST=""
let b_prefixList=0


G_SYNPOSIS="

  NAME

        dty_analyze.sh

  SYNOPSIS

        dty_analyze.sh          -S <substringFilter>                    \
                                -p <substringPrefixList>                \
                                -t <splitToken>                         \
                                -o <outputDir>                          \
                                -s <surface>                            \
                                -h <hemi>                               \
                                -t <STAGES>


  DESC

        'dty_analyze.sh' creates grouped summaries of a set of density
        files that have been tagged by the p-test <subscringFilter>.

        It relies on the outputs of a standard curvature analysis
        pipeline.

  ARGS

        -S <substringFilter>
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


        -T <splitToken>
        The string token to split output filenames on. Probably this
        shouldn't be changed from the default.

        Defaults to 'cloudCoreOverlap'.

        -o <outputDir>
        The directory to contain output text files.

        Defaults to './'

        -s <surface>
        The surface to filter on.

        -h <hemi>
        The hemisphere to filter on.

        -t <STAGES>
        The stages to run.

  STAGES

        1 - summarize
                Build the density table files by filtering the space
                of outputs conforming to a filter.
        2 - threshold
                Parse the density table files and determine a new
                threshold cut off to parse all density files.
        3 - final cutoffs
                Based on the threshold cutoff, analyze all statistical
                geometries for cutoffs.


  HISTORY

        10-Jan-2014
        o Initial design and coding.
"

G_SELF=`basename $0`
G_PID=$$

A_noOutRunDir="checking on output run directory"
A_preconditionFail="checking on stage preconditions"

EM_noOutRunDir="I couldn't access the output run dir. Does it exist?"
EM_preconditionFail="I couldn't find a necessary precondition."

EC_noOutRootDir=54
EC_preconditionFail=60

while getopts v:s:h:S:p:o:t: option ; do
        case "$option"
        in
                o) G_OUTDIR=$OPTARG             ;;
                p) PREFIXLIST=$OPTARG
                   b_prefixList=${#PREFIXLIST}  ;;
                S) G_FILTER=$OPTARG             ;;
                s) G_SURFACE=$OPTARG            ;;
                h) G_HEMI=$OPTARG               ;;
                t) G_STAGES="$OPTARG"           ;;
                v) let Gi_verbose=$OPTARG       ;;
                \?) synopsis_show
                    exit 0;;
        esac
done

verbosity_check
topDir=$(pwd)

# Are we on a Mac with installed MacPorts?
XARGS=xargs
lprint "Checking on xargs style"
fileExist_check /opt/local/bin/gxargs Linux MacOS && XARGS=/opt/local/bin/gxargs

printf "\n"
cprint  "hostname"      "[ $(hostname) ]"

G_LOGDIR=$G_OUTDIR
lprint          "Checking on output root dir"
dirExist_check ${G_LOGDIR} "not found - creating"  \
              || mkdir -p ${G_LOGDIR}              \
              || fatal noOutRootDir
cd $G_OUTDIR >/dev/null
G_LOGDIR=$(pwd)
cd $topDir >/dev/null

if (( b_prefixList )) ; then
        PREFIXLIST=$(echo "$PREFIXLIST" | tr "," " ")
else
        PREFIXLIST="*"
fi

## Check which stages to process
statusPrint     "Checking which stages to process"
barr_stage=([1]=0 [2]=0 [3]=0)
for i in $(seq 1 3) ; do
        b_test=$(expr index $G_STAGES "$i")
        if (( b_test )) ; then b_flag="1" ; else b_flag="0" ; fi
        barr_stage[$i]=$b_flag
done
ret_check $?

STAMPLOG=${G_LOGDIR}/${G_SELF}.log
stage_stamp "Init | ($(pwd)) $G_SELF $*" $STAMPLOG

STAGENUM="dty_analyze-1"
STAGEPROC="summaryTables-$G_FILTER"
STAGE=${STAGENUM}-${STAGEPROC}
STAGE1RELDIR=${G_OUTRUNDIR}/${STAGE}
STAGE1FULLDIR=${G_OUTDIR}/${STAGE}
statusPrint     "Checking stage 1 output dir"
dirExist_check ${G_OUTDIR}/${STAGE} "not found - creating"        \
            || mkdir -p ${G_OUTDIR}/${STAGE}                      \
            || fatal noOutRunDir
if (( ${barr_stage[1]} )) ; then
        statusPrint "$(date) | Processing Stage $STAGENUM - START" "\n"
        ALLHITS=""
        b_removeResultFiles=0
        for PREFIX in $PREFIXLIST; do
                if (( b_prefixList )) ; then
                        PREFIXHITS=$(find . -iname "*$PREFIX*$G_FILTER*"    |\
                                    grep -v dty_analyze                     |\
                                    grep $G_SURFACE                         |\
                                    grep $G_HEMI)
                else
                        PREFIXHITS=$(find . -iname "*$G_FILTER*"            |\
                                    grep -v dty_analyze                     |\
                                    grep $G_SURFACE                         |\
                                    grep $G_HEMI)
                fi
                b_HITS=$(echo "$PREFIXHITS" | wc -l)
                if (( ! ${#PREFIXHITS} )) ; then b_HITS=0; fi
                lprint "Saving p-test lists for $PREFIX-$G_FILTER-$G_HEMI-$G_SURFACE"
                if (( b_HITS )) ; then
                        echo "$PREFIXHITS" > ${G_OUTDIR}/${STAGE}/p-$PREFIX-$G_FILTER-$G_HEMI-$G_SURFACE
                else
                        touch ${G_OUTDIR}/${STAGE}/p-$PREFIX-$G_FILTER-$G_HEMI-$G_SURFACE
                fi
                rprint "[ $b_HITS ]"
                b_removeResultFiles=$(( b_HITS || b_removeResultFiles))
                ALLHITS=$(printf "%s\n%s" "$ALLHITS" "$PREFIXHITS")
                if (( !b_prefixList )) ; then
                        break
                fi
        done

        if [[ b_removeResultFiles ]] ; then
            for DTY in $G_DENSITYLIST ; do
                rm -f ${G_OUTDIR}/${STAGE}/$G_DTY-$G_HEMI-$G_SURFACE.txt
            done
        fi

        for DTY in $G_DENSITYLIST ; do
            touch ${G_OUTDIR}/${STAGE}/$DTY-$G_HEMI-$G_SURFACE.txt;
        done
        for HIT in $ALLHITS ; do
                DIR=$(echo $HIT   | $XARGS -i% echo "dirname %"   | sh)
                FILE=$(echo $HIT  | $XARGS -i% echo "basename %"  | sh)
                #echo $FILE
                for DTY in $G_DENSITYLIST ; do
                        STEM=$(echo $FILE | sed 's/\(.*\)'${G_TOKEN}'\(.*\)/\1'${G_TOKEN}${DTY}'/').txt
                        #printf "%s    %s  %s \n" $DIR $FILE $STEM
                        CONTENTS=$(cat $DIR/$STEM)
                        echo -e "$CONTENTS\t$DIR/$STEM" >> ${G_OUTDIR}/${STAGE}/$DTY-$G_HEMI-$G_SURFACE.txt
                done
        done
        statusPrint "$(date) | Processing Stage $STAGENUM - END" "\n"
fi


if (( b_prefixList )) ; then
        PREFIXLIST=". $PREFIXLIST"
else
        PREFIXLIST="."
fi

STAGENUM="dty_analyze-2"
STAGEPROC="statTables-$G_FILTER"
STAGE=${STAGENUM}-${STAGEPROC}
STAGE2RELDIR=${G_OUTRUNDIR}/${STAGE}
STAGE2FULLDIR=${G_OUTDIR}/${STAGE}
statusPrint     "Checking on stage 2 preconditions" "\n"
for FILE in $G_DENSITYLIST ; do
        lprint $FILE
        fileExist_check ${STAGE1FULLDIR}/$FILE-$G_HEMI-$G_SURFACE.txt || fatal preconditionFail
done
statusPrint     "Checking stage 2 output dir"
dirExist_check ${G_OUTDIR}/${STAGE} "not found - creating"        \
            || mkdir -p ${G_OUTDIR}/${STAGE}                      \
            || fatal noOutRunDir
if (( ${barr_stage[2]} )) ; then
        statusPrint "$(date) | Processing Stage $STAGENUM - START" "\n"

        AREATABLE=$(cat ${STAGE1FULLDIR}/AreaDensity-$G_HEMI-$G_SURFACE.txt)
        PARTICLETABLE=$(cat ${STAGE1FULLDIR}/ParticleDensity-$G_HEMI-$G_SURFACE.txt)

        for FILE in $G_DENSITYLIST ; do
            lprintn "$FILE"
            for PREFIX in $PREFIXLIST ; do
                cprint "Filtering results for prefix" "[ $PREFIX ]"
                if [[ $PREFIX == "." ]] ; then
                        FILTER="$PREFIX"
                        SCOPE="-all-"
                else
                        FILTER="/$PREFIX/"
                        SCOPE="-$PREFIX-"
                fi
                base=$(basename $FILE)
                meanFileName="mean${SCOPE}$FILE-$G_HEMI-$G_SURFACE.txt"
                stdFileName="std${SCOPE}$FILE-$G_HEMI-$G_SURFACE.txt"
                # The control || after the grep is necessary to handle cases
                # where the filter didn't return any hits.
                meanLine=$(cat ${STAGE1FULLDIR}/$FILE-$G_HEMI-$G_SURFACE.txt |\
                         (grep "$FILTER" || echo -e "0 0 0 0")          |\
                          stats_print.awk | grep Mean)
                stdLine=$(cat  ${STAGE1FULLDIR}/$FILE-$G_HEMI-$G_SURFACE.txt |\
                        (grep "$FILTER"  || echo -e "0 0 0 0")          |\
                         stats_print.awk | grep Std)
                echo "$meanLine"        > ${STAGE2FULLDIR}/$meanFileName
                echo "$stdLine"         > ${STAGE2FULLDIR}/$stdFileName
                mean=$(echo $meanLine   | awk '{print $4}')
                std=$(echo $stdLine     | awk '{print $4}')
                sum=$(echo "scale = 2; $mean + $std" | bc)
                echo "$sum"             > ${STAGE2FULLDIR}/cutoff${SCOPE}$FILE-$G_HEMI-$G_SURFACE.txt
            done
        done

        AREAMEAN=$(echo "$AREATABLE" | stats_print.awk | grep Mean)
        statusPrint "$(date) | Processing Stage $STAGENUM - END" "\n"

fi

STAGENUM="dty_analyze-3"
STAGEPROC="cutoffs-$G_FILTER"
STAGE=${STAGENUM}-${STAGEPROC}
STAGE3RELDIR=${G_OUTRUNDIR}/${STAGE}
STAGE3FULLDIR=${G_OUTDIR}/${STAGE}

statusPrint     "Checking on stage 3 preconditions" "\n"
for FILE in $G_DENSITYLIST ; do
    for PREFIX in $PREFIXLIST ; do
        if [[ $PREFIX == "." ]] ; then
                FILTER="$PREFIX"
                SCOPE="-all-"
        else
                FILTER="/$PREFIX/"
                SCOPE="-$PREFIX-"
        fi
        PRE="cutoff${SCOPE}$FILE-$G_HEMI-$G_SURFACE.txt"
        lprint $PRE
        fileExist_check ${STAGE2FULLDIR}/$PRE || fatal preconditionFail
    done
done

statusPrint     "Checking stage 3 output dir"
dirExist_check ${G_OUTDIR}/${STAGE} "not found - creating"        \
            || mkdir -p ${G_OUTDIR}/${STAGE}                      \
            || fatal noOutRunDir
if (( ${barr_stage[3]} )) ; then
        statusPrint "$(date) | Processing Stage $STAGENUM - START" "\n"

        # Running the analysis over previous results will APPEND!!
        #rm ${STAGE3FULLDIR}/* 2>/dev/null
        for FILE in $G_DENSITYLIST ; do
            # echo "PREFIXLIST = $PREFIXLIST"
            lprintn "$FILE-$G_HEMI-$G_SURFACE.txt"
            for PREFIX in $PREFIXLIST ; do
                if [[ $PREFIXLIST == "." ]] ; then
                        FILTER=""
                        SCOPE="-all-"
                fi
                if [[ $PREFIX != "." ]] ; then
                        FILTER="/$PREFIX/"
                        SCOPE="-$PREFIX-"
                fi
                if [[ $PREFIX == "." && $PREFIXLIST != "." ]] ; then
                        continue
                fi
                lprint "processing separation for groups $SCOPE"
                SEPARATIONFILE="separate${SCOPE}$FILE-$G_HEMI-$G_SURFACE.txt"
                # echo "PREFIX = $PREFIX"
                TARGET="${STAGE2FULLDIR}/cutoff${SCOPE}$FILE-$G_HEMI-$G_SURFACE.txt"
                # echo "TARGET = $TARGET"
                f_cutoff=$(cat $TARGET)
                CMD="find . -wholename \"*$FILTER*$FILE.txt\"       |\
                            grep -v dty_analyze                     |\
                            grep $G_SURFACE                         |\
                            grep $G_HEMI"
                TARGETLIST=$(eval $CMD)
                overlapCount=0
                for OVERLAP in $TARGETLIST ; do
                        f_overlap=$(cat $OVERLAP | awk '{print $3}')
                        # printf "%s\t%s\n" $f_overlap $f_cutoff
                        b_overlap=$(echo "$f_overlap <= $f_cutoff" | bc)
                        if (( b_overlap )) ; then
                                overlapCount=$(expr $overlapCount + 1)
                                OUTTXT=$(printf "%7.3f\t%7.3f\t\t%s\n" $f_cutoff $f_overlap $OVERLAP)
                                echo "$OUTTXT" >> ${STAGE3FULLDIR}/$SEPARATIONFILE
                        fi
                done
                rprint "[ ok ]"
                cprint "Separation count" "[ $overlapCount ]"
            done
        done

        statusPrint "$(date) | Processing Stage $STAGENUM - END" "\n"

fi
