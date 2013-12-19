#
# NAME
#
#	misc.tcl
#
# DESCRIPTION
#
#	Miscellaneous tcl routines
#
# TODO
# o	`clint' needs to be more robust - specifically as far as 
#	interpreting flags with no arguments
#
# HSTORY
#
# 5-11-1998
# o	Initial transfer and testing
#
# 1-10-2000
# o	Re-evaluation. Beautify
#

package provide misc 0.1

proc weekdays_list {} {
    set weekdays { Mon Tue Wed Thu Fri Sat Sun }
    return $weekdays
}

proc deref {pointer {level 1} }  {
#
# ARGS
# pointer		in		name of holder variable
# level		        in (opt)	        stack level reference	
#
# DESC
# "Dereferences" a "pointer" - i.e. a variable containing
# the name of anothr variable.
#
#
    upvar $level $pointer contents
    return $contents
}

proc clint {argv lst_commargs {prefix ""} } {
#
# ARGS
# argv			in		list of command line arguments
# lst_commargs	        in		input list of search variables
#					Variables are assumed defined at a 
#					higher stack level
# prefix		        in		string to prefix to variable name at a
#					higher stack level
#
# DESC
# (Very) Simple command line interpreter.
#
# NOTE
# o It is assumed that lst_commargs are prefixed by "--"
#
    set state flag
    foreach arg $argv {
	set found 0
	switch -- $state {
	    flag {
		foreach commline $lst_commargs {
		    set firstChar [string range $commline 0 0]
		    if {[string first $firstChar $arg]==2} {
			set state value
			set var $commline
			set found 1
			break
		    }
		}
		if {!$found} {
		    puts "unknown flag $arg"
		    exit 100
		}
	    }
	    value { 
		set state flag
		upvar ${prefix}${var} variable
		set variable $arg
		
	    }
	}
    }
}


