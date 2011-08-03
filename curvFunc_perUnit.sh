#!/bin/bash
#
# Simple parser on Gaussian filtered tables that calculates the
# per unit curvature function per scale radius.
#


HEMI=$1         # rh/lh
CURV=$2         # K, K1, K2, ...
DOMAIN=$3       # Rectified, Negative, Positive
REGION=$4       # frontal, parietal, temporal
PLOT=$5         # 'pu' (per-unit), 'val', or 'perc'.
GROUP=$6        # if true, perform a group mean summary

b_group=${#GROUP}


matrix_perUnit=$(vcat ${HEMI}-${CURV}-${DOMAIN}-*${REGION}*-val ${HEMI}-${CURV}-${DOMAIN}-*${REGION}*-perc   |\
    grep -v SUBJECT | col_div2.awk -v precision=8 -v preserve=1 -v start=2)

matrix_perc=$(cat ${HEMI}-${CURV}-${DOMAIN}-*${REGION}*-perc    |\
    grep -v SUBJECT | matrix_scale.awk -v precision=8 -v preserve=1 -v start=2 -v scale=1)

matrix_val=$(cat ${HEMI}-${CURV}-${DOMAIN}-*${REGION}*-val      |\
    grep -v SUBJECT | matrix_scale.awk -v precision=8 -v preserve=1 -v start=2 -v scale=1)

matrix=matrix_perUnit

if (( ${#PLOT} )) ; then
    case $PLOT in 
        "pu")   matrix=matrix_perUnit   ;;
        "val")  matrix=matrix_val       ;;
        "perc") matrix=matrix_perc      ;;
    esac
fi

if (( b_group )) ; then
    for group in 1 2 3 ; do
       mean=$(echo "${!matrix}" | sed 's/[ \t]*//' | grep ^[$group] | stats_print.awk -v mean=1)
       echo "$mean" | awk '{for(col=3; col<=NF; col++) printf("%f\t", $col); printf("\n");}'
    done
else
    echo "${!matrix}"
fi
