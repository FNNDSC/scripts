#
# NAME
#
#	class_struct.tcl
#
# DESCRIPTION
#
#	This package provides general "pseudo class" 
#	construction/manipulation routines as well as some general 
#	purpose functions.
#
#	Basic data types are denoted by the following prefices:-
#	o <none>		normal string data
#	o arr			array type data
#	o lst			list type data
#	o ptr			"pointer"-type data
#
# HISTORY
#
# 04-28-1998
# o	Version 0.1 created from `backup_mgr' process
#
# 01-10-2000
# o	Resurrected and testing in new environment.
# o	Beautify
#
# 01-17-2000
# o	Strange bug found in array_associate with [string trimleft]
#	(see code)
#

package provide class_struct 0.1

proc class_get {classOut classIn field} {
#
# ARGS
# classOut		out		holder for returned child class
# classIn		in		parent class
# field		in		record name in parent class
#
# DESC
# Given a class that is a superset of other classes (arrays), return
# the class (as an array) denoted by field.
#
#
    upvar $classIn arr
    upvar $classOut records

    foreach {key data} [array get arr]  {
	if {![string first $field $key]} {
	    lappend lst_data $data
	    lappend lst_key $key
	}
    }
    class_Initialise records $lst_key $lst_data
}

proc list_order {classIn lst_order} {
#
# ARGS
# classIn		in		input array with arbitrary order
# lst_order		in		ordered list of indices
# lst_ordered		return		ordered list of values
#
# DESC
# Considering that the order of array elements is stored in an
# arbitrarily indexed hash table, this routine takes a class (array)
# as well an ordered list of indices, and returns a list containing
# the array values structured according to this order.
#
#
    upvar $classIn arr
    foreach element $lst_order {
	foreach {key value} [array get arr] {
	    if {[string match *$element* $key]} {
		lappend lst_ordered $value
		break
	    }
	}
    }
    return $lst_ordered
}

proc class_Initialise {class struct initdata {filename void}} {
#
# ARGS
# class			in/out		class variable to be initialised
# struct		in		structure of the class (array indices)
# initdata	        in		structure based initialisation data 
#					(array values)
# filename		in (opt)	file containing initialisation data
# arr			return		initialised class variable 
#
# DESC
# Initialises a class.
#
# If <filename>==void, then class is initialised with <initdata>,
# else class is initialised with contents of <filename>.
#
# If <filename>!=void and <filename> does not exist,
# initialisation reverts to <initdata>
#
# NOTE 
# o	<filename> must have been created by an
#	earlier call of `class_Dump'
# o	The class is returned in function name as well
#	as in <class>
#

    global delim
    upvar $class arr

    if {![string first lst $struct]} {
	set class_struct [deref $struct "#0"]
    } else {set class_struct $struct}
    if {![string first lst $initdata]} {
	set class_data [deref $initdata "#0"]
    } else {set class_data $initdata}

    if {$filename!="void"} {
	if [catch {open $filename r} fileID] {
	    puts stderr "Cannot initialise from file $filename"
	    puts stderr "Reverting to <initdata>"
	    set filename void
	} else {
	    foreach line [split [read $fileID] \n] {
		set record [join $line " "]
		if {[string length $record]} {
		    set array_index [lindex [split $record $delim] 0]
		    set array_value [lindex [split $record $delim] 1]
		    set arr($array_index) [string trimleft $array_value]
		}
	    }
	}
    } 
    if {$filename=="void"} {
	array_associate arr $class_struct $class_data
    }
    return arr
}

proc array_associate {class lst_key lst_data} {
#
# ARGS
# class			in/out		name of array to be associated
# lst_key		in		list of array indices
# lst_data		in		list of corresponding values
# arr			return		associated array
#
# DESC
# Recursive array builder. 
#
# If a data element is prefixed with `arr' it is itself of type array and 
# all its indices and values are added to the parent class, prefixed with 
# the parent index name for the field corresponding to the data element.
#
# If a data element is prefixed with `ptr' it is assumed to a "pointer" 
# operation i.e. it denotes the name of a variable containing the actual 
# data.
#
    upvar $class arr
    foreach value $lst_data index $lst_key {
	if {![string first arr $value]} {
	    upvar "#0" $value arrn
	    foreach {key data} [array get arrn] {
		lappend deepKey $index,$key
		lappend deepData $data
	    }
 	    array_associate arr $deepKey $deepData
	    if {[info exists deepKey]} {unset deepKey}
	    if {[info exists deepData]} {unset deepData}
	} elseif {![string first "ptr" $value]} {
	    set stripped [string trimleft $value "ptr"]
	    set stripped [string trimleft $stripped "_"]
	    upvar "#0" $stripped deref_value
	    set arr($index) "$deref_value"
	} else {
	    set arr($index) $value
	}
    }
    return arr
}

proc class_Dump {class {filename void}} {
#
# ARGS
# class			in		class variable to be dumped
# filename		in (opt)        name of target file to dump to
#
# DESC
# Dumps a class to a file buffer, specified by the filename param.
# Default is filename=void, in which case info is dumped to stdout.
# If filename=="Class", then the created file will have the same name
# as the name field of the class, otherwise the filename will
# be spec'd by the filename argument.
#
# HISTORY
# 29-06-2012
# o Fixed the formatting on output.
#
    upvar  $class arr
    global delim

    if {$filename=="void"} {
	set fileID stdout
    } elseif {$filename=="Class"} {
	set fileID [open $arr(name).dump w]
    } else {set fileID [open $filename w]}
    foreach {index value} [array get arr] {
	lappend arrlst "$index $value"
    }
    set sorted [lsort $arrlst]
    set prevSet ""
    foreach set $sorted {
	set index [lindex $set 0]
	set value ""
	for {set allargs 1} {$allargs < [llength $set]} {incr allargs} {
	    append value "[lindex $set $allargs] "
	}
	#set leading_tab [llength [split $index ,]]
	set currSet [lindex [split $index ,] [expr [llength [split $index ,]]-2]]
	if {$currSet!=$prevSet} {puts $fileID ""}
	#for {set i 1} {$i<$leading_tab} {incr i} {puts -nonewline $fileID "\t"}
	puts $fileID [format "%-20s%-50s" "$index$delim" "$value"]
	#puts -nonewline $fileID "$index$delim\t"
	#if { [expr [string length $index] %15] < 7 } { puts -nonewline  $fileID "\t" }
	#puts $fileID "$value"
	set prevSet $currSet
    }
    if {$filename!="void"} {close $fileID}
}
