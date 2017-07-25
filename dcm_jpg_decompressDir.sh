#!/bin/bash


# "include" the set of common script functions
source common.bash

declare -i Gi_verbose=0
declare -i Gb_useOverrideOut=0

G_SYNOPSIS="

NAME

        dcm_jpg_decompressDir.bash

 SYNOPSIS

        dcm_jpg_decompressDir    -D <dicomInputDir>                     \\
                                [-v <verbosity>]                        \\
                                [-O <dicomOutputDir>]                   \\
 
 DESCRIPTION

        'dcm_anonymize.bash' accepts an input directory containing DICOM
        files and anonymizes the data. Output directory is the standard
        postproc stream.

 ARGUMENTS

        -v <level> (optional)
        Verbosity level.

        -D <dicomInputDir>
        The directory containing DICOM files for a particular study.

        -O <OutDir> (optional) (Default: $G_OUTDIR)
        The output directory.


 PRECONDITIONS

        o source neuro-fs stable

 POSTCONDITIONS

        o Output decompressed dcms are stored in:

              <OutDir>

"

###\\\
# Process command options
###///

while getopts D:v:O: option ; do 
        case "$option"
        in
                D)      G_DICOMINPUTDIR=$OPTARG         ;;
                v)      let Gi_verbose=$OPTARG          ;;
                O)      Gb_useOverrideOut=1
                        G_OUTDIR=$OPTARG                ;;
                \?)     synopsis_show 
                        exit 0;;
        esac
done

if (( !Gb_useOverrideOut )) ; then 
        G_OUTDIR=${G_DICOMINPUTDIR}-jpgDecompress
fi

verbosity_check
topDir=$(pwd)

cprint "Input Dir" $G_DICOMINPUTDIR
cprint "Ouput Dir" $G_OUTDIR

cp -pvdri $G_DICOMINPUTDIR $G_OUTDIR
cd $G_OUTDIR
for file in *dcm ; do
    if [[ -f $file ]]; then
        #http://wiki.bash-hackers.org/syntax/pe#substring_removal
        echo $file
        dcmdjpeg -v $file ${file##*/}
    fi
done

shut_down 0
