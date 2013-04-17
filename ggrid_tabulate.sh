#!/bin/bash

G_SIGN="neg pos"
G_GROUPS="X Y"
G_CURVpos="K K1 K2 H S C BE thickness"
G_CURVneg="K K1 K2 H"
G_TABLE="K,S K1,C K2,BE H,thickness"
G_GROUPNUM="3"
G_SEPSTRING=""

G_LEFTLABEL=/tmp/leftlabel.txt
G_RIGHTLABEL=/tmp/rightlabel.txt
G_RIGHTBORDER=/tmp/rightBorder.txt

let Gb_extraLines=0
G_EXTRALINES=""

# User spec'd
HEMI=lh
SURFACE=smoothwm
REGION=frontal

G_SYNPOSIS="

  NAME

        ggrid_tabulate.sh

  SYNOPSIS
  
        ggrid_tabulate.sh -h <hemi> -r <region> -s <surface>            \
                                [-n <sign>]                             \
                                [-S <sepString>] [-G <groupNum>]        \
                                [-T]


  DESC

        'ggrid_tabulate.sh' is rather simple script that \"plots\"
        grid groupings of the curvature functions in a manner suitable
        for post processing for publication.
        
        This provides a quick summary of the spatial ordering of the groups.

  ARGS

        -n <sign>
        The curvature sign to process ('neg', 'pos', or 'neg pos').

        -h <hemi>
        The hemisphere to process ('lh' or 'rh').
        
        -r <region>
        The region to process ('frontal', 'temporal', 'parietal', 'occipital)'

        -s <surface>
        The surface to process ('smoothwm', 'pial')
        
        -S <sepString>
        Print <sepString> between field columns.
        
        -G <groupNum>
        If specified, indicates the number of groups in sample.

        -T
        If specified, generate extra col separation characters -- useful for
        importing into OpenOffice and LaTeX.

  PRECONDITIONS
  o A grid_tabulate.sh run that has created *.grid files.
  o 'vcat' app.

  POSTCONDITIONS
  o For each pos,neg for each curv, for each region, for each surface, create:

  HISTORY
    
  14 April 2011
  o Grid additions.

  17 April 2013
  o Sign spec.
"

function boxBorder_draw
{
    printf "%10s" " "
    printf "+"
    for cols in $(seq 2 $(expr $G_GROUPNUM \* 3)) ; do
        printf "-"
    done
    printf "+"
    for cols in $(seq 2 $(expr $G_GROUPNUM \* 3)) ; do
        printf "-"
    done
    printf "+"
    printf "%10s" " "
    printf "+"
    for cols in $(seq 2 $(expr $G_GROUPNUM \* 3)) ; do
        printf "-"
    done
    printf "+"
    printf "\n"
}

while getopts h:r:s:n:S:G:T option ; do
    case "$option" 
    in
        n) G_SIGN="$OPTARG"     ;;
        h) HEMI=$OPTARG         ;;
        r) REGION=$OPTARG       ;;
        s) SURFACE=$OPTARG      ;;
        S) G_SEPSTRING=$OPTARG  ;;
        G) G_GROUPNUM=$OPTARG   ;;
    esac
done


if (( Gb_extraLines )) ; then G_EXTRALINES="|" ; fi

for group in $G_TABLE ; do
    rm -f $G_LEFTLABEL
    rm -f $G_RIGHTLABEL
    rm -f $G_RIGHTBORDER
    LEFT=$(echo $group  | awk -F \, '{print $1}')
    RIGHT=$(echo $group | awk -F \, '{print $2}')
    
    for rows in $(seq 1 $G_GROUPNUM) ; do
      printf "%10s\n"   $LEFT           >> $G_LEFTLABEL
      printf "%10s\n"   $RIGHT          >> $G_RIGHTLABEL
      printf "%s\n"     " "             >> $G_RIGHTBORDER
    done

    boxBorder_draw
    vcat -d "$G_SEPSTRING" $G_LEFTLABEL     \
      neg-centroids-analyze-${HEMI}.${LEFT}.${REGION}.${SURFACE}.txt.grid       \
      pos-centroids-analyze-${HEMI}.${LEFT}.${REGION}.${SURFACE}.txt.grid       \
      $G_RIGHTLABEL                                                             \
      pos-centroids-analyze-${HEMI}.${RIGHT}.${REGION}.${SURFACE}.txt.grid      \
      $G_RIGHTBORDER
    boxBorder_draw

done

