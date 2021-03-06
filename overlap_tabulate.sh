#!/bin/bash

G_SIGN="neg pos"
G_GROUPNUM=3
G_CURVpos="K K1 K2 H S C BE thickness"
G_CURVneg="K K1 K2 H"
G_TYPE=""

G_SEPSTRING=""

# User spec'd
HEMI=lh
SURFACE=smoothwm
REGION=frontal

G_SYNPOSIS="

  NAME

        overlap_tabulate.sh

  SYNOPSIS
  
        overlap_tabulate.sh -h <hemi> -r <region> -s <surface> \
                                [-n <sign>]
                                [-T <optionalType>]
                                [-S <sepString>] [-G <groupNum>]

  DESC

        'overlap_tabulate.sh' is rather simple script that creates
        a table of data suitable for incorporation into papers/presentations.

        It essentially reads the '*-overlap' file for a file of name:
        
            <sign>-<group>-<hemi>-<curv>-<region>-<surface>.txt-overlap
            
        and creates a table of overlaps for groups by curvature functions.

  ARGS

        -n <sign>
        The curvature sign to process ('neg', 'pos', or 'neg pos').

        -h <hemi>
        The hemisphere to process ('lh' or 'rh').
        
        -r <region>
        The region to process ('frontal', 'temporal', 'parietal', 'occipital)'

        -s <surface>
        The surface to process ('smoothwm', 'pial')

        -T <optionalType>
        More accurate overlap analysis is available using the CentroidCloud
        analysis. By specifying either 'L' or 'R' here, the Left or Right
        polygon deviation percentage overlap is displayed.
        
        -S <sepString>
        Print <sepString> between field columns.
        
        -G <groupNum>
        The number of a priori groupings.

  HISTORY
  
  15 November 2010
  o Initial design and coding.
  
  10 March 2010
  o Group spec.

  08 March 2013
  o Type spec.

  17 April 2013
  o Sign spec.
"

while getopts h:r:s:n:S:G:T: option ; do
    case "$option" 
    in
        n) G_SIGN="$OPTARG"     ;;
        h) HEMI=$OPTARG         ;;
        r) REGION=$OPTARG       ;;
        s) SURFACE=$OPTARG      ;;
        S) G_SEPSTRING=$OPTARG  ;;
        G) G_GROUPNUM=$OPTARG   ;;
        T) G_TYPE=$OPTARG       ;;
    esac
done

# To find the combinations, in MatLAB use:
#       C = combnk(1:5,2)
# for all the combinations of 5 groups.
case "$G_GROUPNUM"
in 
        1) G_GROUPS="1-1"                       ;; # This is actually meaningless
        2) G_GROUPS="1-2"                       ;;
        3) G_GROUPS="1-2 2-3 1-3"               ;;
        4) G_GROUPS="1-2 1-3 1-4 2-3 2-4 3-4"   ;;
        5) G_GROUPS="1-2 1-3 1-4 1-5 2-3 2-4 2-5 3-4 3-5 4-5" ;;
        6) G_GROUPS="1-2 1-3 1-4 1-5 1-6 2-3 2-4 2-5 2-6 3-4 3-5 3-6 4-5 4-6 5-6" ;;
esac

printf "%15s%s" "curv" "$G_SEPSTRING"
for SIGN in $G_SIGN ; do
   for GROUP in $G_GROUPS ; do 
        printf "%15s%s" "$SIGN-$GROUP" "$G_SEPSTRING"
   done
done
printf "\n"

for CURV in $G_CURVpos ; do
    printf "%15s%s" "$CURV" "$G_SEPSTRING"
    for SIGN in $G_SIGN ; do
        for GROUP in $G_GROUPS ; do
            fileName=${SIGN}-${GROUP}-centroids-analyze-${HEMI}.${CURV}.${REGION}.${SURFACE}.txt-overlap${G_TYPE}
            if [[ -f $fileName ]] ; then
                overlap=$(cat $fileName)
            else
                overlap="NaN"
            fi
            printf "%15.5f%s" $overlap "$G_SEPSTRING"
        done
    done
    printf "\n"
done

