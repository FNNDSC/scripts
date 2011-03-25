#!/bin/bash

# User spec'd
G_HEMI="lh rh"
G_REGION="frontal temporal parietal occipital"
G_SURFACE="smoothwm pial"
G_REPORTDIR="reports"
let Gb_groupOverride=0
G_GROUPNUM=3
G_GROUPNUMOVERRIDE=3
G_TYPE="-x"

let Gb_expDirSpecified=0

declare -i Gb_reportSave=0

G_SYNPOSIS="

  NAME

        data_summarize.sh -t <dataType> [-s] [-E <expDir>] [-G <groups>]

  SYNOPSIS
  
        data_summarize.sh
        
  DESC

        Walk down an experiment tree and summarize a specific data measure.

  ARGS
  
        -t <dataType>
        One of 'overlap', 'ordering', 'ordering2', or 'areas'.

        -s 
        If specified, save summary reports (one per region/hemi/surface)
        to a report directory. The report dir is <root>/reports/<dataType>.
        
        -E <expDir>
        If passed, specifies the top level experiment directory. Also
        turns off the toplevel <hemi>-<region> processing.
        
        -G <groups>
        If specified, the number of a priori groups to analyze.
        
  HISTORY
  
  02 December 2010
  o Initial design and coding.
  
  10 March 2011
  o More flexible dir layout handling.

"

while getopts sE:t:G: option ; do
    case "$option" 
    in
        t)      G_TYPE=$OPTARG          ;;
        s)      let Gb_reportSave=1     ;;
        E)      G_EXPDIR=$OPTARG        
                Gb_expDirSpecified=1    ;;
        G)      G_GROUPNUMOVERRIDE=$OPTARG      
                Gb_groupOverride=1      ;;
        ?)      echo "$G_SYNPOSIS"
                exit 1
    esac
done

starDir=$(pwd)
cd $G_EXPDIR >/dev/null
G_EXPDIR=$(pwd)

if [[ $G_TYPE == "-x" ]] ; then
    printf "No <dataType> specified! Exiting with code '1'.\n\n"
    exit 1
fi

cd $starDir

case "$G_TYPE"
in
        overlap)        TABULATE="overlap_tabulate.sh"          ;;
        areas)          TABULATE="areas_tabulate.sh"            ;;
        ordering)       TABULATE="ordering_tabulate.sh"         ;;
        ordering2)      TABULATE="ordering_tabulate.sh -T "     ;;
        grid)           TABULATE="grid_tabulate.sh"             ;;
        *)              printf "Invalid <dataType>! Exiting with code '2'.\n\n"
                        exit 2                                          ;;
esac

G_REPORTDIR=${G_REPORTDIR}/$G_TYPE

if [[ ! -d ${G_EXPDIR}/${G_REPORTDIR} ]] ; then 
    mkdir -p ${G_EXPDIR}/${G_REPORTDIR} ; 
fi
cd ${G_EXPDIR}/$G_REPORTDIR >/dev/null
G_REPORTDIR=$(pwd)

for HEMI in $G_HEMI ; do
    for REGION in $G_REGION ; do
        HEMIREGION="$HEMI-$REGION"
        if (( !Gb_expDirSpecified )) ; then
            G_GROUPNUM=$(cd $G_EXPDIR/$HEMIREGION; ls -1 groupID* | wc -l)
            cd $G_EXPDIR/$HEMIREGION/groupCurvAnalysis/lobesStrict.annot/$REGION >/dev/null
        else
            G_GROUPNUM=$(cd $G_EXPDIR; ls -1 groupID* | wc -l)
            cd ${G_EXPDIR}/groupCurvAnalysis/lobesStrict.annot/$REGION
        fi
        if (( Gb_groupOverride )) ; then
            G_GROUPNUM=$G_GROUPNUMOVERRIDE
        fi
        for SURFACE in $G_SURFACE ; do
            printf "\n\n$HEMIREGION-$SURFACE\n"
            REPORT=$($TABULATE -G $G_GROUPNUM -h $HEMI -r $REGION -s $SURFACE -S "|")
            echo "$REPORT"
            if (( Gb_reportSave )) ; then
                echo "$REPORT" > $G_REPORTDIR/$G_TYPE-$HEMIREGION-$SURFACE.txt
            fi
        done
    done
done

ALLREPORTS=${G_TYPE}-reports.all
if (( Gb_reportSave )) ; then
    cd $G_REPORTDIR >/dev/null
    rm $ALLREPORTS* 2>/dev/null
    for SURFACE in smoothwm pial ; do
        for HEMI in $G_HEMI ; do
            for REGION in $G_REGION ; do
                for FILE in *$HEMI*$REGION*$SURFACE*txt ; do
                    REPORT=$(cat $FILE)
                    echo $FILE      >> $ALLREPORTS-$SURFACE
                    echo "$REPORT"  >> $ALLREPORTS-$SURFACE
                    echo ""         >> $ALLREPORTS-$SURFACE
                done
            done
        done
    done
fi

cd $G_EXPDIR


