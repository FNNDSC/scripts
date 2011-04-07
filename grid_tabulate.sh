#!/bin/bash

G_SIGN="neg pos"
G_GROUPS="X Y"
G_CURVpos="K K1 K2 H S C BE thickness"
G_CURVneg="K K1 K2 H"
G_GROUPNUM="3"
G_SEPSTRING=""

let Gb_extraLines=0
G_EXTRALINES=""

# User spec'd
HEMI=lh
SURFACE=smoothwm
REGION=frontal

G_SYNPOSIS="

  NAME

        grid_tabulate.sh

  SYNOPSIS
  
        grid_tabulate.sh -h <hemi> -r <region> -s <surface>             \
                                [-S <sepString>] [-G <groupNum>]        \
                                [-T]


  DESC

        'grid_tabulate.sh' is rather simple script that creates
        2D grids of group cluster spatial arrangements.

        It essentially reads the group centroid file of form:
        
            <sign>-centroids-analyze-<hemi>-<curv>-<region>-<surface>.txt
            
        and processes the X and Y centroid positions, returning the group
        indices in increasing order along each dimension.
        
        This provides a quick summary of the spatial ordering of the groups.

  ARGS

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

  POSTCONDITIONS
  o For each pos,neg for each curv, for each region, for each surface, create:
      <fileName>.grid
      <fileName>.xord
      <fileName>.yord

  HISTORY
    
  25 March 2011
  o Grid additions.

"

while getopts h:r:s:S:G:T option ; do
    case "$option" 
    in
        h) HEMI=$OPTARG         ;;
        r) REGION=$OPTARG       ;;
        s) SURFACE=$OPTARG      ;;
        S) G_SEPSTRING=$OPTARG  ;;
        G) G_GROUPNUM=$OPTARG   ;;
    esac
done


printf "%15s%s" "curv" "$G_SEPSTRING"
for SIGN in $G_SIGN ; do
    for GROUP in $G_GROUPS ; do
        printf "%15s%s" "$SIGN-${GROUP}${G_EXTRALINES}" "$G_SEPSTRING"
    done
done
printf "\n"

declare -a a_X
declare -a a_Y
declare -a a_GIDLINE

if (( Gb_extraLines )) ; then G_EXTRALINES="|" ; fi

for CURV in $G_CURVpos ; do
    printf "%15s%s" "$CURV" "$G_SEPSTRING"
    for SIGN in $G_SIGN ; do
      for GROUP in $G_GROUPS ; do
        fileName=${SIGN}-centroids-analyze-${HEMI}.${CURV}.${REGION}.${SURFACE}.txt
        if [[ -f $fileName ]] ; then
            centroids=$(cat $fileName)
            for line in $(seq 1 $G_GROUPNUM) ; do 
                a_GIDLINE[line]=$(echo "$centroids" | sed '/^\([\t ]*\)'$line'/!d')
                a_X[line]=$(echo "${a_GIDLINE[$line]}" | awk '{print $2}')
                a_Y[line]=$(echo "${a_GIDLINE[$line]}" | awk '{print $3}')
            done
            Xorder=$(echo "${a_X[@]}" | tr ' ' '\n' | asort.awk -v width=1 -v b_indexOrder=1)
            Yorder=$(echo "${a_Y[@]}" | tr ' ' '\n' | asort.awk -v width=1 -v b_indexOrder=1 -v b_descend=1)
            if [[ "$GROUP" == "X" ]] ; then 
                Xordering=${Xorder//' '/}
                ordering=${Xorder//' '/$G_EXTRALINES}
            else
                Yordering=${Yorder//' '/}
                ordering=${Yorder//' '/$G_EXTRALINES}
            fi
            grid2D_show.py -S ${fileName}.grid -X $Xordering -Y $Yordering
            echo $Xordering > ${fileName}.xord
            echo $Yordering > ${fileName}.yord
        else
            if (( Gb_extraLines )) ; then
                ordering="N|N|N|"
            else
                ordering="NaN"
            fi
        fi
        printf "%15s%s" "$ordering" "$G_SEPSTRING" 
      done
    done
    printf "\n"
done

