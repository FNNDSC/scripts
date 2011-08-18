# NAME
#	
#	common.bash
#
# DESCRIPTION
#
#	'common.bash' is a set of common script functions that can be
#	used by other stand-alone scripts. Typically, these are made
#	available by:
#
#		source common.bash
#
#	in the host script.
#
# DEPENDENCIES
#
#	This file should typically be sourced in the "main" section of
#	the host script.
#
#	Note that there are several dependencies imposed by sourcing
#	these common functions on the host script.
#
#		Gi_verbose:		Verbosity level tracker
#		Gb_forceStage:		Execution stage override flag
#               STAMPLLOG:              Specified in main program, defines
#                                       stamp log file
#               G_LOGDIR                Directory containing output logs and
#                                       expert opts files.
#
#	These should be handled by the getopts loop of the host script.
#

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///
G_SELF=`basename $0`
G_PID=$$

G_COMMON_MIGRATEANALYSISDIR="-x"
G_COMMON_MIGRATEORIGDIR="-x"


# Column formatting
declare -i	G_LC=40
declare -i	G_RC=40

# Output behaviour
declare -i 	Gi_verbose=0

# Stage handling
declare	-i	Gb_forceStage=0

#
# Error handling is performed by using a "poor man's" dictionary type hack of
# the following form:
#
#	A_$stem="Action Performed"
#	EM_$stem="Error condition/message"
#	EC_$stem="Code"
#
# where $stem denotes the name of the particular error. Errors are called
# using "fatal $stem"
#

A_eg="Action performed"
EM_eg="Error condition flagged"
EC_eg="-100"

A_metaLog="checking the meta log file"
EM_metaLog="it seems as though this stage has already run.\n\tYou can force execution with a '-f'"
EC_metaLog=80

###\\\
# Function definitions
###///

function expertOpts_file
{
    # ARGS
    # $1                        process name
    #
    # DESC
    # For the passed <process name>, return the associated
    # expertOpts file.
    #

    local processName=$1
    local optsFile=""

    optsFile=${G_LOGDIR}/${processName}.opt
    echo "$optsFile"
}

function expertOpts_parse
{
    # ARGS
    # $1                        process name
    #
    # DESC
    # Checks for <processName> in $G_LOGDIR.
    # If exists, read contents and return, else
    # return empty string.
    #

    local processName=$1
    local optsFile=""
    OPTS=""

    optsFile=$(expertOpts_file $processName)
    if (( $Gb_useExpertOptions ))  ; then
        if [[ -f  $optsFile ]] ; then
            OPTS=$(cat $optsFile)
        fi
    fi
    OPTS=$(printf " %s " $OPTS)
    echo "$OPTS"
}

function expertOpts_rm
{
    # ARGS
    # $1                        process name
    #
    # DESC
    # Removes the expertOpts file
    #

    local processName=$1
    local optsFile=""

    optsFile=$(expertOpts_file $processName)
#     optsFile=${G_LOGDIR}/${processName}.opt
    if (( $Gb_useExpertOptions )) ; then
        if [[ -f  $optsFile ]] ; then
            rm -f $optsFile
        fi
    fi
}

function expertOpts_write
{
    # ARGS
    # $1                        process name
    # $2                        option string
    #
    # DESC
    # Appends $2 to <processName>.opt in $G_LOGDIR.
    #

    local processName=$1
    local optsFile=""
    OPTS=$2

    optsFile=$(expertOpts_file $processName)
    if (( $Gb_useExpertOptions )) ; then
      echo "$OPTS" >> $optsFile
    fi
    OPTS=$(printf " %s " $OPTS)
    echo "$OPTS"
}

function trim
{
    echo $1;
}

function string_clean
{
    # ARGS
    # $1                        target string
    #
    # DESC
    # Removes useless junk characters from <target string>.
    #

    local targetString=$1

    echo "$targetString" | sed 's/[]|&+=<{([)}> ]*//g'
}

function verbosity_check
{
	#
	# DESC
	# If verbosity level is non-zero, set output to stdout, else
	# set to /dev/null
	#

	exec 6>&1 
	if (( Gi_verbose )) 
	then
		exec >&1
	else
		exec > "/dev/null"
	fi
}

function shut_down
# $1: Exit code
{
    # If the migrate analysis was turned on, then at the end we want
    # to move the results from the analysis directory to their final
    # resting place
    if [[ "$G_COMMON_MIGRATEANALYSISDIR" != "-x" ]] ; then
        
        # First remove the symbolic link between original directory
        # and analysis directory
        cd $(dirname $G_COMMON_MIGRATEORIGDIR)
        rm $(basename $G_COMMON_MIGRATEORIGDIR)
        
        # Move the results from the temporary analysis directory
        # into their final resting place
        mv $G_COMMON_MIGRATEANALYSISDIR .
        
    fi
    
    echo -e "\n$G_SELF:\n\tShutting down with code $1 at $(date).\n"
    exit $1
}

function synopsis_show
{
	echo "USAGE:"
	echo "$G_SYNOPSIS"
}
                   
function error
# $1: Action
# $2: Error string
# $3: Exit code
{
	echo -e "\n$G_SELF:\n\tSorry, but there seems to be an error." >&2
	echo -e "\tWhile $1,"                                      >&2
	echo -e "\t$2\n"                                           >&2
	shut_down $3
}                

function fatal
# $1: variable name - used to construct action/error string/exit code
{
	local stem=$1
	eval action=\$A_$stem
	eval errorString=\$EM_$stem
	eval exitCode=\$EC_$stem
 	error "$action" "$errorString" "$exitCode"
}

function warn
# $1: Action
# $2: Warn string
# $3: Default value
{
	echo -e "\n$G_SELF: WARNING\n" 			>&2
	echo -e "\tWhile $1,"                           >&2
	echo -e "\t$2\n"                                >&2
	echo -e "\tWarning code: '$3'\n"		>&2
}                

function beware
# $1: variable name - used to construct action/error string/exit code
{
	local stem=$1
	eval action=\$A_$stem
	eval errorString=\$EM_$stem
	eval exitCode=\$EC_$stem
	warn "$action" "$errorString" "$exitCode"
}

function NOP
{
    	#
    	# DESC
    	#	Do nothing!
    
    return 0
}

function NOP_ret
{
   	#
	# ARGS
	# $1		in/out		a variable that is directly
	#					returned
	#
	# DESC
	# Does nothing other than "reflect" a passed variable back to
	# the caller.
	#

	return $1

}

function ret_check
{
	# ARGS
	# $1 		in		return value to check
	# $2		in (opt)	failure text
	# $3		in (opt)	success text
	# DESC
	# Checks for the passed return value, and echoes a
	# conditional to stdout. Returns this value back to
	# the main program.
	#
	
	local ret=$1
	FAIL="failure"
	PASS="ok"
	if (( ${#2} )) ; then
		FAIL=$2
	fi
	if (( ${#3} )) ; then
		PASS=$3
	fi

	if [[ $ret != "0" ]] ; then
		if (( Gi_verbose )) ; then 
		    printf "%*s\n" 	$G_RC	"[ $FAIL ]"
		fi
	else
		if (( Gi_verbose )) ; then
		    printf "%*s\n" 	$G_RC	"[ $PASS ]"
		fi
	fi
	return $ret
}

function fileExist_check
{
	#
	# ARGS
	# $1 		in		file to check
	# $2		in (opt)	failure text
	# $3		in (opt)	success text
	#
	# DESC
	# Checks for the existence of a file, and echoes a
	# conditional to stdout. Returns this value back to
	# the main program:
	#	0: no error (file does exist)
	#	1: some error (file does not exist)
	#
	
	local file=$1
	FAIL="failure"
	PASS="ok"
	if (( ${#2} )) ; then
		FAIL=$2
	fi
	if (( ${#3} )) ; then
		PASS=$3
	fi
	
	if [[ ! -f $file ]] ; then
		if (( Gi_verbose )) ; then 
		    printf "%*s\n" 	$G_RC	"[ $FAIL ]"
		fi
		return 1
	else
		if (( Gi_verbose )) ; then
		    printf "%*s\n" 	$G_RC	"[ $PASS ]"
		fi
		return 0
	fi
}

function file_checkOnPath
{
        # ARGS
        # $1            in              file to check
        #
        # DESC
        # Checks for the existence of a file. If not found,
        # return 1, else return 0.
        #

        local file=$1

        type -all $file 2>/dev/null >/dev/null
        notFound=$?

        if (( notFound ))  ; then
		printf "%*s\n" 	$G_RC	"[ failure ]"
                return 1
        else
		printf "%*s\n" 	$G_RC	"[ ok ]"
        fi
        return 0
}

function dirExist_check 
{
	#
	# ARGS
	# $1 		in		dir to check
	# $2		in (opt)	failure text
	# $3		in (opt)	success text
	#
	# DESC
	# Checks for the existence of a dir, and echoes a
	# conditional to stdout. Returns this value back to
	# the main program:
	#	0: no error (file does exist)
	#	1: some error (file does not exist)
	#
	
	local dir=$1
	FAIL="failure"
	PASS="ok"
	if (( ${#2} )) ; then
		FAIL=$2
	fi
	if (( ${#3} )) ; then
		PASS=$3
	fi
	if [[ ! -d $dir ]] ; then
		printf "%*s\n" 	$G_RC	"[ $FAIL ]"
		return 1
	else
		printf "%*s\n" 	$G_RC	"[ $PASS ]"
		return 0
	fi
}

function cprint
{
	#
	# ARGS
	# $1		in		left column text
	# $2		in		right column text
	#
	# DESC
	# Prints two input text strings in two columns: left and
	# right respectively.
	#
	local left=$1
	local right=$2

	if (( ! Gi_verbose )) ; then return 1 ; fi
	printf "%*s"	$G_LC 	"$left"
	printf "%*s\n"	$G_RC	"$right"
}

function lprint
{
	#
	# ARGS
	# $1		in		left column text
	#
	# DESC
	# Prints left column text string.
	#
	local left=$1

	if (( ! Gi_verbose )) ; then return 1 ; fi
	printf "%*s"	$G_LC 	"$left"
}

function lprintn
{
        #
        # ARGS
        # $1            in              left column text
        #
        # DESC
        # Prints left column text string, followed by \n
        #
        local left=$1

        printf "%*s\n"    $G_LC   "$left"
}

function rprint
{
	#
	# ARGS
	# $1		in		right column text
	#
	# DESC
	# Prints right column text string, followed by \n
	#
	local right=$1

	if (( ! Gi_verbose )) ; then return 1 ; fi
	printf "%*s\n"	$G_RC	"$right"
}

function statusPrint
{
        # ARGS
        # $1            in              message to print
        # $2            in              possible trailing character or string
        #
        # DESC
        # Prints a status message on the left of the console.
        #

        local status=$1
        local ctrlN=$2

	if (( ! Gi_verbose )) ; then return 1 ; fi
        printf "%*s$ctrlN" $G_LC "$status"
}

function stage_alreadyRun
{
        local stage="$1"
        local logFile="$2"

        echo $(cat "$logFile" | awk -F \| '{print $3'} | grep "$stage" | wc -l)
}

function stage_check
{
        local stage="$1"
        local logFile="$2"

        if [[ -f "$logFile" ]] ; then
                if (( !Gb_forceStage && $(stage_alreadyRun "$stage" "$logFile") )) ; then
                        fatal metaLog
                fi
        fi
}

function sysprint
{
    local message="$1"
    echo -e "$(date) $(hostname) $message"
}

function stage_stamp
{
        local stage=$1
        local logFile=$2
        local clusterUser="$3"

	if (( !${#logFile} )) ; then
	    logFile="stdout"
	fi
        echo -e "$(date) $(hostname) $clusterUser | $G_SELF | Stage $stage | ok" >> $logFile
	if [[ $logFile == "stdout" ]] ; then
	   cat $logFile
	   rm $logFile
	fi
}

function stage_run
{
       #
       # ARGS
       # $1                     name of stage
       # $2                     command line to execute
       # $3                     file to log stdout
       # $4                     file to log stderr
       # $5                     turn OFF tee
       # 
       # DESCRIPTION
       # Run the stage command. If $3 and $4 exist, capture output
       # of stdout and stderr respectively.
       # 
       # If a 5th argument is passed, turn OFF the tee.
       # 
       # If G_mailLogTo exists, mail stdout and stderr.
       # 

       local stageName=$1
       local stageCMD=$2
       local stdout=$3
       local stderr=$4
       local noTEE=$5
       local b_TEE=1

       STDOUTFILE=/dev/null
       STDERRFILE=/dev/null
       
       if (( ${#3} )) ; then STDOUTFILE=$3      ; fi 
       if (( ${#4} )) ; then STDERRFILE=$4      ; fi 
       if (( ${#5} )) ; then b_TEE=0            ; fi 
       stage_check "$stageName" $STAMPLOG
       statusPrint "Running $stageName..."
       stage_stamp "RUN  $(echo $stageCMD | tr '\n' ' ')" $STAMPLOG
       if (( b_TEE )) ; then
            ((( eval $stageCMD | tee $STDOUTFILE) 3>&1 1>&2 2>&3      |\
                tee $STDERRFILE) 3>&1 1>&2 2>&3)
        else
            eval $stageCMD >$STDOUTFILE 2>$STDERRFILE
       fi
       ret=$?
       ret_check $ret
       if (( !$ret )) ; then stage_stamp "$stageName" $STAMPLOG ; fi
       return $ret
}

function stage_run_bg
{
       #
       # ARGS
       # $1                     name of stage
       # $2                     command line to execute
       # $3                     file to log stdout
       # $4                     file to log stderr
       # $5                     turn OFF tee
       #
       # DESCRIPTION
       # Run the stage command in the background. If $3 and $4 exist, 
       # capture output of stdout and stderr respectively.
       #
       # If a 5th argument is passed, turn OFF the tee.
       #
       # If G_mailLogTo exists, mail stdout and stderr.
       #

       local stageName=$1
       local stageCMD=$2
       local stdout=$3
       local stderr=$4
       local noTEE=$5
       local b_TEE=1

       STDOUTFILE=/dev/null
       STDERRFILE=/dev/null

       if (( ${#3} )) ; then STDOUTFILE=$3      ; fi
       if (( ${#4} )) ; then STDERRFILE=$4      ; fi
       if (( ${#5} )) ; then b_TEE=0            ; fi
       stage_check "$stageName" $STAMPLOG
       statusPrint "Running $stageName..."
       stage_stamp "RUN  $(echo $stageCMD | tr '\n' ' ')" $STAMPLOG
       if (( b_TEE )) ; then
            ((( eval $stageCMD | tee $STDOUTFILE) 3>&1 1>&2 2>&3      |\
                tee $STDERRFILE) 3>&1 1>&2 2>&3) &
        else
            eval $stageCMD >$STDOUTFILE 2>$STDERRFILE &
       fi
       ret=$?
       ret_check $ret
       if (( !$ret )) ; then stage_stamp "$stageName" $STAMPLOG ; fi
       return $ret
}

function process_kill
{
	#
	# ARGS
	# $1		in		process name
	#

	HOST=$(uname -a | awk '{print $1}')

	if [[ "$HOST" == "Darwin" ]]  ; then
        	ps -aux | grep $1 | grep -v grep | awk '{print "kill -9 " $2}' | sh 2>/dev/null >/dev/null
	else
        	ps -Af  | grep $1 | grep -v grep | awk '{print "kill -9 " $2}' | sh 2>/dev/null >/dev/null
	fi
 	return 0
}

function mail_reports
{
    # ARGS
    #  $1 - Mailto address(es)
    #  $2 - Whether to mail stdout ("1" = true, "0" = false)
    #  $3 - Whether to mail stderr ("1" = true, "0" = false)
    #
    # DESC
    # Email reports to specified user(s).
    #
    local mailTo=$1
    local mailStdOut=$2
    local mailStdErr=$3

    if (( "$mailStdOut" == "1" )) ; then
        if [[ -f ${G_LOGDIR}/${G_SELF}.std ]] ; then
            cp ${G_LOGDIR}/${G_SELF}.std ${G_LOGDIR}/${G_SELF}.std.mail
            mail -s "stdout: ${G_SELF}" $mailTo < ${G_LOGDIR}/${G_SELF}.std.mail
        fi
    fi
    
    if (( "$mailStdErr" == "1" )) ; then
        if [[ -f ${G_LOGDIR}/${G_SELF}.err ]] ; then
            cp ${G_LOGDIR}/${G_SELF}.err ${G_LOGDIR}/${G_SELF}.err.mail
            mail -s "stderr: ${G_SELF}" $mailTo < ${G_LOGDIR}/${G_SELF}.err.mail
        fi
    fi
}

function cluster_schedule
{
    # ARGS
    # $1                        original script command line args
    # $2                        name of pipeline (e.g., tract, fs, dcmanon, etc.)
    #
    # DEPENDENCIES 
    # G_CLUSTERDIR              cluster directory where schedule log is found
    # G_SCHEDULELOG             schedule log file name (e.g., schedule.log)
    # G_CLUSTERUSER             name of user submitting to cluster
    # G_LOGDIR                  log directory path
    #
    # DESC
    # Creates a custom script in the G_LOGDIR that is essentially
    # the original command line. Once scheduled, termination of this
    # script ceases, and it is "re-spawned" on the cluster.
    # 
    local cmdArgs=$1
    local pipelineName=$2

    # Setup the command line args (stripping the -c)
    COMARGS=$(echo $cmdArgs | sed 's|-c||')
    # Create mini-script to run on cluster and add to schedule.log
    STAGE="0-cluster_schedule"
    STAGECMD="$G_SELF $COMARGS -f                    >\
                ${G_LOGDIR}/${G_SELF}.std           2>\
                ${G_LOGDIR}/${G_SELF}.err"
    STAGECMD=$(echo $STAGECMD | sed 's|/local_mount||g')
    CLUSTERSH=${G_LOGDIR}/$pipelineName-cluster.sh
    echo "#!/bin/bash"                                      > $CLUSTERSH
    echo "export PATH=$PATH"                                >> $CLUSTERSH   
    echo "source $FREESURFER_HOME/SetUpFreeSurfer.sh"       >> $CLUSTERSH
    echo "source $FSL_DIR/etc/fslconf/fsl.sh"               >> $CLUSTERSH
    echo "export SUBJECTS_DIR=$SUBJECTS_DIR"                >> $CLUSTERSH
    echo "export DSI_PATH=$(echo $PATH | tr ":" "\n" | grep dtk)/matrices" >> $CLUSTERSH
    echo "export PYTHONPATH=$PYTHONPATH"                    >> $CLUSTERSH
    echo "$STAGECMD"                                        >> $CLUSTERSH
    chmod 755 $CLUSTERSH
    STAGECMD="${G_LOGDIR}/$pipelineName-cluster.sh"
    STAGECMD=$(echo $STAGECMD | sed 's|/local_mount||g')
    stage_stamp "$STAGECMD" ${G_CLUSTERDIR}/$G_SCHEDULELOG "$G_CLUSTERUSER"
    stage_stamp "$STAGE Schedule for cluster" $STAMPLOG
    stage_stamp "$STAGE" $STAMPLOG
    
    # Also append to output of XML file used by web front end
    LINENUMBER=$(wc -l "${G_CLUSTERDIR}/$G_SCHEDULELOG" | awk '{print $1}')
    GENHEADER=""
    if [[ ! -f "${G_CLUSTERDIR}/$G_SCHEDULELOG.xml" ]] ; then
        GENHEADER="-h"
    fi
    GENXMLCMD="cluster_genXML.bash -f ${G_CLUSTERDIR}/$G_SCHEDULELOG -l ${LINENUMBER} ${GENHEADER}"
    eval $GENXMLCMD >> "${G_CLUSTERDIR}/$G_SCHEDULELOG.xml"
}

function wait_for_lockfile
{
    # ARGS
    # $1                        lock file name
    # $2                        timeout in seconds
    #
    # DEPENDENCIES 
    #
    # DESC
    # Wait for a lockfile to be available for use.  This
    # essentially provides process/thread level protection on
    # operations that should not occur synchronously
    # 

    local lockFile=$1
    TIMEOUT_SEC=3600
    if (( ${#2} )) ; then TIMEOUT_SEC=$2      ; fi
    
    # Make sure the file gets deleted if the process
    # exits before deleting the file.
    trap "rm -f $lockFile" 0 1 2 9 15
    
    lockfile -1 -r ${TIMEOUT_SEC} $lockFile   
}

function release_lockfile
{
    # ARGS
    # $1                        lock file name
    #
    # DEPENDENCIES 
    # 
    #
    # DESC
    # Deletes a lockfile if it exists.
    # 
    local lockFileName=$1
    rm -f $lockFileName
}

function migrateAnalysis_enable
{
    # ARGS
    # $1                        Directory to use for migrated analysis
    # $2                        Final directory to store results in
    # DEPENDENCIES 
    # 
    #
    # DESC
    # This function is used for having an alternate directory to use
    # for processing the data.  It is useful for example where the data
    # needs to be moved to a cluster storage space for processing and
    # then moved back afterwards.
    #
    G_COMMON_MIGRATEANALYSISDIR=$1
    G_COMMON_MIGRATEORIGDIR=$2
    
    # Create a symbolic link between the original directory and the
    # analysis directory that will be used
    origDir=$(pwd)
    cd $(dirname $G_COMMON_MIGRATEORIGDIR)
    ln -s $G_COMMON_MIGRATEANALYSISDIR $(basename $G_COMMON_MIGRATEORIGDIR)
    cd $origDir
}

function pipelineStatus_create
{
    # ARGS
    # $1                    Pipeline name
    # $2                    Remaining arguments should be a string
    #                       with the names of the stages to add.
    #                       Each stage will be numberered starting at 1.
    #
    # DESC
    #
    # Create pipeline status with specified stages    
    local pipelineName=$1
    local stages=$2
    
    # Create the pipeline
    pipeline_status_cmd.py --createPipeline $pipelineName ${G_LOGDIR}/${G_SELF}.status
    
    # Add the stages
    for STAGE in $stages ; do            
            pipeline_status_cmd.py --addStage $STAGE ${G_LOGDIR}/${G_SELF}.status                            
    done        
}

function pipelineStatus_addInput
{
    # ARGS
    # $1                    Stage name
    # $2                    Root directory
    # $3                    File path
    # $4                    Name [optional, default: File path]
    # $5                    Type [optional, default: None]
    #
    # DESC
    #
    # Add input to given stage
    
    NAME=""
    TYPETAG=""
    if (( ${#4} )) ; then 
        NAME="--name $4"      
    fi
    if (( ${#5} )) ; then
        TYPETAG="--typeTag $5"
    fi        
    
    (pipeline_status_cmd.py --addInput $1 --rootDir $2 \
                            --filePath $3 ${NAME} ${TYPETAG} ${G_LOGDIR}/${G_SELF}.status)
    return $?                                 
}

function pipelineStatus_addOutput
{
    # ARGS
    # $1                    Stage name
    # $2                    Root directory
    # $3                    File path
    # $4                    Name [optional, default: File path]
    # $5                    Type [optional, default: None]    
    #
    # DESC
    #
    # Add output to given stage
    
    NAME=""
    TYPETAG=""
    if (( ${#4} )) ; then 
        NAME="--name $4"      
    fi
    if (( ${#5} )) ; then
        TYPETAG="--typeTag $5"
    fi        
    
    (pipeline_status_cmd.py --addOutput $1 --rootDir $2 \
                            --filePath $3 ${NAME} ${TYPETAG} ${G_LOGDIR}/${G_SELF}.status)
    return $?                                 
}

function pipelineStatus_canRun
{
    # ARGS
    # $1                    Stage name
    #
    # DESC
    # Check whether a pipeline can run (e.g., whether its 
    # dependencies have been satisfied)
    FAIL="failure"
	PASS="ok"
	
	pipeline_status_cmd.py --queryCanRun $1 ${G_LOGDIR}/${G_SELF}.status
	ret=$?
    
    if (( Gi_verbose )) ; then
        printf "Checking on stage $1 inputs"
        if (( $ret )) ; then
            printf "%*s\n" 	$G_RC	"[ $FAIL ]"
        else
            printf "%*s\n" 	$G_RC	"[ $PASS ]"
        fi
	fi
    return $ret
}



#
# Typical getops loop:
#
# while getopts v:f option ; do 
# 	case "$option"
# 	in
# 		v) Gi_verbose=$OPTARG			;;
# 		f) Gb_forceStage=1			;;		
# 		\?) synopsis_show 
# 		    exit 0;;
# 	esac
# done

#
# Remember to stamp output log with current command line history:
#
# verbosity_check
# topDir=$(pwd)
# STAMPLOG=${topDir}/${G_SELF}.log
# stage_stamp "Init | ($topDir) $G_SELF $*" $STAMPLOG

#
# Options pruning:
#
# shift $(($OPTIND - 1))
# ARGS=$*

