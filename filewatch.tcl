#!/bin/sh
# the next line  restart with wish \
 exec tclsh "$0" $@
#
#
# NAME
#
#	filewatch.tcl
#
# SYNOPSIS
#
#	filewatch.tcl	[--file <filename>]		\
#			[--interval <seconds>]		\
#			[--checkfor <attribute>]	\
#			[--execute <file>]		\
#			[--optargs <scriptargs>]	\ 
#			[--clean]			\
#			[--tmp <tmpDir>]		\
#			[--quiet]			\
#			[--usage]		
#
# 
# DESCRIPTION
#
#	`filewatch.tcl' monitors a given file for a change in a specific
#	attribute. When this change occurs, it takes appropriate action
#	- usually specified as a file that is called.
#
#	Command line attributes:-
#		o --file <filename> : 
#			> file that is watched
#		o --interval <seconds> : 
#			> amount of time (seconds) that the process sleeps 
#			  before checking target
#		o --check <attribute> : 
#			> parameter that is checked:-  
#			  (atime ctime dev gid ino mode mtime nlink size uid)
#		o --quiet
#			> indicates that script dumps no output to stdout
#		o --execute <file> : 
#			> indicates file that is executed when attribute
#			  changes
#			> if called with no value, indicates that the script 
#			  file is '<filename>_changed'
#		o --optargs <scriptargs> :
#			> additional command line arguments passed on to 
#			  spawned process.
#			> in order to parse correctly, the arguments must be 
#			  double underscore '__' delimited, and enclosed 
#			  within escaped quotations marks, eg: 
#
#		--optargs \"-a__audiofile.wav__-r__some.machine__-l__username\"
#
#			  will be passed as:
#
#		-a audiofile.wav -r some.machine -l username
#
#		o --clean
#			> forces script to clean /tmp dir of all `state' files 
#			  containing current hostname.
#			> useful if only one filewatch process 
#			  is running per host.
#
#		o --tmp <tmpDir>
#			> The directory in which to keep temporary state tracking
#			  information. Defaults to /tmp
#		o --usage
#			> gives synopsis
#
# NOTE
#
#	`filewatch.tcl' provides the ability to parse metadata within
#	the optargs string. It is possible that the executed program
#	might require some filewatch.tcl specific values, passed to it
#	within optargs. This metadata is of two forms, embedded tcl
#	scripts, and internal filewatch.tcl variables.
#
#	Internal variables are referenced by the syntax "#varname", and
#	embedded tcl scripts are denoted by "%script". Note that at this
#	stage, these embedded scripts are limited to simple one-statement
#	commands.
#
#	For example, assume that the spawned executable requires, amongst
#	others, the flags "-c pid -f file -p somepath". The pid refers to
#	the pid of the calling process, i.e. filewatch's pid, and file refers
#	to the filewatch.tcl variable, $gv(file). This could be specified
#	either directly on the command line to filewatch, or, perhaps 
#	more simply, in the environment variable FILEWATCH (which can
#	contain a default command line arg list) as:
#
#		--optargs -p__/home/pienaar/__-f__#file__-c__%pid
#
#	`filewatch.tcl' will parse its command line arguments, and
#	interpret any metacharacters within the optargs value.
#
#
#
# HISTORY
#
# (Initial script history not recorded)
#
# 5-20-1996
# o Script resuscitated...
# o 'quiet' parameter added
# o show_synopsis routine added...
#
# 10-17-1997
# o Returned once again to this script
# o Corrected minor bug with '-execute' flag
#
# 10-19-1997
# o Added `clean' command line argument - cleans /tmp dir.
#
# 01-05-2000
# o Modernization phase
# o Removed dependence on external C command line interpreter
#
# 01-06-2000
# o Added var_dump
#
# 01-07-2000
# o Developed PARVAL from `commint.c'
#
# 01-07-2000
# o Consolidated globals into single array structure
#
# 01-11-2000
# o Removed implicit scriptargs flags - program is too auddif.sh
#   specific otherwise.
# o Script examines environment variable FILEWATCH for default
#   optargs
#
# 07-14-2008
# o Added --tmp <tmpDir>
#

# includes
lappend auto_path ~/src/devel/tcl_packages
package require parval
package require misc

###\\\
# Globals --->
###///

set lst_switches \
    { file interval checkfor execute optargs clean verbose usage }

set gv(SELF)		filewatch.tcl
set gv(file)		/var/log/messages
set gv(checkfor)	size
set gv(interval)	10
set gv(execute)		auddif.sh
set gv(verbose)		0
set gv(clean)		0
set gv(tmp)		/tmp
set gv(usage)		0
set gv(host)		[exec hostname]
#set gv(scriptargs)	"-c [pid]"
#set gv(optargs)		"-p__/home/pienaar/arch/scripts/System_sounds/"
set gv(optargs)		""

###\\\
# Function Definitions --->
###///

proc var_dump {} {
    # dumps the values of all the global variables
    global gv

    puts stdout ""
    puts stdout "Global variable dump: ([exec date])"
    puts stdout "SELF:\t\t$gv(SELF)"
    puts stdout "file:\t\t$gv(file)"
    puts stdout "checkfor:\t$gv(checkfor)"
    puts stdout "interval:\t$gv(interval)"
    puts stdout "execute:\t$gv(execute)"
    puts stdout "verbose:\t$gv(verbose)"
    puts stdout "clean:\t\t$gv(clean)"
    puts stdout "tmp:  \t\t$gv(tmp)"
    puts stdout "usage:\t\t$gv(usage)"
    puts stdout "host:\t\t$gv(host)"
    puts stdout "optargs:\t$gv(optargs)"
}

proc tcl_getParam {filename checkfor} {
    # If the target <filename> does not exist, this proc will
    # return a zero.
    if {[catch {file stat $filename info} errormsg]} {
	set param 0
    } else {
    	set param $info($checkfor)
    }
    return $param
}

proc synopsis_show {} {
    global gv
    puts stdout ""
    puts stdout "USAGE:"
    puts stdout "$gv(SELF) \t\[--file <name=$gv(file)>\] \\"
    puts stdout "\t\t\[--interval <seconds=$gv(interval)>\] \\"
    puts stdout "\t\t\[--check <checkfor=$gv(checkfor)>\] \\"
    puts stdout "\t\t\[--execute <file=$gv(execute)>\] \\"
    puts stdout "\t\t\[--optargs <$gv(optargs)>\] \\"
    puts stdout "\t\t\[--usage\] \\"
    puts stdout "\t\t\[--clean\] \\"
    puts stdout "\t\t\[--tmp <tmpDir=$gv(tmp)>\]		"
    puts stdout ""
    shutdown 0
}

proc shutdown {exitcode} {
    global gv
    puts stdout "\n\t$gv(SELF)"
    puts stdout "\tShutting down - sending system code $exitcode"
    exit $exitcode
}

###\\\
# main --->
###/// 

#
# First, parse command line arguments
#

# Build commswitch array "class"
set arr_PARVAL(0) 0
PARVAL_build commswitch $argv "--"

# Append the environment variable $FILEWATCH to the command
# path. Any switches passed on the command line will precede
# $FILEWATCH, and thus override environment parameters

catch {set arr_PARVAL(commswitch,argv) [concat $arr_PARVAL(commswitch,argv) $env(FILEWATCH)]} errormsg

# Parse the commargs

foreach element $lst_switches {
    PARVAL_interpret commswitch $element
    if { $arr_PARVAL(commswitch,argnum) >= 0 } {
	set gv($element) $arr_PARVAL(commswitch,value)
    }
}

# Parse the double underscore "__" optargs
if {[string length $gv(optargs)]} {
    regsub -all "__" $gv(optargs) " " optargs_nospaces
    set gv(optargs) $optargs_nospaces
    regsub ^\" $gv(optargs) "" optargs_noquotes_start
    set gv(optargs) $optargs_noquotes_start
    regsub \"$ $gv(optargs) "" optargs_noquotes_end
    set gv(optargs) $optargs_noquotes_end
}

# Now, interpret the optargs for any meta data. This can either
# be latent commands, preceded by "%", or referenced variables,
# preceded by "#"

# First the latent commands
# Check the optargs for any argument values that start with
# "%". These arguments are directly executed by filewatch (with some
# rudimentary security, of course!).

set largv [split $gv(optargs) " "]
set whereComm [lsearch -regexp $largv %]
while {$whereComm > -1} {
    set toExec [lindex $largv $whereComm ]
    set comm [lindex [split $toExec %] 1]
    switch -- $comm {
	pid {
	    set value [pid]
	}
    }
    set largv [lreplace $largv $whereComm $whereComm $value]
    set whereComm [lsearch -regexp $largv %]
}

# Second the referenced variables
# Check the command string for any argument values that start with
# "#". These arguments refer to filewatch.tcl variables

set whereVar [lsearch -regexp $largv \#]
while {$whereVar > -1} {
    set intVar [lindex $largv $whereVar ]
    set var [lindex [split $intVar \# ] 1]
    set value $gv($var)
    set largv [lreplace $largv $whereVar $whereVar $value]
    set whereVar [lsearch -regexp $largv \#]
}

set gv(optargs) [join $largv " "]

# Do we just want the synopsis?
if {$gv(usage)} {
    synopsis_show
}

# Strip away any path information in the filename
set broken [split $gv(file) "/"]
set name [lindex $broken [expr [llength $broken] - 1] ]

# Check if --execute was specified as a couplet
if { $gv(execute) == 1 } {
    set longname [concat $name "changed"]
    set gv(execute) [join $longname "_"] 
}

# Remove the domain from the host name
set broken [split $gv(host) "."]
set gv(host) [lindex $broken 0]	

unset broken name

# Set initial conditions
set param [tcl_getParam $gv(file) $gv(checkfor)]
set old_param $param

if {$gv(verbose)} {
    puts stdout ""
    puts stdout "Target file:\t$gv(file)"
    puts stdout "Monitoring:\t$gv(checkfor)"
    puts stdout "Time interval:\t$gv(interval) seconds"
    puts stdout "Process id:\t[pid]"
    puts stdout "\nCheckpointing initial $gv(checkfor) as:\t<$param>"
    puts stdout "Any changes will fork:\t\t$gv(execute)"
    puts stdout "Optional arguments:\t\t$gv(optargs)"
    puts stdout ""
}

if {$gv(clean)} {
    puts stdout "Cleaning old states in $gv(tmp) dir..."
    set found [ catch {eval exec ls [glob $gv(tmp)/*$gv(execute)*$gv(host)*]} ]
    if {[lindex $found 0]} {
	puts stdout "No old states found!"
    } else {
	eval exec rm -f [glob $gv(tmp)/*$gv(host)*state*] >/dev/null
    }
}

while {1==1} {
    set param [tcl_getParam $gv(file) $gv(checkfor)]
    if {$param!=$old_param} {
	if {$gv(verbose)} {
	    puts stdout "Executing: $gv(execute) $gv(optargs)"
	}
	set err [catch {eval exec $gv(execute) $gv(optargs)} returnVal]
	if {$gv(verbose)} {
	    puts stdout $returnVal
	}
#	if {$err} {
#	    puts stderr "Some error occurred when executing:"
#	    puts stderr "$gv(execute) $gv(optargs)"
#	    puts stderr "\nexiting..."
#	    exit 1
#	}
	set old_param $param
    }
    if { $gv(interval) } { exec sleep $gv(interval) }
}



