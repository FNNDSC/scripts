#!/bin/bash

G_SIGN="neg pos"
G_GROUPNUM=3
G_CURVpos="K K1 K2 H S C BE thickness"
G_CURVneg="K K1 K2 H"

G_SEPSTRING=""

# User spec'd
HEMI=lh
SURFACE=smoothwm
REGION=frontal

G_SYNPOSIS="

  NAME

        areas_tabulate.sh

  SYNOPSIS
  
        areas_tabulate.sh -h <hemi> -r <region> -s <surface> \
                                [-S <sepString>] [-G <groups>]

  DESC

        'areas_tabulate.sh' is rather simple script that creates
        a table of data suitable for incorporation into papers/presentations.

        It essentially reads the statistical region area file for a given
        analysis. Files are of the form:
        
            <sign>-<area>-<hemi>.<curv>.<region>.<surface>.txt
            
  ARGS

        -h <hemi>
        The hemisphere to process ('lh' or 'rh').
        
        -r <region>
        The region to process ('frontal', 'temporal', 'parietal', 'occipital)'

        -s <surface>
        The surface to process ('smoothwm', 'pial')
        
        -S <sepString>
        Print <sepString> between field columns.
        
        -G <groups>
        The number of groups in this sample.

  HISTORY
  
  15 November 2010
  o Initial design and coding.

"

while getopts h:r:s:S:G: option ; do
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
   for GROUP in $(seq 1 $G_GROUPNUM) ; do 
        printf "%15s%s" "$SIGN-$GROUP" "$G_SEPSTRING"
   done
done
printf "\n"

for CURV in $G_CURVpos ; do
    printf "%15s%s" "$CURV" "$G_SEPSTRING"
    for SIGN in $G_SIGN ; do
        for GROUP in $(seq 1 $G_GROUPNUM) ; do
            fileName=${SIGN}-A${GROUP}-${HEMI}.${CURV}.${REGION}.${SURFACE}.txt
            if [[ -f $fileName ]] ; then
                area=$(cat $fileName | head -n 1)
            else
                area="NaN"
            fi
            printf "%15.5f%s" $area "$G_SEPSTRING"
        done
    done
    printf "\n"
done

