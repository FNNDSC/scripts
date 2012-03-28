#
# NAME
#
#	.bashrc
#
# DESC
#
#	`.bashrc' sets the basic environment for bash shells.
#
#	This specific file sets the prompt, path, and terminal title.
#	Alias and functions are defined separately in the login-specific
#	file, .bash_profile
#
# HISTORY
# 20 June 2000
#  o Initial design and coding
#
# 21 June 2000
#  o Building of separate "informational" functions
#
# 06 January 2000
#  o Merging of old tcsh .cshrc and .login files
#
# 08 January 2000
#  o Need to separate monolithic file into .bashrc and .bash_profile - this
#    is largely for ssh purposes: the splash screen that the monolithic
#    file created confuses ssh.
#
# 25 Septmeber 2002
#  o Removed JAVA_HOME export - seemed to confuse openoffice
#
# 19 February 2003
#  o Began updates for MGH-environment
#
# 04 March 2004
#  o Misc updates and fixing... df usage seems to cause problems on some
#    machines, causing logins to hang
#       - When shell logs in, the prompt is "statsBasic".
#       - From the command line, call "statsPartition" for partition information
#         (based on 'df' and 'du') in the xterm titlebar; or call "statsFull"
#         for partition information *and* load *and* file information in the
#         console prompt itself.
#
# 22 July 2004
#  o Added some NMR aliases
#
##

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

if [[ -f /usr/bin/uname ]] ; then
	arch=$(/usr/bin/uname)
fi

if [[ -f /bin/uname ]] ; then
	arch=$(/bin/uname)
fi

#\\\
# KDE configuration
#///
#export KDEDIR=/usr/kde/3.4

# The following is designed to support custom-built KDE installations
#       that live (typically) somewhere off the $HOME tree. Most of these
#       are legacy leftovers that are kept as placeholders if necessary.
case $HOSTNAME in
	kaos | heisenberg )
		export KDEDIR=/usr
	;;
	nebula | pulsar | bigbird | mongo )
		export KDEDIR="${HOME}"/arch/${arch}/kde3
	;;

	denali )
		export KDEDIR="${HOME}"/arch/${arch}/kde3
	;;

	cambrian.cortechs.net )
		export KDEDIRS=/opt/kde-3.1
		export QTDIR=/opt/qt-3.1.1
		export KDEHOME=~/.kde-3.1
	;;
	reward)
		export KDEHOME=~/.kde-3.2
	;;
	
	triassic )
		 export KDEDIR=/usr/kde/3.3
		 export KDEDIRS=/usr/kde/3.3
	;;
esac

# Define some colours for prompt usage
       BLACK="\[\033[0;30m\]"
         RED="\[\033[0;31m\]"
       GREEN="\[\033[0;32m\]"
       BROWN="\[\033[0;33m\]"
        BLUE="\[\033[0;34m\]"
      PURPLE="\[\033[0;35m\]"
        CYAN="\[\033[0;36m\]"
  LIGHT_GRAY="\[\033[0;37m\]"

   DARK_GRAY="\[\033[1;30m\]"
   LIGHT_RED="\[\033[1;31m\]"
 LIGHT_GREEN="\[\033[1;32m\]"
      YELLOW="\[\033[1;33m\]"
  LIGHT_BLUE="\[\033[1;34m\]"
LIGHT_PURPLE="\[\033[1;35m\]"
  LIGHT_CYAN="\[\033[1;36m\]"
       WHITE="\[\033[1;37m\]"

 WHITE_BCKGRND="\[\033[47m\]"
  CYAN_BCKGRND="\[\033[46m\]"
PURPLE_BCKGRND="\[\033[45m\]"
  BLUE_BCKGRND="\[\033[44m\]"
 BROWN_BCKGRND="\[\033[43m\]"
 GREEN_BCKGRND="\[\033[42m\]"
   RED_BCKGRND="\[\033[41m\]"
 BLACK_BCKGRND="\[\033[40m\]"

    NO_COLOUR="\[\033[0m\]"
    

#\\\
# Define some miscellaneous functions
#///

function prompt_command
{
        #
	# DESC
	#       Define a series of commands that are executed each time a new prompt is
	#       generated. Here, the prompt is constructed from the last 15 characters
        #       of the current absolute path
	#

        if [ "$PWD" = "$HOME" ] ; then
                PWD="~"
        fi

	# Shorten the pwd
	pwd_length=15
	if [ $(echo -n $PWD | wc -c | tr -d " ") -gt $pwd_length ]
	then
   		newPWD="${PROMPTPREFIX}...$(echo -n $PWD | sed -e "s/.*\(.\{$pwd_length\}\)/\1/")"
	else
   		newPWD="${PROMPTPREFIX}$(echo -n $PWD)"
	fi
}

# Set the PROMPT_COMMAND macro
PROMPT_COMMAND=prompt_command

function statsBasic {
	#
	# DESC
	#       This function generates a statistics strip at the top of the
	#       terminal - in the xterm window title.
	#
        # HISTORY
        # 03 March 2004
        #  o Split prompt into different functions depending on desired complexity.
        #

	PS1="${TITLEBARBASIC}${GREEN}\${newPWD}\\$>${NO_COLOUR}"
	PS2='> '
	PS4='+ '
}

function TTstatsBasic {
	#
	# DESC
	#       This function generates a statistics strip at the top of the
	#       terminal - in the console display
	#
        # HISTORY
        # 03 March 2004
        #  o Split prompt into different functions depending on desired complexity.
        #

	PS1="${LIGHT_BLUE}${TTBASIC}${LIGHT_GREEN}\${newPWD}\\$>${WHITE}"
	PS2='> '
	PS4='+ '
}

function statsPartition {
	#
	# DESC
	#       This function generates a statistics strip at the top of the
	#       terminal
	#
        # HISTORY
        # 03 March 2004
        #  o Split prompt into different functions depending on desired complexity.
        #

	PS1="${TITLEBARPARTITION}${LIGHT_GREEN}\${newPWD}\\$>${WHITE}"
	PS2='> '
	PS4='+ '
}

function TTstatsPartition {
	#
	# DESC
	#       This function generates a statistics strip at the top of the
	#       terminal
	#
        # HISTORY
        # 03 March 2004
        #  o Split prompt into different functions depending on desired complexity.
        #

	PS1="${LIGHT_BLUE}${TTPARTITION}${LIGHT_GREEN}\${newPWD}\\$>${WHITE}"
	PS2='> '
	PS4='+ '
}

function statsFull {
	#
	# DESC
	#       This function generates a statistics strip at the top of the
	#       terminal
	#
        # HISTORY
        # 03 March 2004
        #  o Split prompt into different functions depending on desired complexity.
        #

        PS1="${TITLEBARBASIC}\n${BLUE_BCKGRND}$WHITE\033[K$(uname -sr) [${HOST_COLOUR}$(currentLoadInfo_determine)${WHITE}][${FILESTATS}][${PARTITIONSTATS}]${NO_COLOUR}\n${LIGHT_GREEN}\${newPWD}>${WHITE}"
	PS2='> '
	PS4='+ '
}

function TTstatsFull {
	#
	# DESC
	#       This function generates a statistics strip at the top of the
	#       terminal
	#
        # HISTORY
        # 03 March 2004
        #  o Split prompt into different functions depending on desired complexity.
        #

        PS1="${LIGHT_BLUE}${TTFULL}${LIGHT_GREEN}\${newPWD}>${WHITE}"
	PS2='> '
	PS4='+ '
}

function currentPartitionUse_determine
{
        #
        # DESC
        #       Determines the density of the current partition as
        #       a current/total string, i.e. 598M/9.6G
        #
        # HISTORY
        # 06 January 2001
        #  o Initial design and coding
        #
        # 03 March 2004
        #  o The use of 'df' here might be problematic in some cases
        #

        partitionUse=$(df -kh . | grep -v system)
        echo $partitionUse | awk '{print $3 "B/" $2 "B"}'
}

function currentDirSize_determine
{
	#
	# DESC
	#       Determines the size of the current directory
	#
        # HISTORY
        # 03 March 2004
        #  o Processing dir size might cause delays in some architectures.
        #

	let totalBytes=0
        let totalSize=0

	for bytes in $(/bin/ls -l | grep "^-" | sed -e "s/ \+/ /g" | awk '{print $5}')
	do
   		let totalBytes=$totalBytes+$bytes
	done

	# The if...fi's give a more specific output in byte, kilobyte, megabyte,
	# and gigabyte

	if [ $totalBytes -lt 1024 ]; then
   		totalSize=$(echo -e "scale=3 \n$totalBytes \nquit" | bc)B
		else if [ $totalBytes -lt 1048576 ]; then
   			totalSize=$(echo -e "scale=3 \n$totalBytes/1024 \nquit" | bc)kB
			else if [ $totalBytes -lt 1073741824 ]; then
   				totalSize=$(echo -e "scale=3 \n$totalBytes/1048576 \nquit" | bc)MB
				else
   					totalSize=$(echo -e "scale=3 \n$totalBytes/1073741824 \nquit" | bc)GB
			fi
		fi
	fi
	echo $totalSize
}

function currentDirFileStats_determine
{
	#
	# DESC
	#       Determine some stats of files in current directory.
	#       More specifically, count the number of file and directories
	#       (hidden and visible), executables, and special block devices
	#

	let files=$(ls -l                 | grep "^-"  | wc -l | tr -d " ")
	let hiddenfiles=$(ls -ld .*       | grep "^-"  | wc -l | tr -d " ")
	let executables=$(ls -l           | grep ^-..x | wc -l | tr -d " ")
	let directories=$(ls -l           | grep "^d"  | wc -l | tr -d " ")
	let hiddendirectories=$(ls -ld .* | grep "^d"  | wc -l | tr -d " ")-2


	let linktemp=$(ls -l              | grep "^l"  | wc -l | tr -d " ")
	if [ "$linktemp" -eq "0" ]; then
    	links=""
	else
    	links=" ${linktemp}"
	fi
	unset linktemp

	let devicetemp=$(ls -l      | grep "^[bc]"| wc -l | tr -d " ")
	if [ "$devicetemp" -eq "0" ]; then
    	devices="0"
	else
    	devices=" ${devicetemp}"
	fi
	unset devicetemp

        echo ${files}\|${hiddenfiles}f ${executables}x ${directories}\|${hiddendirectories}d ${links}l ${devices}v
}

function currentLoadInfo_determine
{
	#
	# DESC
	#       Determine some statistics about the current load
	#       based on the difference between the 1 and 5 minute loads reported
	#       by "uptime"
	#

	if [ -x /usr/bin/uptime ] ; then
		local one=$(uptime | sed -e "s/.*load average: \(.*\...\), \(.*\...\), \(.*\...\)/\1/" -e "s/ //g")
		local five=$(uptime | sed -e "s/.*load average: \(.*\...\), \(.*\...\), \(.*\...\).*/\2/" -e "s/ //g")
		local diff1_5=$(echo -e "scale = scale ($one) \nx=$one - $five\n print \" \"\n print x \nquit \n" | bc)
		loaddiff="$(echo -n "${one}${diff1_5}")"

    	        load=$(echo -e "scale = 0 \n $one/0.01 \nquit \n" | bc)
    	        if [ $load -gt 200 ]; then
    		        HOST_COLOUR=$LIGHT_RED
    		        else if [ $load -gt 100 ]; then
    			        HOST_COLOUR=$YELLOW
    			else
    				HOST_COLOUR=$LIGHT_GREEN
    		        fi
    	        fi
	else
		loaddiff="No Load"
	fi
        echo $loaddiff
#	return $loaddiff
}

function dsend
	#
	# ARGS
	#	$1		text string to send
	#
	# DESC
	# 	A simple wrapper around 'SSocket_client'.
	#
	# HISTORY
	# 09 March 2005
	#  o Initial design and coding.
	#
{
	SSocket_client --msg "$1"
}

function manpr
        #
        # ARGS
        #       $1            man page to print
        #       $2            destination device. "-" is stdout
        #
        # DESC
        #       If $2 == "-", outputs PostScript to stdout, else assumes
	#       that $2 denotes a printer name
	#
        # HISTORY
        # 09 January 2001
        #  o Initial design and coding
        #
{
	case $2 in
		- )
        	man $1 | nroff -man | enscript -1RjG -fCourier8 -p -
		;;
		* )
		man $1 | nroff -man | enscript -1RjG -fCourier8 -P $2
	esac
}

function manmac
{
	man -t $1 | open -f -a preview
}

function cdr
{
	cd /cygdrive/$1
}

#\\\
# Define the xterm title bar
#///
TTY=$(tty | sed 's/\/dev\///')
# Simplest case, for all shells / architectures
TITLEBARBASIC='\[\033]0;\u@\h ($OSTYPE) $TTY \w\007\]'
TTBASIC='\033[s\033[0;0H\033[K\u@\h ($OSTYPE) $TTY \w\007\033[u\]'
case $TERM in
	*term* | *win* | *rxvt* )
	if [ $OSTYPE = beos ] ; then
                TITLEBARBASIC='\[\033]0;\u ($OSTYPE) $TTY \w\007\]'
	else
                TITLEBARPARTITION='\[\033]0;\u@\h ($OSTYPE) [$(currentDirSize_determine)/$(currentPartitionUse_determine)] $TTY \w\007\]'
                TTPARTITION='\033[s\033[0;0H\033[K\u@\h ($OSTYPE) [$(currentDirSize_determine)/$(currentPartitionUse_determine)] $TTY \w\007\033[u\]'
                PARTITIONSTATS='$(currentDirSize_determine)/$(currentPartitionUse_determine)'
                FILESTATS='$(currentDirFileStats_determine)'
                LOADSTATS='$(currentLoadInfo_determine)'
                TTFULL='\033[s\033[0;0H\033[K\u@\h $(uname -sr) [$(currentLoadInfo_determine)][$(currentDirFileStats_determine)][$(currentDirSize_determine)/$(currentPartitionUse_determine)] $TTY \w\007\033[u\]'
        fi
        ;;
	*)
                TITLEBARBASIC=""
        ;;
esac

#\\\
# Path concerns
#///
name=$(hostname | awk -F. '{print $1}')

# The "self" directory is simply the home directory on the local machine.
# It is assumed that the "arch" and "arch/scripts" directories on the
# home partition are either local or linked to the correct partitions.
self=$HOME

# The "lab" directory denotes a "group" shared directory.
case $name in
        "pangea" )      lab=/opt			;;
        "localhost" )   lab=/opt			;;
        * )             lab=/opt			;;
esac

# Setup some variables for local/self/lab/java paths
b_64=$(uname -a | grep x86_64 | wc -l)
if (( b_64 )) ; then
	BIT=64
else
	BIT=32
fi

for DIR in bin lib scripts ; do
        for ACCESS in local self lab java ; do
        	arch=$(uname)
		b_NT=$(uname -a | grep CYGWIN | wc -l)
		if (( b_NT )) ; then
			arch=win
		fi
                case $ACCESS in
                        "self" )        root=$self      ;;
                        "lab" )         root=$lab       ;;
                        "java" )        root=$self
                                        arch="java"     ;;
			"local" )	root=$self
					arch="local"	;;
                esac
                if [ $DIR = "scripts" ] ; then
                        export "${ACCESS}_${DIR}"="${root}/arch/scripts"
                else
                        export "${ACCESS}_${DIR}"="${root}/arch/${arch}${BIT}/${DIR}"
                fi
        done
done
arch=$(uname)

statsBasic
if [ -f ~/.ls_colours_bash ] ; then
        . ~/.ls_colours_bash
fi

#\\\
# Some internal shell variables
#///
umask u=rwx,g=rwx,o=
set     -o ignoreeof
set     -o emacs
if [ $arch != BeOS ] ; then
	set     -o notify
fi
shopt   -s cdspell
shopt   -s checkwinsize

#\\
# Miscellaneous environment variables
#///
export CLASSPATH=$java_lib
export SAL_IGNOREXERRORS=1
export PRINTER=HPhpLaserJet1000
export FONT=7x14bold
export TAPE=/dev/nrtape/dat
export ENSCRIPT="-1RjG -P$PRINTER -MLetter -fHelvetica10"
export ORGANIZATION="MGH/MIT/HMS Athinoula A. Martinos Center for Biomedical Imaging"
export REPLYTO=$(whoami)@$(hostname)
#export EMACSPACKAGEPATH="${HOME}"/arch/common/share/xemacs21/packages
export NNTPSERVER=news
export COLORTERM=1
export SDKEYDIR=${lab}/arch/common/sdfast
export PSTILL_PATH=${lab}/arch/${arch}/pstill_dist
#export FILEWATCH="--optargs -p__/home/rudolph/arch/scripts/System_sounds/__-f__#file__-c__%pid"
export FLASH_GTK_LIBRARY=libgtk-x11-2.0.so.0
export CDPATH=.:/home/rudolph:/homes/9/rudolph:/space/kaos/1/users/rudolph/data/recon:/space/sound/10/users/pfizer_testretest/data:/cmas/nodulus/1/users/CMA/otl
export PYTHONPATH=~/src/devel/pythonpath

#\\
# CVS related environment variables
#//

case $HOSTNAME in
	mosix* )
		export CVSROOT=:pserver:${USER}@pangea:/mch/mch3/proj/CVS_repository
	;;
	*localhost* )
		export CVSROOT=:pserver:${USER}@pangea:/mch/mch3/proj/CVS_repository
	;;
	* )
		#export CVSROOT=:ext:rudolph@gate.nmr.mgh.harvard.edu:/space/repo/1/dev
		export CVSROOT=:ext:rudolph@gate.nmr.mgh.harvard.edu:/space/repo/1/sanfs
		export CVS_RSH=ssh
	;;
esac

#\\\
# Miscellaneous aliases
#///
alias xsu='xterm -bg "#440000" -fg white -fn $FONT -T root@$(hostname) -e su -'
alias htv='xterm -g 80x60 -e lynx'
alias xless='xless -g 80x45'
alias rmi='rm -i'
alias skiet='kill -9'
alias bye='logout'
alias clean='rm -f $(/bin/ls *% .*% .*~ *~ \#*\# [c][o][r][e] [L][O][G] 2>/dev/null | tee /dev/tty) >/dev/null'
alias c='clear'
alias qtld='export LD_LIBRARY_PATH=/home/pienaar/arch/${arch}/qt/lib:$LD_LIBRARY_PATH'
alias psap='ps -Af | grep '

#\\\
# NMR aliases
#///
alias ssc='source "${HOME}"/.bashrc ; source "${HOME}"/.bash_profile ; source "${HOME}"/.ls_colours_bash-bgblack'
alias nse='source "${HOME}"/arch/scripts/nse'
alias cnde='source "${HOME}"/arch/scripts/cnde'
alias chb-fsdev='source "${HOME}"/arch/scripts/chb-fsdev'
alias chb-fsstable='source "${HOME}"/arch/scripts/chb-fsstable'
alias chb-fsunstable='source "${HOME}"/arch/scripts/chb-fsunstable'
alias chb-connectome='source "${HOME}"/arch/scripts/chb-connectome'
alias chb-connectome-dbg='source "${HOME}"/arch/scripts/chb-connectome-dbg'
alias nmr-fsdev='source "${HOME}"/arch/scripts/nmr-fsdev'
alias lnde='source "${HOME}"/arch/scripts/lnde'
alias nde='source "${HOME}"/arch/scripts/nde'
alias lde='source "${HOME}"/arch/scripts/lde'
alias rde='source "${HOME}"/arch/scripts/rde'
alias rde64='source "${HOME}"/arch/scripts/rde64'
alias rde64-dev='source "${HOME}"/arch/scripts/rde64-dev'
alias mde='source "${HOME}"/arch/scripts/mde'
alias nsed='source "${HOME}"/arch/scripts/nsed'
alias ss='source "${HOME}"/.bashrc ; source "${HOME}"/.bash_profile'
#alias m='/space/lyon/9/pubsw/Linux2/common/matlab/7.0.1/bin/matlab -nosplash -nodesktop'
alias m='~/arch/scripts/matlab -c'
alias plm='LD_PRELOAD=/lib/libgcc_s.so.1 /space/lyon/9/pubsw/Linux2-2.3-i386.new/bin/matlab7.7 -nosplash -nodesktop'
alias mu='MATLAB_JAVA=/usr/lib/jvm/java-6-sun/jre /space/lyon/9/pubsw/Linux2-2.3-i386.new/bin/matlab7.7 -nosplash -nodesktop'
alias m64='/space/lyon/9/pubsw/Linux2-2.3-x86_64/bin/matlab7.8 -nosplash -nodesktop'
alias mmac='/usr/pubsw/packages/matlab/7.8/bin/matlab -nosplash -nodesktop'
alias mchb='matlab -nosplash -nodesktop'
alias es='export SUBJECTS_DIR=$(pwd)'
alias ep='export PATH=$(pwd):$PATH'
alias ks='pushd . >/dev/null ; cd /cmas/fs/1/users/freesurfer/Subjects/surf_parc/kentron ; es ; popd >/dev/null'
alias uldp='unset LD_LIBRARY_PATH'
alias aldp='export LD_LIBRARY_PATH=$(pwd):$LD_LIBRARY_PATH'
alias cms='pushd . >/dev/null ; cd /cmas/fs/1/users/freesurfer/Subjects ; es ; popd >/dev/null'
alias oo='"${HOME}"/arch/Linux/packages/OpenOffice.org/soffice'
alias oob='"${HOME}"/arch/Linux/packages/OpenOffice.org/soffice "-accept=socket,host=localhost,port=2002;urp;"'
alias gp='export XDG_CONFIG_DIRS=/opt/local/etc/xdg ; export XDG_DATA_DIRS=/opt/local/share'
alias ']'='gnome-open'

export bashrc_read=1

if [[ -f "${HOME}"/arch/scripts/localEnv.bash ]] ; then
	source "${HOME}"/arch/scripts/localEnv.bash
fi



# This line was appended by KDE
# Make sure our customised gtkrc file is loaded.
export GTK2_RC_FILES=$HOME/.gtkrc-2.0
export OOO_FORCE_DESKTOP=gnome

