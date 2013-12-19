#
# NAME
#
#	parval.tcl
#
# SYNOPSIS (of main entry point)
#
#	PARVAL_interpret name option
#
# DESCRIPTION
#
#	This package contains a simple, yet robust, command line
#	interpreter. The package design is object-orientated, with
#	the following class structure:-
#
#		> cs		Command string prefix (default "--")
#		> parameter	Command being searched for
#		> value		The command's value
#		> argnum	The ordinal occurence of `parameter'
#				in a search list
#		> argv		The search list (usually the command line
#				arguments)
#
#	Each instance of a PARVAL "class" contains a complete seach list,
#	labelled `argv'. Of course, explicitly declaring `argv' within the
#	"class" means that each PARVAL instance has its own local copy of
#	whatever was defined by argv. The name, argv, reflects that in 
#	most cases this list is simply the command line parameters (of course,
#	any list will interpreted just as easily).
#
#	PARVAL contains implicit knowledge of the syntax of argv. It 
#	assumes argv contains an arbitrary ordering of <name> <value>
#	pairs, with <name> prefixed by cs ("--"). It is possible
#	for <name> to have no <value>. PARVAL will simply assign
#	nothing to that record.
#
#	Most of the intelligence in interpreting a PARVAL structure
#	resides in the calling program.
#
# COUPLETS
#
#	The combination of <name> <value> form a couplet. Once <name>
#	is found in the argv list, `value' is initially set to `1'.
#	The argument immediately following <name> is checked. If it 
#	is not preceded by cs ("--"), it is assumed to be a value and
#	the internal `value' is set to this argument.
#
#	Note that this allows for simple boolean (non-couplet) switches
#	to be simply parsed, provided that the syntax of the command
#	line arguments does not contain "noise". Consider a command
#	line string such as "--gamma 9 --antialias --alpha 4". The
#	"--antialias" is a non-couplet switch. When parsed, its value
#	is initially set to `1', the next argument is examined and 
#	seen to be a command. The value of --antialias remains thus `1'.
#	The calling program can test for --antialias by parsing for it
#	and examining the `argnum'. If != -1, it can use the <value>
#	to imply a boolean variable.
#
#	This whole approach is simply to allow for "purely" automated
#	parsing of command lines and assigning internal variables.
#	
#
#
# EXAMPLE
#
#	Given a command line of:
#
#		> executable --option1 value1 --option2 value2 --option3
#
#	the main program can construct a PARVAL object called (for instance)
#	clarg with
#
#		> set arr_PARVAL(0) 0
#		> PARVAL_build clarg $argv "--"
#
#	which builds an object, clarg, with $argv, and specifying that 
#	"--" prefixes <name>.
#
#	Using
#
#		> PARVAL_interpret clarg option1
#
#	would fill the clarg structure. `argnum' would be 0,
#	parameter `option1', and value 'value1'.
#
#	By examining the value of argnum, the calling program can
#	determine whether a particular <name> occured in the passed
#	list.
# 
#
# NOTE (NB!)
#
#	Each program that uses this "class" needs to declare a global
#	array variable, arr_PARVAL. This can be simply accomplished by
#	`set arr_PARVAL(0) 0'
#
#
# HISTORY
#
# 01-06-2000
# o Initial design and coding. Derivation from `commint.c'
#
# 22 September 2004
# o Added an option for processing option values that contain spaces,
#	"os" : option spaces. If set to "1", then assume options can
#	contain spaces, and that no "spurious" options are in $argv.
#

package provide parval 0.1

proc PARVAL_build {name argv {cs "--"} {so "0"}} {
    global arr_PARVAL

    set arr_PARVAL($name,cs)		$cs
    set arr_PARVAL($name,argv)		$argv
    set arr_PARVAL($name,parameter)	""
    set arr_PARVAL($name,value)		""
    set arr_PARVAL($name,argnum)	-1
    set arr_PARVAL($name,so)		$so

    return arr_PARVAL
}

proc PARVAL_nullify {name {so "0"}} {
    global arr_PARVAL

    set arr_PARVAL($name,cs)		"--"
    set arr_PARVAL($name,parameter)	""
    set arr_PARVAL($name,value)	""
    set arr_PARVAL($name,argnum)	-1
    set arr_PARVAL($name,so)		$so
}

proc PARVAL_print {name}  {
    global arr_PARVAL

    puts stdout "PARVAL:\t\t$name"
    puts stdout "cs:\t\t$arr_PARVAL($name,cs)"
    puts stdout "so:\t\t$arr_PARVAL($name,so)"
    puts stdout "parameter:\t$arr_PARVAL($name,parameter)"
    puts stdout "value:\t\t$arr_PARVAL($name,value)"
    puts stdout "argnum:\t\t$arr_PARVAL($name,argnum)"
    puts stdout "search list:\n\t$arr_PARVAL($name,argv)"
}

proc PARVAL_interpret {name option} {
    global arr_PARVAL

    PARVAL_nullify $name $arr_PARVAL($name,so)
    set argnum \
	[lsearch -regexp $arr_PARVAL($name,argv) $option]
    
    set parameter \
	[lindex $arr_PARVAL($name,argv) $argnum]

    if { [string first $arr_PARVAL($name,cs) $parameter] != 0 } {
	return
    }

    set arr_PARVAL($name,argnum) $argnum
    if {$argnum==-1} {
	return
    } else {
	incr argnum
	set arr_PARVAL($name,parameter) $option
	set arr_PARVAL($name,value) 1
	set argc [llength $arr_PARVAL($name,argv)]
	if {$argnum < $argc} {
	    if {$arr_PARVAL($name,so)} {
	    	set value [lindex $arr_PARVAL($name,argv) $argnum]
		set arr_PARVAL($name,value) ""
		set wordCount "0"
		while {[string first $arr_PARVAL($name,cs) $value] != 0 && $argnum < $argc} {
		    if {$wordCount} {
			append arr_PARVAL($name,value) " "
		    }
		    append arr_PARVAL($name,value) $value
		    incr argnum
		    incr wordCount
		    set value [lindex $arr_PARVAL($name,argv) $argnum]
		}
	    } else {
	    	set value [lindex $arr_PARVAL($name,argv) $argnum]
	    	if { [string first $arr_PARVAL($name,cs) $value] != 0 } {
		    set arr_PARVAL($name,value) $value
	    	}
	    }
	}
    }
} 
