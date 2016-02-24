#!/bin/bash

G_STARTDIR="./"
G_OUTDIR="/tmp"
G_FORMAT="nii"

# "include" the set of common script functions
source common.bash

G_SYNOPSIS="

 NAME

        recur_mri_convert.sh

 SYNOPSIS

        recur_mri_convert.sh [-S <startPath>] [-O <outdir>] [-f <format>]

 DESCRIPTION

        'recur_mri_convert.sh' walks recursively down <startPath> flagging
        all directories that have files ending in 'dcm'. For each flagged 
	directory, the script will run 'mri_convert' on the first 'dcm' file 
	found, storing the output in <outDir> with a name constructed from the 
	flagged directory name.

 ARGUMENTS

        -S <startDir> (defaults to $G_STARTDIR)
        The start directory down which the script will walk.

        -O <outdir> (defaults to $G_OUTDIR)
        The directory that will store the converted files.
        
        -f <format> (defaults to $G_FORMAT)
        The output format to pass to mri_convert.
	
  PRECONDITIONS
  
  	o The parent shell/terminal must have sourced the FreeSurfer env, i.e.
	
		$>. neuro-fs stable
		
	
"

while getopts S:O:f: option ; do
        case "$option"
        in
                S)      G_STARTDIR=$OPTARG      ;;
                O)      G_OUTDIR=$OPTARG        ;;
                f)      G_FORMAT=$OPTARG        ;;
                \?)     synopsis_show
                        shut_down 1             ;;
        esac
done

here=$(pwd)        

if [[ ! -d $G_OUTDIR ]] ; then
        mkdir $G_OUTDIR
fi
cd $G_OUTDIR
G_OUTDIR=$(pwd)

cd $here

cd $G_STARTDIR
G_STARTDIR=$(pwd)
DIRS=$(find . -follow -iname "*.dcm"                                   | \
        awk -F \/ '{printf("%s/%s/%s/%s\n", $1, $2, $3, $4);}'  | \
        sort -u)

for DIR in $DIRS ; do
    cd $DIR
    outFile=$(echo $DIR | sed 's/^..//' | tr '/' '-')
    echo $outFile
    CMD="mri_convert $(/bin/ls -1 *dcm  | head -n 1) -o ${G_OUTDIR}/${outFile}.${G_FORMAT}"
    echo "$CMD" | sh -v
    echo ""
    cd $G_STARTDIR    
done         

cd $here


