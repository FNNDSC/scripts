#!/bin/bash
#


# "include" the set of common script functions
source common.bash

declare -i Gb_cleanTmpImages=1

declare -i Gb_XBuffer=0
declare -i G_XDisplay=1

declare -i Gi_verbose=0
declare -i Gb_showInfo=0
declare -i Gb_saveAnalyze=0

G_imageMagFactor="1"
declare -i Gb_size=0
declare -i Gi_Xsize=500
declare -i Gi_Ysize=400
declare -i Gb_perc=0
declare -i Gi_xperc=25
declare -i Gi_yperc=25

G_dropThrough=""
Gb_dropThroughArgs=0

G_trackVolume="-x"
G_trackVolumeBase="-x"

G_XVFB="Xvfb"
G_plane="SAG"
G_fontDir="/usr/share/fonts/truetype/"
declare -a GA_planeSliceArg=( "-nx" "-ny" "-nz")
#                              SAG   COR   AXI
declare -i Gb_volumeSlice=0
declare -i Gb_sliceStart=0
declare -i Gi_sliceStart=0
declare -i Gb_sliceEnd=0
declare -i Gi_sliceEnd=0
declare -i Gb_sliceStep=0
declare -i Gi_sliceStep=1
declare -i Gi_totalSlices=0
declare -i Gi_sliceThickness=1
declare -i Gb_annotateText=0
declare -i Gb_forceStage=1
declare -i G_LC=40

CONVERTBIN=/usr/bin/convert

G_SYNOPSIS="

 NAME

	track_slice.bash

 SYNOPSIS

	track_slice.bash	[-v <verbosity>]			\\
				[-S|-C|-A|-V]				\\
				[-T <totalSlices>] [-k <thickness>]	\\
					[-b <sliceStart>]		\\
					[-s <sliceStep>]		\\
					[-e <sliceEnd>]			\\
				[-m <imageMagFactor>]			\\
					[-X <absoluteXsize>]		\\
					[-Y <absoluteYsize>]		\\
					[-x <percentXsize>]		\\
					[-y <percentYsize>]		\\
				[-i]					\\
				[-a]					\\
				[-o]					\\
				[-E]					\\
				[-d <XvfbScreenDisplay>] [-B <XvfbBin>]	\\
				[-D <dropThroughArgs>]			\\
				-t <trackVolume>

 DESCRIPTION

	'track_slice.bash' is a shell wrapper about a 'track_vis' process.
	Its primary purpose is to slice a trackvis 'volume' into slabbed
	image segments, which are then saved as 'jpg' screen snapshots.

	It forms part of a larger processing pipeline that, downstream from
	here, pushes the sliced jpegs into a PACS system.

 ARGUMENTS

	-v <level> (optional)
	Verbosity level.

	-S|-C|-A|-V (optional, default -V)
	Slice plane options, either Sagittal, Coronal, Axial, or Volume.
	The Volume option will slice across along each of the three 
	SCA planes.

	-T <totalSlices> (optional, default $G_totalSlices)
	For the chosen slice plane, generate <totalSlices> evenly spaced slabs
	of <thickness>.

	-k <thickness> (optional, default $G_sliceThickness)
	The thickness of a slab, in logical slice units.

	-b <sliceStart> [-s <sliceStep>] -e <sliceEnd>
	An alternate method of specifying slabs. Here, set a slice start
	index, a skip step, and an end slice. <sliceStep> defaults to '1'. 
	If a <totalSlices> has also been specified, then any of these settings
	are ignored.

	-m <imageMagFactor> (optional, default $Gi_imageMagFactor)
	The magnification factor for saved images. If specified, increase the
	images by a factor of <imageMagFactor>.

	-X <absoluteXsize> (optional, default $Gi_Xsize)
	If specified, define the width in pixels of final image. This image 
	is 'cropped' from the original such that its center point is coincident
	with the original center.

	-Y <absoluteYsize> (optional, default $Gi_Ysize)
	If specified, define the height in pixels of final image. This image 
	is 'cropped' from the original such that its center point is coincident
	with the original center.

	-x <percentXsize> (optional, default $Gi_xperc)
	If specified, define the width (as percentage of original width) of 
	final image. This image is 'cropped' from the original such that its 
	center point is coincident with the original center. Note that the
	argument is an integer percentage value between 1 and 100.

	-y <percentYsize> (optional, default $Gi_yperc)
	If specified, define the height (as percentage of original height) of 
	final image. This image is 'cropped' from the original such that its 
	center point is coincident with the original center. Note that the
	argument is an integer percentage value between 1 and 100.

	-i (optional, default $Gb_showInfo)
	Show info. The track volume is rendered briefly and console information
	captured and written to the console.

	-a (optional, default $Gb_annotateText)
	If true, annotate each image created with a text label that conveys
	the plane, slice index, and thickness.

	-o (optional, default $Gb_saveAnalyze)
	If specified, output the displayed tracks also to an analyze volume.
	The name of the volume file is based on the current plane, slice
	index, and slab thickness.

	-E (optional, default $Gb_cleanTmpImages)
	Keep temporary images. Useful mainly for debugging purposes. If 
	specified, keeps all intermediary images that were generated.

	-B <XvfbScreenDisplay> 	(optional, default $Gb_XBuffer)
	-b <XvfbBin>		(optional, default $G_XVFB)
	If specified, draw images to the <XvfbScreenDisplay> display of a 
	spawned Xvfb server. This removes the need for an active X Server 
	and allows 'track_slice.bash' to run on a headless display (or from
	a web server).

	The '-b <XvfbBin>' allows the specification of the actual Xvfb process
	to run. Useful is Xvfb is not installed on the standard PATH.

	-D <dropThroughArgs> (optional, default $G_dropThrough)
	Additional arguments that are passed 'as is' to the underlying
	'track_vis' engine without processing by the wrapper script.

	-t <trackVolume>
	The actual trk format volume to process.


 PRECONDITIONS
	
	o A FreeSurfer 'std' or 'dev' environment.

        o You will need the following files in your PATH:

                * 'track_vis'
                  The actual trackvis backend program.

	o ImageMagick 'convert' tools.

 POSTCONDITIONS

	o For a given track 'volume', a series of sliced
	  images is generated.

	o The -X -Y and -x -y arguments 'crop' parts of the
	  sliced image. Note that the -x and -y take precedence
	  over -X and -Y.

	o Each slice plane is stored in its own directory, created
	  off current working dir.

	o For the SAG and AXI planes, the display is rotated before
	  slicing.

 HISTORY

	13 November 2007
	o Initial design and coding.

	17 April 2008
	o SAG / AXI rotations
	o Plane-specific directories

"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///

# Actions
A_fileCheck="checking for a required file dependency"
A_noTrackVolumeArg="checking for the -t <trackVolume> argument"
A_noTrackVolume="checking if the <trackVolume> exists"
A_noSubjectsDirVar="checking environment"
A_noSubjectsDir="checking environment"
A_noSubjectBase="checking base subject dir"
A_comargs="checking command line arguments" 
A_noComSpec="checking for command spec"
A_noOptionsFile="checking for 'options.txt' file"
A_metaLog="checking the track_slice.bash.log file"
A_cropPercX="checking the percentage X crop value"
A_cropPercX="checking the percentage Y crop value"
A_checkingSizePerc="checking the size and percentage command line args"
A_noFontDir="checking for fonts to be used to annotate images"
A_noXvfb="starting Xvfb"

# Error messages
EM_fileCheck="it seems that a dependency is missing."
EM_noTrackVolumeArg="it seems that not <trackVolume> was specified."
EM_noTrackVolume="I am having problems accessing the <trackVolume>. Does it exist?"
EM_noSubjectsDirVar="it seems that the SUBJECTS_DIR environment var is not set."
EM_noSubjectsDir="it seems that the SUBJECTS_DIR refers to an invalid directory."
EM_noSubjectBase="I couldn't find a subject base directory."
EM_comargs="it seems that a required command line argument is missing."
EM_noComSpec="no command spec was found."
EM_noOptionsFile="I can't seems to access the 'options.txt' file."
EM_metaLog="it seems as though this stage has already run.\n\tYou can force execution with a '-f'"
EM_cropPercX="an invalid percentage was provided. Should be integer: 1.. 100"
EM_cropPercY="an invalid percentage was provided. Should be integer: 1.. 100"
EM_checkingSizePerc="you have specified *both* a size and percentage!"
EM_noFontDir="a required directory containing 'arial.ttf' is missing. Check the dependencies for 'convert'."
EM_noXvfb="the X virtual frame buffer did not start."

# Error codes
EC_fileCheck=1
EC_noTrackVolumeArg=10
EC_noTrackVolume=11
EC_noSubjectsDirVal=20
EC_noSubjectsDir=21
EC_noSubjectBase=22
EC_comargs=30
EC_noComSpec=31
EC_noOptionsFile=40
EC_metaLog=80
EC_cropPercX=91
EC_cropPercY=92
EC_checkingSizePerc=93
EC_noFontDir=51
EC_noXvfb=61

# Defaults
D_whatever=

###\\\
# Function definitions
###///

function p2i
{
        #
        # ARGS
        # $1            in              plane name
        #
        # DESC
        # Maps plane name to an index lookup
        #

        local plane=$1
        local index=""
        case $plane
        in
                "SAG")  index=0         ;;
                "COR")  index=1         ;;
                "AXI")  index=2         ;;
                "TRA")	index=2         ;;
        esac
        echo $index
}

###\\\
# Process command options
###///

let G_sliceStart=0
let G_sliceEnd=1
let G_sliceStep=1


while getopts v:b:s:e:T:k:SCAVit:om:X:Y:x:y:aEB:d:D: option ; do 
	case "$option"
	in
		v) Gi_verbose=$OPTARG 					;;
		b) Gi_sliceStart=$OPTARG				
		   Gb_sliceStart=1					;;
		s) Gi_sliceStep=$OPTARG					
		   Gb_sliceStep=1					;;
		e) Gi_sliceEnd=$OPTARG					
		   Gb_sliceEnd=1					;;
		t) G_trackVolume=$OPTARG	
		   G_trackVolumeBase=$(basename $G_trackVolume .trk)	;;
		S) G_plane="SAG"					;;
		C) G_plane="COR"					;;
		A) G_plane="AXI"					;;
		V) Gb_volumeSlice=1					;;
		m) G_imageMagFactor=$OPTARG				;;
		X) Gb_size=1
		   Gi_Xsize=$OPTARG					;;
		Y) Gb_size=1
		   Gi_Ysize=$OPTARG					;;
		x) Gb_perc=1
		   Gi_xperc=$OPTARG					;;
		y) Gb_perc=1
		   Gi_yperc=$OPTARG					;;
		i) Gb_showInfo=1					;;
		o) Gb_saveAnalyze=1					;;
		T) Gi_totalSlices=$OPTARG				;;
		a) Gb_annotateText=1					;;
		E) Gb_cleanTmpImages=0					;;
		d) Gb_XBuffer=1			
		   G_XDisplay=$OPTARG					;;
		B) G_XVFB=$OPTARG					;;
		D) G_dropThrough=$OPTARG
		   Gb_dropThroughArgs=1					;;
		\?) synopsis_show 
		    exit 0;;
	esac
done

verbosity_check
topDir=$(pwd)
STAMPLOG=${topDir}/${G_SELF}.log

echo ""
cprint  "hostname"      "[ $(hostname) ]"

printf "%40s"   "Checking for <trackVolume> argument"
if [[ "$G_trackVolume" == "-x" ]] ; then
        fatal noTrackVolumeArg
fi
ret_check $?

printf "%40s"   "Checking if <trackVolume> is accessible"
fileExist_check $G_trackVolume || fatal noTrackVolume

TRACKDIR=$(dirname $G_trackVolume)
cd $TRACKDIR
TRACKDIR=$(pwd)
cd $topDir

G_trackVolume=${TRACKDIR}/${G_trackVolumeBase}.trk

REQUIREDFILES="track_vis /usr/bin/convert common.bash mkill"
for file in $REQUIREDFILES ; do
        printf "%40s"   "Checking for $file..."
        file_checkOnPath $file || fatal fileCheck
done

cprint "Image magnification factor" "[ $G_imageMagFactor ]"

if (( Gb_size )) ; then
    cprint "Crop to center absolute X image size"	"[ $Gi_Xsize ]"
    cprint "Crop to center absolute Y image size"	"[ $Gi_Ysize ]"
fi

if (( Gb_perc )) ; then
    cprint "Crop to center percentage X image size"	"[ $Gi_xperc% ]"
    cprint "Crop to center percentage Y image size"	"[ $Gi_yperc% ]"
fi

if (( Gb_size && Gb_perc )) ; then
    beware checkingSizePerc
fi

if (( b_CheckPreConditions )) ; then
	NOP
fi

# if (( Gb_annotateText )) ; then
#     printf "%40s" "Checking for $G_fontDir"
#     dirExist_check $G_fontDir || fatal noFontDir
# fi

if (( Gb_XBuffer )) ; then
    #
    # NOTE: The screen depth of 24 for Xvfb is critical!
    #
    if [[ $G_XVFB == "Xvfb" ]] ; then
    	statusPrint	"Checking for Xvfb binary on PATH"
    	file_checkOnPath $G_XVFB || noXvfb
    else
	statusPrint	"Checking on passed Xvfb binary"
	fileExist_check	$G_XVFB || noXvfb
    fi
    export DISPLAY=:${G_XDisplay}
    cprint "Setting Xvfb display"	"[ $G_XDisplay ]"
    STAGE="Xvfb"
    STAGECMD="$G_XVFB :${G_XDisplay} -screen 1 1600x1200x24 2>/dev/null"
#     stage_run "$STAGE" "$STAGECMD" ./${STAGE}.std" "./${STAGE}.err || fatal noXvfb
    echo "$STAGECMD &" | sh
fi

stage_stamp "Init | ($topDir) $G_SELF $*" $STAMPLOG

STAGE="Determining track info"
echo "$(date) | $STAGE"
CONSOLE=$(track_vis -nr $G_trackVolume)
rm -f info.png 2>/dev/null
DIM=$(echo "$CONSOLE" 	| grep "Volume dimension")
SAG=$(echo "$DIM" 	| awk '{print $3}')
COR=$(echo "$DIM" 	| awk '{print $4}')
AXI=$(echo "$DIM" 	| awk '{print $5}')
stage_stamp "$STAGE" $STAMPLOG

if (( Gb_showInfo )) ; then echo "$DIM" ; fi
echo "$CONSOLE" > ${G_trackVolumeBase}.info

declare -i i_maxSlices=0
declare -i i_currentSlab=0
declare -i i_endNumber=0
# while (( 1 > 2 )) ; do
for plane in "SAG" "COR" "AXI" ; do
    cd $topDir >/dev/null
    if [[ "$G_plane" == "$plane" || "$Gb_volumeSlice" == "1" ]] ; then
	STAGE=$plane
        stage_stamp "$STAGE | START" $STAMPLOG
	statusPrint "Checking on plane specific output dir"
	dirExist_check $plane || mkdir $plane
	cd $plane
        eval i_maxSlices=\$$plane
        if (( !Gi_sliceEnd )) ; then Gi_sliceEnd=$i_maxSlices; fi
        if (( Gi_sliceEnd > i_maxSlices )) ; then 
            Gi_sliceEnd=$i_maxSlices ; 
        fi
	if (( Gb_volumeSlice && !Gb_sliceEnd )) ; then
	    Gi_sliceEnd=$i_maxSlices
	fi
	if (( Gi_totalSlices )) ; then
	    if [ "$Gi_totalSlices" -eq "1" ] ; then
	    	# Just output the center slice
	    	Gi_sliceStep=1
	    	Gi_sliceStart=$(echo "$i_maxSlices/2" | bc)
	    	Gi_sliceEnd=$Gi_sliceStart	    	
	    else
	    	Gi_sliceStep=$(echo "$i_maxSlices/$Gi_totalSlices" | bc)
	    	Gi_sliceStart=0
	    	Gi_sliceEnd=$i_maxSlices
	    fi
	fi
	# echo $i_maxSlices $Gi_totalSlices $Gi_sliceStart $Gi_sliceEnd $Gi_sliceStep
        cprint "Number of slices to create in $STAGE..." "[ $i_maxSlices ]"
        cprint "Loop parameters" "[ $Gi_sliceStart; $Gi_sliceEnd; $Gi_sliceStep ]"
        for ((  i_currentSlab=$Gi_sliceStart ; 				\
		i_currentSlab<=$Gi_sliceEnd ; 				\
		i_currentSlab+=$Gi_sliceStep )) ; do
	    printf " %s | Slicing plane %s: %d/%d (%d)\n"               \
				"$(date)"				\
				"$plane" 				\
				"$i_currentSlab" 			\
                                "$Gi_sliceEnd"                          \
				"$Gi_sliceThickness"
	    i_endNumber=$(echo $i_currentSlab + $Gi_sliceThickness | bc)
	    snapshotFile=""
	    snapshotFile=$(printf "%s%s" "$snapshotFile"	"$G_trackVolumeBase")
	    snapshotFile=$(printf "%s%s" "$snapshotFile"	"-$plane")
	    snapshotFile=$(printf "%s%s" "$snapshotFile"	"-$i_currentSlab")
	    snapshotFile=$(printf "%s%s" "$snapshotFile"	"-$Gi_sliceThickness")
	    if (( Gb_saveAnalyze )) ; then 
		saveAnalyze="-ov $snapshotFile"
	    else
		saveAnalyze=""
	    fi
            STAGE="track_vis"
	    ROTATECMD=""
	    if [[ $plane == "SAG" ]] ; then ROTATECMD="-camera azimuth 90"; fi
	    if [[ $plane == "AXI" ]] ; then ROTATECMD="-camera elevation -90" ; fi
	    rm -f tmp.cam 2>/dev/null
            STAGECMD="track_vis $G_trackVolume				\
			${GA_planeSliceArg[$(p2i $plane)]}		\
			$i_currentSlab					\
		 	$i_endNumber $saveAnalyze $G_dropThrough	\
			$ROTATECMD					\
			-mag $G_imageMagFactor				\
			-sc $snapshotFile"
            stage_run "$STAGE" "$STAGECMD" "./${STAGE}.std" "./${STAGE}.err" "NOECHO"

	    # Get image size
	    imageSize=$(identify $snapshotFile.png			|\
			head -n 1					|\
			awk '{print $3}')

	    if (( Gb_size || Gb_perc )) ; then
	        imageX=$(echo $imageSize | awk -Fx '{print $1}')
	        imageY=$(echo $imageSize | awk -Fx '{print $2}')
		cprint "Original image Xsize" "[ $imageX ]"
		cprint "Original image Ysize" "[ $imageY ]"
	        if (( Gb_perc )) ; then
		    Gi_Xsize=$(echo -e "scale=0\n 
					$imageX * 0.$Gi_xperc\n
					quit\n" | bc | awk -F \. '{print $1}')
		    Gi_Ysize=$(echo -e "scale=0\n 
					$imageY * 0.$Gi_yperc\n
					quit\n" | bc | awk -F \. '{print $1}')
	        fi
	        ox=$(echo -e "scale = 0 \n ($imageX - $Gi_Xsize)/2 \n quit \n" | bc)
	        oy=$(echo -e "scale = 0 \n ($imageY - $Gi_Ysize)/2 \n quit \n" | bc)
		statusPrint 						\
                    "Cropping image to ${Gi_Xsize}x${Gi_Ysize}+${ox}+${oy}" "\n"
                STAGE="convert"
                STAGECMD="convert -crop 				        \
			  ${Gi_Xsize}x${Gi_Ysize}+${ox}+${oy} 			\
			  ${snapshotFile}.png ${snapshotFile}-cropped.png"
                stage_run "$STAGE" "$STAGECMD" "./${STAGE}.std" "./${STAGE}.err"

		mv ${snapshotFile}.png ${snapshotFile}.orig.png
		cp ${snapshotFile}-cropped.png ${snapshotFile}.png
	    fi
	    if (( Gb_annotateText )) ; then
		printf "%40s"	"Annotating image..."
		LABEL="$G_trackVolumeBase "
                f_perc="0.00"
                if (( Gi_sliceEnd )) ; then
                  i100=$(echo "$i_currentSlab * 100" | bc)
                  f_perc=$(echo "scale=2;$i100/${Gi_sliceEnd}" | bc)
                fi
		LABEL="$LABEL $plane: SLICE $i_currentSlab/$Gi_sliceEnd (${f_perc}%)"
		LABEL="$LABEL LOGICAL WIDTH: $Gi_sliceThickness"
		convert ${snapshotFile}-cropped.png ${snapshotFile}-cropped.jpg
		convert ${snapshotFile}-cropped.jpg 			\
			-gravity South -background skyblue -splice 0x18	\
			-draw "text 0,0 '$LABEL'" ${snapshotFile}.png 
		rm ${snapshotFile}-cropped.jpg 2>/dev/null
		ret_check $?
	    fi

	    if (( Gb_cleanTmpImages )) ; then
		printf "%40s"	"Cleaning tmp images..."
		rm ${snapshotFile}-cropped.png 2>/dev/null
		rm ${snapshotFile}.orig.png 2>/dev/null
		ret_check $?
	    fi
	done
        stage_stamp "$plane | END" $STAMPLOG
    fi
done

if (( Gb_XBuffer )) ; then
	statusPrint	"Shutting down Xvfb"
	ps -Af  | grep Xvfb | grep -v $G_SELF | grep -v grep | awk '{print "kill -9 " $2}' | sh 2>/dev/null >/dev/null
	ret_check $?
fi

STAGE="Normal termination"
stage_stamp "$STAGE" $STAMPLOG

printf "%40s" "Cleaning up"
shut_down 0

