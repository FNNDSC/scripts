#!/bin/bash
#

# "include" the set of common script functions
source common.bash

let Gi_verbose=0
let Gb_forceStage=0
let Gb_labelsSave=0

let Gb_labelRegion=0
let Gb_regionalPercentages=0

LABELREGION=""
TABLEFILESUFFIX=""
PROCESS=Gaussian
EXPDIR="./"
INTEGRALTYPE="Norm"
INTEGRALDOMAIN="Rectified"
HEMI="rh"
MRISCURVATURESTATS="mris_curvature_stats"
CONTINUOUSFORM=""
TEXTURELIST="K,K1,K2,H,C,S,BE"
FILTER="highPassFilterGaussian"
LOWPASSFILTER=1.5
#GAUSSIANLIST="1.0000,0.2500,0.1111,0.0625,0.0400,0.0278,0.0204,0.0156,0.0123,0.0100"
GAUSSIANLIST="0.1111,0.0625,0.0400,0.0278,0.0204,0.000"


G_SYNOPSIS="

 NAME

	curv_Kfilter.bash

 SYNOPSIS

	curv_Kfilter.bash 	        [-e <experimentTopDir>]		\\
					[-v <verbosity>]		\\
					[-T <textureList>]		\\
					[-K <cutoffList>]		\\
					[-H <hemisphere>]		\\
					[-h] [-c] [-L]			\\
                                        [-t <tableFileSuffix>           \\
					[-l <lowPassFilter>]		\\
					[-i <integralType>]		\\
                                        [-I <integralDomain>]           \\
                                        [-r <labelRegion>]              \\
                                        [-R]                            \\
					[-m <mris_curvature_stats>]	\\
					[<SUBJ1> <SUBJ2> ... <SUBJn>]

 DESCRIPTION

	'curv_Kfilter' is a simple wrapper script about a
	'mris_curvature_stats' processes that generates tables of values
	per subject and per <GAUSSIANLIST>. Each table reports for 
	each <TEXTURELIST> the normalized rectified integral for the
	particular <TEXTURELIST> function.

        The Gaussian curvature value is used as a 'scale' filter that
        tags regions of interest.

	Most of the heavy lifting is performed by the 'mris_curvature_stats'
	process.

 ARGUMENTS

	-e <experimentTopDir> (optional - default '$EXPDIR')
	The directory housing the <subjectDirList>.

	-v <level> (optional)
	Verbosity level.

	-T <textureList> (optional) (Default: $TEXTURELIST)
	A comma separated list of curvature functions to tabulate. One
	table per function is created. 

	-K <cutoffList> (optional) (Default: $GAUSSIANLIST)
	A comma separated list of cut off Gaussian curvatures. These
	comprise the *columns* of each table.

	-m <mris_curvature_stats> (optional) (Default: $MRISCURVATURESTATS)
	Use <mris_curvature_stats>. Useful to override a FreeSurfer path
	setting.

        -L (optional)
        If specified, describe the filtered region in a FreeSurfer label files.
        This will save a label per subject, per texture, per filter radius.

	-h (optional) 
	By default, the script passes the --highPassFilterGaussian to
	the underlyng 'mris_curvature_stats' process. By specifying this
	flag, the script will instead pass a --highPassFilter flag
	instead. This has the effect of filtering only on surface values,
	and not on the Gaussian of the surface vertex.

        -t <tableFileSuffix> (optional)
        If specified, append the <tableFileSuffix> to the generated table file
        name.

	-H <hemisphere> (optional) (Default: $HEMI)
	Hemisphere data to process.

	-l <lowPassFilter> (optional) (Default: $LOWPASSFILTER)
	Low pass filter curvatures by <lowPassFilter>.

	-i <integralType> (optional) (Default: $INTEGRALTYPE)
	Specifies the integral type to filter from 'mris_curvature_stats'.
	This defaults to the 'Mean' integral. Can also be  the 'Norm' integral.
	The 'Mean' averages the integral by the number of vertices counted,
	the 'Norm' averages the integral by the area of the vertices counted.
        Case insensitive.

	-I <integralDomain> (optional) (Default: $INTEGRALDOMAIN)
        Specifies the intergral domain to filter. One of 'negative', 
        'positive', or 'rectified'. Case insensitive.

	-c (optional) (Default: '$CONTINUOUSFORM')
	If specified, toggle the '--continuous' flag on the underlying
	'mris_curvature_stats' process. This selects the continuous Second 
        Order Fundamental form for calculating the prinicple curvatures.

        -r <labelRegion> (optional)
        If specified, constrain curvature analysis to the region defined in the
        label file <hemi>.<labelRegion>.label.

	[<SUBJ1> <SUBJ2> ... <SUBJn>]
 	List of subject IDs to process. These comprise the *rows* of each
	table.

 PRECONDITIONS

	o Run in directory with all the subject dirs extant.

	o The directories specified in the <subjectDirList> *must* have the
	  same names as specific subject IDs in SUBJECTS_DIR.	

 POSTCONDITIONS

	o A set of tables will be generated. Each table will be echoed
	  to both stdout and a <GAUSSIANLIST> file.

 NOTE
	o This script assumes a very fixed structure for the output
	  of 'mris_curvature_stats'. Any changes to this program's output
	  will probably require corresponding adaptations here.

 HISTORY

	16 April 2007
	o Initial design and coding.

	21 February 2008
	o 'common.bash' incorporation
	o Fixed scope to process locally generated curvature
	  maps, not original \$SUBJECTS_DIR maps --
	  pass a full curvature filename starting with
	  "./" to mris_curvature_stats to force reading of
	  local file, and not \$SUBJECTS_DIR equivalent.
          
       18 May 2010
       o Re-vamping as 'curv_Kfilter.bash'.

       31 August 2010
       o Added '-I <integralDomain>' to filter pos, neg, or rectified values.

"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///
G_SELF=`basename $0`
G_PID=$$

# Actions
A_noSubjectsDirVar="checking environment"
A_noSubjectsDir="checking environment"
A_noSubjectBase="checking base subject dir"
A_comargs="checking command line arguments" 
A_comargsE="checking command line argument '-e'" 
A_noComSpec="checking for command spec"
A_noExpDir="checking on the passed directory"
A_noHemisphere="checking the '-h' parameter"
A_noRhCurv="linking the right hemisphere curvature file"
A_noLhCurv="linking the left hemisphere curvature file"
A_gaussian="generating the Gaussian curvatures"
A_metaLog="checking the meta log file"
A_noMriVol="checking on the 'mri_volprocess' binary"
A_mriVolprocess="running the 'mri_volprocess' binary"

# Error messages
EM_noSubjectsDirVar="it seems that the SUBJECTS_DIR environment var is not set."
EM_noSubjectsDir="it seems that the SUBJECTS_DIR refers to an invalid directory."
EM_noSubjectBase="I couldn't find a subject base directory."
EM_noComSpec="no command spec was found."
EM_comargsE="I couldn't find the <experimentTopDir> specifier."
EM_noComSpec="no command spec was found."
EM_noExpDir="I couldn't find the <experimentTopDir>."
EM_noHemisphere="I couldn't find a valid specifier. Use either 'lh' or 'rh'."
EM_noRhCurv="I couldn't link the file."
EM_noLhCurv="I couldn't link the file."
EM_gaussian="some error occurred."
EM_metaLog="it seems as though this stage has already run.\n\tYou can force execution with a '-f'"
EM_noMriVol="I can't find the file on your current path"
EM_mriVolprocess="the program died unexpectedly"

# Error codes
EC_noSubjectsDir=1
EC_noSubjectBase=2
EC_noComSpec=3
EC_comargsE=12
EC_noComSpec=1
EC_noExpDir=23
EC_noHemisphere=30
EC_noRhCurv=31
EC_noLhCurv=32
EC_gaussian=40
EC_metaLog=80
EC_noMriVol=90
EC_mriVolprocess=100

# Defaults
D_whatever=

###\\\
# Process command options
###///

while getopts e:v:T:K:m:hcH:i:I:l:Lt:r:R option ; do 
	case "$option"
	in
		e) EXPDIR=$OPTARG 			;;
		v) Gi_verbose=$OPTARG 			;;
		h) FILTER="highPassFilter"		;;
		c) CONTINUOUSFORM="--continuous"	;;
		l) LOWPASSFILTER=$OPTARG		;;
                L) let Gb_labelsSave=1                  ;;
		i) INTEGRALTYPELIST=$OPTARG		;;
                I) INTEGRALDOMAINLIST=$OPTARG           ;;
		T) TEXTURELIST=$OPTARG			;;
                t) TABLEFILESUFFIX=$OPTARG              ;;
		K) GAUSSIANLIST=$OPTARG			;;
		H) HEMILIST=$OPTARG                     ;;
		m) MRISCURVATURESTATS=$OPTARG		;;
                r) let Gb_labelRegion=1
                   LABELREGION=$OPTARG                  ;;
                R) let Gb_regionalPercentages=1         ;;
		\?) synopsis_show 
		    exit 0;;
	esac
done


verbosity_check
startDir=$(pwd)
G_OUTDIR=$(pwd)
STAMPLOG=${G_OUTDIR}/${G_SELF}.log
statusPrint     "$STAMPLOG" "\n"
stage_stamp     "Init | ($startDir) $G_SELF $*" $STAMPLOG

statusPrint	"Checking for SUBJECTS_DIR env variable"
b_subjectsDir=$(set | grep SUBJECTS_DIR | wc -l)
if (( !b_subjectsDir )) ; then
	fatal noSubjectsDirVar
fi
ret_check $?

statusPrint	"Checking for SUBJECTS_DIR directory"
dirExist_check $SUBJECTS_DIR || fatal noSubjectsDir

statusPrint	"Checking for <experimentTopDir>"
dirExist_check $EXPDIR || mkdir -p $EXPDIR
cd $EXPDIR ; EXPDIR=$(pwd) ; cd $startDir

STAMPLOG=$EXPDIR/${G_SELF}.log
stage_stamp "0 | ($startDir) $G_SELF $*" $STAMPLOG

shift $(($OPTIND - 1))
CLISUBJECTS=$*
b_SUBJECTLIST=$(echo $CLISUBJECTS | wc -w)
if (( b_SUBJECTLIST )) ; then
	SUBJECTS="$CLISUBJECTS"
fi

SUBJECTS=$(echo $SUBJECTS | tr ' ' '\n' )

statusPrint	"Checking <subjectList> in SUBJECTS_DIR" "\n"
for SUBJ in $SUBJECTS ; do
	statusPrint	"$SUBJ..." "\n"
	statusPrint	"Found in SUBJECTS_DIR"
	dirExist_check ${SUBJECTS_DIR}/$SUBJ* || fatal noSubjectBase
done

statusPrint	"Checking <subjectList> dirs" "\n"
cd $EXPDIR
for SUBJ in $SUBJECTS ; do
	statusPrint	"$SUBJ..."
	dirExist_check $SUBJ || mkdir $SUBJ
done

cd $EXPDIR
DATE=$(date)

l_PRINCIPAL=$(echo $TEXTURELIST| tr ',' ' ')
l_CUTOFF=$(echo $GAUSSIANLIST | tr ',' ' ')
l_HEMI=$(echo $HEMILIST | tr ',' ' ')
l_INTEGRALTYPE=$(echo $INTEGRALTYPELIST | tr ',' ' ')
l_INTEGRALDOMAIN=$(echo $INTEGRALDOMAINLIST | tr ',' ' ')
let rowCount=1
let colCount=1
FIELD="20"
for HEMI in $l_HEMI ; do
  for PRINCIPAL in $l_PRINCIPAL ; do
    for INTEGRALDOMAIN in $l_INTEGRALDOMAIN ; do
      for INTEGRALTYPE in $l_INTEGRALTYPE ; do
        OUT=$HEMI-$PRINCIPAL-$INTEGRALDOMAIN-$INTEGRALTYPE-$FILTER-${LOWPASSFILTER}.tab$TABLEFILESUFFIX
        OUTVAL=$HEMI-$PRINCIPAL-$INTEGRALDOMAIN-$INTEGRALTYPE-$FILTER-${LOWPASSFILTER}.tab$TABLEFILESUFFIX-val
        OUTPERC=$HEMI-$PRINCIPAL-$INTEGRALDOMAIN-$INTEGRALTYPE-$FILTER-${LOWPASSFILTER}.tab$TABLEFILESUFFIX-perc
        printf "\nGenerating $OUT table\n"
        printf "%-25s" "SUBJECT"                        | tee --append $OUT $OUTVAL $OUTPERC
        for COL in $l_CUTOFF ; do
	  printf "%-${FIELD}s" "$COL"			| tee --append $OUT $OUTVAL $OUTPERC
        done
        printf "\n"                                     | tee --append $OUT $OUTVAL $OUTPERC
        for ROW in $SUBJECTS ; do
	  printf "%-25s" "$ROW"				| tee --append $OUT $OUTVAL $OUTPERC
          # The scaleFactor is a historical artifact, and allows a post-scale of
          # mris_curvature_stats values. For now, the scaleFactor is essentially
          # meaningless and set to 1.0.
          scaleFactor=1
	  if [[ "$PRINCIPAL" == "K" || "$PRINCIPAL" == "BE" || "$PRINCIPAL" == "S" ]] ; then
	    scaleFactor=$(echo -e "scale=5\n$scaleFactor * $scaleFactor\nquit" | bc)
	  fi
          FILTERLABEL=""
          if (( Gb_labelsSave )) ; then
            FILTERLABEL="filterLabel ROI-$HEMI-$ROW-${COL}-${LOWPASSFILTER}.label"
          fi
          LABELARG=""
          if (( Gb_labelRegion )) ; then
            LABELARG="-l ${HEMI}.${LABELREGION}"
          fi
          if (( Gb_regionalPercentages )) ; then
            REGIONALPERC="--regionalPercentages"
          fi
	  for COL in $l_CUTOFF ; do
	    CMD="$MRISCURVATURESTATS --$FILTER $COL 		  	          \
			--lowPassFilterGaussian ${LOWPASSFILTER}	          \
                        $FILTERLABEL                                              \
			$CONTINUOUSFORM					          \
			--postScale $scaleFactor			          \
                        $LABELARG $REGIONALPERC                                   \
			-G -F smoothwm $ROW $HEMI 2>/dev/null                    |\
			grep \"$PRINCIPAL \" 				 	 |\
			grep -i $INTEGRALTYPE 				         |\
			grep -i $INTEGRALDOMAIN                                  |\
			awk '{print \$6 \" \" \$9}' 2>/dev/null"
	    stage_stamp "$PRINCIPAL-$ROW-$COL RUN $(echo $CMD | tr '\n' ' ')" $STAMPLOG
	    valperc=$(eval $CMD)
            val=$(echo $valperc | awk '{print $1}')
            perc=$(echo $valperc | awk '{print $2}' | sed -e 's/[^0-9]//' -e 's/\(.*\)%)/\1/')
	    printf "%-${FIELD}s" "$valperc"		| tee --append $OUT
            printf "%-${FIELD}s" "$val"                 >> $OUTVAL
            printf "%-${FIELD}s" "$perc"                >> $OUTPERC

	    stage_stamp "${PRINCIPAL}-${ROW}-${COL}" $STAMPLOG
	  done
	  printf "\n"				| tee --append $OUT $OUTVAL $OUTPERC
        done
      done
    done
  done
done

shut_down 0

