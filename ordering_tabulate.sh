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

        ordering_tabulate.sh

  SYNOPSIS
  
        ordering_tabulate.sh -h <hemi> -r <region> -s <surface>         \
                                [-S <sepString>] [-G <groupNum>]        \
                                [-T]


  DESC

        'ordering_tabulate.sh' is rather simple script that creates
        a table of data suitable for incorporation into papers/presentations.

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

  HISTORY
  
  02 December 2010
  o Initial design and coding.
  
  11 March 2011
  o Group additions.

"

while getopts h:r:s:S:G:T option ; do
    case "$option" 
    in
        h) HEMI=$OPTARG         ;;
        r) REGION=$OPTARG       ;;
        s) SURFACE=$OPTARG      ;;
        S) G_SEPSTRING=$OPTARG  ;;
        G) G_GROUPNUM=$OPTARG   ;;
        T) Gb_extraLines=1      ;;
    esac
done

if (( Gb_extraLines )) ; then G_EXTRALINES="|||" ; fi

printf "%15s%s" "curv" "$G_SEPSTRING"
for GROUP in $G_GROUPS ; do 
    for SIGN in $G_SIGN ; do
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
    for GROUP in $G_GROUPS ; do
      for SIGN in $G_SIGN ; do
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
                ordering=${Xorder//' '/$G_EXTRALINES}
            else
                ordering=${Yorder//' '/$G_EXTRALINES}
            fi
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

