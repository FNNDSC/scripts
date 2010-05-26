#!/bin/bash

source common.bash

declare -i Gb_customStorescu=0
declare -i Gi_verbose=0



G_ANALYSISDIR=../groupCurvAnalysis/aparc.annot

# Defaults
G_LOBE=pos	# pos or neg
G_HEMI=rh      	# rh or lh
G_CURV=H	# BE C H K1 K2 K S
G_GROUP=1	# 1 or 2

G_SYNOPSIS="

 NAME

        $G_SELF

 SYNOPSIS

        $G_SELF  \\
                                [-v <verbosity>]                        \\
                                [-a <expDir>]                           \\
                                [-l <lobe>]                             \\
                                [-h <hemi>]                             \\
                                [-c <curvatureFunc>]                    \\
                                [-g <group>]

 DESCRIPTION

        'centroid_groupAnalyze.bash' examines the centroid text files for
        given curvature function and prints the distance between 
        group centroids.

 PRECONDITIONS

        o common.bash script source.

 ARGUMENTS

        -v <level> (Optional)
        Verbosity level. A value of '10' is a good choice here.

        -e <analysisTopDir>
        Top level directory containing group data.

        -l <lobe> (optional, default = $G_LOBE)
        The positive or negative lobe of the centroid analysis to examine.

        -h <hemi> (optional, default = $G_HEMI)
        The hemisphere to process.

        -c <curvatureFunc> (optional, default = $G_CURV)
        The curvature function to process.

        -g <group> (optional, default = $G_GROUP)
        The group id to analyze.


"
# Actions
A_dirAccess="attempting to access a directory"

# Error messages
EM_dirAccess="I couldn't access the directory. Does it exist? Do you have access rights?"

# Error codes
EC_dirAccess="50"


while getopts a:l:h:c:g:v: option ; do
        case "$option"
        in
                a)      G_ANALYSISDIR=$OPTARG           ;;
                l)      G_LOBE=$OPTARG                  ;;
                h)      G_HEMI=$OPTARG                  ;;
                c)      G_CURV=$OPTARG                  ;;
                g)      G_GROUP=$OPTARG                 ;;
                v)      Gi_verbose=$OPTARG              ;;
                \?) 	synopsis_show
                    	exit 0;;
        esac
done

topDir=$pwd
verbosity_check

statusPrint     "Checking base dir"
dirExist_check  $G_ANALYSISDIR || fatal dirAccess
cd $G_ANALYSISDIR 
G_ANALYSISDIR=$(pwd)

STATS=$(find . -iname "${G_LOBE}-centroids-analyze-${G_HEMI}.${G_CURV}.*txt" \
        -exec cat {} \;                                                      |\
        grep "           $G_GROUP"                                           |\
        awk '{printf("%12.5f %12.5f\n", $6, $7)}'                            |\
        stats_print.awk)
MEANstd=$(echo "$STATS" | grep Mean | awk '{print $2}')
MEANrms=$(echo "$STATS" | grep Mean | awk '{print $3}')
STDstd=$(echo "$STATS" | grep Std | awk '{print $2}')
STDrms=$(echo "$STATS" | grep Std | awk '{print $3}')

printf "%12s"	"$G_CURV-$G_GROUP"
printf "%12.5f"	$MEANstd
printf "%12.5f"	$STDstd
printf "%12.5f"	$MEANrms
printf "%12.5f"	$STDrms

printf "\n"

cd $topDir
