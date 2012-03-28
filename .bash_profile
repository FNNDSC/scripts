##
#
# NAME
#
#	.bash_profile
#
# DESC
#
#	`.bash_profile' is the bash analogue of .login
#
# HISTORY
#
# 08 January 2000
#  o Separation from monolithic .bashrc.
#  o Contains basically only the splash screen
#
# 15 March 2002
#  o Expanded $PATH for gcc-3 "separate" installation tree.
#
# 03 March 2004
#  o Edits to CYGWIN path
# 
# 08 June 2005
#  o Added 'Darwin' section
#
# 25 October 2011
#  o git additions...
##

if [[ -f /usr/bin/uname ]] ; then
	arch=$(/usr/bin/uname)
fi

if [[ -f /bin/uname ]] ; then
	arch=$(/bin/uname)
fi

if [ ! ${bashrc_read:+1} ] ; then
        . ~/.bashrc
        export bash_profile_read=1
fi

if [ $arch = BeOS ] ; then
	HOSTNAME=BeOS
fi

function git_current {
   BRANCH_NAME=`git branch -v 2>/dev/null |grep '^*'|awk '{print $2}'`
   BRANCH_HASH=`git branch --abbrev=4 -v 2>/dev/null |grep '^*'|grep -o '[0-9a-f][0-9a-f][0-9a-f][0-9a-f]' | tr '\n' '-'`
   if (( ${#BRANCH_NAME} )) ; then
       echo -n "($BRANCH_NAME@$BRANCH_HASH)"
   fi
}

if [[ -f ~/.git.bash ]] ; then
    GIT_PROMPT='$(git_current)'
    if [[ $GIT_READ != "1" ]] ; then
	PS1orig="$PS1"
    fi
#    PS1_noTrail=$(echo $PS1orig | awk -F '\\$>' '{printf("%s\b%s\n", $1, $2);}')
#    PS1="${PS1_noTrail}${BROWN}${GIT_PROMPT}${NO_COLOUR}\\$>"

    PS1="${TITLEBARBASIC}${GREEN}\${newPWD}${BROWN}${GIT_PROMPT}${NO_COLOUR}\\$>"
    PS2='> '
    PS4='+ '

    source ~/.git.bash
    GIT_READ=1
fi

#\\\
# DISPLAY variable
#///
if [ $TERM = "xterm" ] ; then
        if [ ! ${DISPLAY:+1} ] ; then
                echo -n "X display name: "
                read display
                export DISPLAY=${display}:0.0
        fi
fi

#\\\
# Draw splash screen
#///
echo -en "\033[0m"
alias sep="echo +-----------------------------------------------------------------------------+"
sep
echo -en "\t\t\tWelcome to "
echo -e "\033[45m\033[1;33m$HOSTNAME\033[0m, $USER"
sep
echo -e "Terminal is an $TERM, on a $arch architcture\033[1;31m"
/usr/bin/uptime 2>/dev/null
echo -en "\033[0m"
sep
echo -en "\033[0;36m"

#\\\
# Some platform specific issues
#///
case $arch in
        Linux )

                #export PATH=".:$local_bin:$self_bin:$self_scripts:$lab_bin:$lab_scripts:$java_bin:${QTDIR}/bin:${KDEDIRS}/bin:/usr/bin:/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/games:/etc:/usr/etc:/usr/bin/X11:/usr/man:/usr/X11R6/bin:/opt/gnome/bin:/cmas/nodulus/1/common/Linux/bin"
                export PATH=".:$local_bin:$self_bin:$self_scripts:$lab_bin:$lab_scripts:$java_bin:${QTDIR}/bin:${KDEDIRS}/bin:/usr/bin:/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/games:/etc:/usr/etc:/usr/bin/X11:/usr/man:/usr/X11R6/bin:/opt/gnome/bin:/opt/torque/bin"
                alias cp='cp -pvrdi'
                alias ls='ls -CFh --color'
                mesg y
                finger -s
		echo -en "\033[0m"
		sep
		echo -en "\033[1;35m"
		fortune
		echo -en "\033[0m"
        ;;
        FreeBSD )
                export PATH=".:$local_bin:$self_bin:$self_scripts:$lab_bin:$lab_scripts:$java_bin:/usr/bin:/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/games:/etc:/usr/openwin/bin:/usr/etc:/usr/bin/X11:/usr/man:/usr/X11R6/bin"
                alias cp='cp -pPRi'
                alias ls='ls -CFG'
		export LSCOLORS="DxGxcxdxCxegedabagacad"
                finger
		echo -en "\033[0m"
		sep
		echo -en "\033[1;35m"
		fortune
		echo -en "\033[0m"
        ;;
        IRIX | IRIX64 )
                alias wavplay='soundplayer -nodisplay'
                alias play='/usr/sbin/soundplayer -nodisplay'
		alias xterm=color_xterm
		alias ping='ping -c 4'
                export LD_LIBRARY_PATH=/usr/freeware/lib:${LD_LIBRARY_PATH}
                export PATH=".:$local_bin:$self_bin:$self_scripts:$lab_bin:$lab_scripts:$java_bin:${KDEDIR}/bin:/usr/bin:/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/bsd:/etc:/usr/etc:/usr/bin/X11:/usr/man:/usr/local/sdfast/bin:/usr/freeware/bin:/usr/local/freeware/bin:/usr/local_bme/bin:/usr/java/bin"
                if [ -x /usr/freeware/bin/cp ] ; then
                        alias cp='/usr/freeware/bin/cp -pvrdi'
                fi
		alias ls='ls -CFh --color'
                mesg y
                finger -s
		echo -en "\033[0m"
		sep
		echo -en "\033[1;35m"
		fortune
		echo -en "\033[0m"
        ;;
        BeOS )
                alias cp='cp -pvrdi'
                alias ls='ls -CFh --color'
		echo -en "\033[0m"
		sep
		echo -en "\033[1;35m"
		fortune
		echo -en "\033[0m"
        ;;
        SunOS )
                export PATH=".:$local_bin:$self_bin:$self_scripts:$lab_bin:$lab_scripts:$java_bin:/usr/bin:/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/games:/etc:/usr/openwin/bin:/usr/etc:/usr/man:/opt/sfw/bin"
                alias cp='cp -pvrdi'
                alias ls='ls -CFh --color'
                mesg y
                finger -s
		echo -en "\033[0m"
		sep
		echo -en "\033[1;35m"
		fortune
		echo -en "\033[0m"
        ;;
        CYGWIN* )
		export PATH=".:$local_bin:$self_bin:$self_scripts:$lab_bin:$lab_scripts:$java_bin::${PATH}"
                alias cp='cp -pvrdi'
                alias ls='ls -CFh --color'
		echo -en "\033[0m"
		sep
		echo -en "\033[1;35m"
		fortune
		echo -en "\033[0m"
        ;;
       Darwin )
                export PATH=".:$local_bin:$self_bin:$self_scripts:$lab_bin:$lab_scripts:$java_bin:${QTDIR}/bin:${KDEDIRS}/bin:/usr/bin:/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/games:/etc:/usr/etc:/usr/bin/X11:/usr/man:/usr/X11R6/bin:/opt/gnome/bin:/opt/local/bin:/sw/bin"
                alias cp='gcp -pvrdi'
		if [[ -x gls ]] ; then
		    alias ls='gls -CFh --color'
		else
                    alias ls='ls -CFhG'
	        fi
		export TERM=xterm-color
		export CLICOLOR=1
		export CLICOLOR_FORCE=1
		export LSCOLORS="DxGxcxdxCxegedabagacad"
                mesg y
                finger -s
		echo -en "\033[0m"
		sep
		echo -en "\033[1;35m"
		fortune
		echo -en "\033[0m"
	;;
        * )
                mesg y
                who
                echo $sep
                echo -en "\033[0;31m"
                echo "( I cannot identify this architecture )"
        ;;
esac
echo -en "\033[0m"
sep
unalias sep

##
# Your previous /Users/rudolphpienaar/.bash_profile file was backed up as /Users/rudolphpienaar/.bash_profile.macports-saved_2009-09-10_at_13:29:49
##

# MacPorts Installer addition on 2009-09-10_at_13:29:49: adding an appropriate PATH variable for use with MacPorts.
export PATH=/opt/local/bin:/opt/local/sbin:$PATH
# Finished adapting your PATH environment variable for use with MacPorts.


##
# Your previous /Users/rudolphpienaar/.bash_profile file was backed up as /Users/rudolphpienaar/.bash_profile.macports-saved_2009-09-11_at_09:30:28
##

# MacPorts Installer addition on 2009-09-11_at_09:30:28: adding an appropriate PATH variable for use with MacPorts.
export PATH=/opt/local/bin:/opt/local/sbin:$PATH
# Finished adapting your PATH environment variable for use with MacPorts.

