#!/bin/bash

# User spec'd
G_HEMI="lh rh"
G_SIGN="neg pos"
G_REGION="frontal temporal parietal occipital"
G_SURFACE="smoothwm pial"
G_REPORTDIR="reports"

let Gb_groupOverride=0
let Gb_annotationSpec=0
let Gb_surfaceSpec=0
let Gb_regionSpec=0

G_GROUPNUM=3
G_GROUPNUMOVERRIDE=3
G_TYPE="-x"
G_EXPDIR=$(pwd)

ANNOTATIONSTEM="lobesStrict"

let Gb_expDirSpecified=0

declare -i Gb_reportSave=0

G_SYNPOSIS="

  NAME

        data_summarize.sh -t <dataType> [-s] [-E <expDir>] [-G <groups>]\\
                          [-n <sign>]                                   \\
			  [-a <annotationStem]				\\
			  [-R <regionSpec>]				\\
			  [-S <surfaceSpec>]

  SYNOPSIS
  
        data_summarize.sh
        
  DESC

        Walk down an experiment tree and summarize a specific data measure.

  ARGS

        -n <sign>
        The curvature sign to process ('neg', 'pos', 'sk', or combinations like
        'neg pos').

        -t <dataType>
        One of 'pval1', 'pval5', 'overlap', 'overlapL', 'overlapR', 
        'ordering', 'ordering2', 'areas', 'areasP', 'grid', or 'ggrid'.

        -s 
        If specified, save summary reports (one per region/hemi/surface)
        to a report directory. The report dir is <root>/reports/<dataType>.
        
        -E <expDir>
        If passed, specifies the top level experiment directory. Also
        turns off the toplevel <hemi>-<region> processing.
        
        -G <groups>
        If specified, the number of a priori groups to analyze.

	-a <annotationStem>
	If specified, the annotation sub-directory off the groupAnalysis
	directory. Defaults to $ANNOTATIONSTEM.
	
	-R <regionSpec>
	If specified, the regions to process, i.e. subdirectories
	off the <annotationStem>. This should be a comma-delimited list.
	
	-S <surfaceSpec>
	If specified, the surface to process. 
	
  EXAMPLE

    data_summarize.sh -t overlap -E PMGvNormal_autodijk -G 2 		  \\
	-a regions-native 						  \\
	-R \"entire,region-1,region-2,region-3,region-4,region-5,region-6\" \\
	-S autodijk

    data_summarize.sh -G 3 -E lh-frontal -S smoothwm -t grid
        
  HISTORY
  
  02 December 2010
  o Initial design and coding.
  
  10 March 2011
  o More flexible dir layout handling.

  14 April 2011
  o Added 'ggrid'.
  
  15 June 2011
  o Added -a, -R, and -S options.

  17 April 2013
  o Sign spec.
"

while getopts sE:t:G:a:n:S:R: option ; do
    case "$option" 
    in
        n)      G_SIGN="$OPTARG"                                ;;
	a)	Gb_annotationSpec=1
                ANNOTATIONSTEM=$OPTARG				;;
	S)	Gb_surfaceSpec=1
		G_SURFACE=$OPTARG	
		G_SURFACE=$(echo "$G_SURFACE" | tr ',' ' ')	;;
	R)	Gb_regionSpec=1
		G_REGION=$OPTARG	
		G_REGION=$(echo "$G_REGION" | tr ',' ' ')	;;
        t)      G_TYPE=$OPTARG          			;;
        s)      let Gb_reportSave=1     			;;
        E)      G_EXPDIR=$OPTARG        
                Gb_expDirSpecified=1    			;;
        G)      G_GROUPNUMOVERRIDE=$OPTARG      
                Gb_groupOverride=1      			;;
        ?)      echo "$G_SYNPOSIS"
                exit 1
    esac
done

startDir=$(pwd)
cd $G_EXPDIR >/dev/null
G_EXPDIR=$(pwd)

if [[ $G_TYPE == "-x" ]] ; then
    printf "No <dataType> specified! Exiting with code '1'.\n\n"
    exit 1
fi

cd $startDir

if (( Gb_annotationSpec && Gb_expDirSpecified && !Gb_regionSpec )) ; then
    cd $G_EXPDIR/groupCurvAnalysis/${ANNOTATIONSTEM}.annot
    G_REGION=$(find . -maxdepth 1 -mindepth 1 -type d | awk -F\/ '{print $2}')
    cd $startDir
fi

case "$G_TYPE"
in
        pval5)          TABULATE="pval_tabulate.sh -T le5"      ;;
        pval1)          TABULATE="pval_tabulate.sh -T le1"      ;;
        overlap)        TABULATE="overlap_tabulate.sh"          ;;
        overlapLSym)    TABULATE="overlap_tabulate.sh -T LSym"  ;;
        overlapRSym)    TABULATE="overlap_tabulate.sh -T RSym"  ;;
        overlapLAsym)   TABULATE="overlap_tabulate.sh -T LAsym" ;;
        overlapRAsym)   TABULATE="overlap_tabulate.sh -T RAsym" ;;
        areas)          TABULATE="areas_tabulate.sh"            ;;
        areasSym)       TABULATE="areas_tabulate.sh -T Sym"     ;;
        areasAsym)      TABULATE="areas_tabulate.sh -T Asym"    ;;
        ordering)       TABULATE="ordering_tabulate.sh"         ;;
        ordering2)      TABULATE="ordering_tabulate.sh -T "     ;;
        grid)           TABULATE="grid_tabulate.sh"             ;;
        ggrid)          TABULATE="ggrid_tabulate.sh"            ;;
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
            cd $G_EXPDIR/$HEMIREGION/groupCurvAnalysis/${ANNOTATIONSTEM}.annot/$REGION >/dev/null
        else
            G_GROUPNUM=$(cd $G_EXPDIR; ls -1 groupID* | wc -l)
            cd ${G_EXPDIR}/groupCurvAnalysis/${ANNOTATIONSTEM}.annot/$REGION
        fi
        if (( Gb_groupOverride )) ; then
            G_GROUPNUM=$G_GROUPNUMOVERRIDE
        fi
        for SURFACE in $G_SURFACE ; do
            printf "\n\n$HEMIREGION-$SURFACE\n"
            REPORT=$(~/src/scripts/$TABULATE -n "$G_SIGN" -G $G_GROUPNUM -h $HEMI -r $REGION -s $SURFACE -S "|")
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


