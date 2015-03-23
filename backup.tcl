#!/bin/sh
# the next line  restart with wish \
 exec tclsh "$0" $@

set G_SYNOPSIS "

       backup.tcl

SYNOPSIS

       backup.tcl       --user          <user>          \\
                        --listFileDir   <listFileDir>   \\
                        --host          <host>          \\
                        --device        <device>        \\
                        --label         <label>         \\
                        --filesys       <filesys>       \\
                        --currentRule   <currentRule>   \\
                        --buffer        <buffer>        \\
                        --rsh           <rsh>           \\
                        --incReset      <incReset>      \\
                        --verbose       <on|off>

DESCRIPTION

       `backup.tcl' is the \"thin\" end of the backup_mgr.tcl process. It
       is typically called only by a controlling backup_mgr program, and
       receives several command line arguments from this controlling
       process. These arguments are used to construct a tar command
       that will ultimately create the archive.

       Note that backup.tcl is machine-specific. The tar command archives
       *local* file system directories (i.e. no multiple file systems) and
       does *not* follow cross links.

       The archive creation process is actually part of a pipeline,
       linking backup.tcl to a `buffer' command via a rsh. This buffer
       process writes the archive to tape, and consequently is run on the
       host that contains the backup device (which need not necessarily
       be the same host on which backup.tcl is run). Obviously it follows
       that this host needs to be configured to allow backup.tcl remote
       access.

       Incremental backups are made for weekly and daily runs. The daily
       backups are referenced to a previous \"weekly\" base; likewise the
       weekly backups are referenced to a \"monthly\" base run. Note that if
       for a particular run this base is non existent, a full backup is
       run and the results used to define a base for subsequent runs.

"

# TODO
# o        Need to consider the effect of non-monthly archive sets... They are
#        based on an incremental record, which if non-existant forces a 
#        complete backup. Perhaps these incremental records need to be 
#        periodically erased?
#
#        Perhaps some rule whereby the *first* daily or weekly backup 
#        per month erased the previous daily and weekly incremental record.
# 
# HISTORY
#
# 4-20-1998 / 04-24-1998
# o        Initial development, testing and debugging.
#
# 6-25-1998
# o        Added -force flag to copy command
#
# 6-26-1998
# o        Tracking down segmentation fault behaviour during monthly
#        vulcan backups. The tar command will be written to the command 
#        line and run manually to narrow down the scope of the
#        error.
#
# 6-29-1998
# o        Changed the construction of the pipeCmd - removed curly brackets
#        and replaced them with single quotes.
#
# 6-30-1998
# o        Re-implemented the basic archiving mechanism... too many 
#        difficulties with quoting between tcl grouping commands. Now this 
#        script creates a child script which contains the archive command 
#        with necessary quoting. This child is then executed.
#
#        Some advantages include cleaner behavior - if the controlling 
#        `backup_mgr' is killed, the overall backup still proceeds. If the 
#        child is killed, remote backup stops cleanly with no lingering 
#        processes hanging about on the target host.
#
# 7-2-1998
# o        Still getting segmentation violation on large archives. I suspect 
#        that the tcl interpreter dies while trying to catch the *huge* 
#        output of the tar command.
#
#        Two possible solutions:-
#                o Redirect all output to a file, which is parsed later
#                o Remove the `verbose' flag from the tar command
#
#        Simpler is probably better. Verbose is removed.
#
# 7-13-1998
# o        Added additional command line parameter, incReset, that
#        controls whether or not to erase the incremental data base used
#        by `tar'. For backup sets that do not have a monthly specifier, 
#        periodic cycling of the incremental file need to be effected - this
#        is specified with the incReset parameter with `yes' argument.
#
#        Note that the decision whether or not to implement this reset is
#        made by the managing `backup_mgr.tcl' process.
#        
# 7-22-1998
# o        Added archive set name to incremental title.
#
# 7-28-1998
# o        Added -v on flag for verbose logging
#
# 01-11-2000
# o        Re-evaluation
# o        Beautify
#
# 01-13-2000
# o        Command line arguments need two dashes ("--")!
#
# 01-14-2000
# o        Changed command line arguments to new GNU style
# o        Forced `verbose' on all archives
#
# 02 December 2000
# o        Added -force to all file delete references
#

lappend auto_path       /root/arch/scripts/tcl_packages
package require         misc
package require         parval

###\\\
# Globals --->
###///

set SELF                "backup.tcl"
set tarcmd              ""
set modFileSys          ""
set state               flag
set listedIncremental   ""
set lst_commargs {
    user host device label filesys currentRule buffer rsh incReset verbose listFileDir
}
foreach var $lst_commargs {set $var ""}

###\\\
# Function definitions --->
###///

proc synopsis_show {} {
    global SELF G_SYNOPSIS

    puts "$G_SYNOPSIS"

}

proc error_exit {action errorMessage code} {
#
# ARGS
# action                in                action being attempted
# message               in                message text
# code                  in                system exit code
#
# DESC
# Simple display of error message and exit
#
    global SELF

    puts stderr "\n$SELF:\n\tSorry, but there seems to be an error."
    puts stderr "\tWhile $action,"                                     
    puts stderr "\t$errorMessage\n"                                           
    synopsis_show
    puts stderr "\n\n\t -- Exiting with code $code -- \n"
    exit $code
}

###\\\
# main --->
###///

# Parse command line arguments, defining internal script variables

set arr_PARVAL(0) 0
PARVAL_build commswitch $argv "--" "1"
foreach element $lst_commargs {
    PARVAL_interpret commswitch $element
    if { $arr_PARVAL(commswitch,argnum) >= 0 } {
        set $element $arr_PARVAL(commswitch,value)
    }
}

# Check that all variables have assigned values
foreach var $lst_commargs {
    if {[set $var]==""} {
        set action "parsing command line arguments"
        set message "Not all required variables are set!"
        append message "\n\n\tPerhaps I have been called with some flags missing?"
        append message "\n\tI couldn't find a value for `$var'."
        error_exit $action $message 1
    }
}

append listFileDir "-"
append listFileDir [exec hostname]
if {![file isdirectory $listFileDir]} {file mkdir $listFileDir}
set child                        "${listFileDir}/archive.sh"

# Build the tar command
switch -- [exec uname] {
    Linux               { append tarcmd "/bin/tar " }
    FreeBSD             { append tarcmd "/usr/bin/tar " }
    Darwin              { append tarcmd "/opt/local/bin/tar " }
    default             { append tarcmd "/bin/tar " }
}
append tarcmd "--create --file - --totals --gzip "
#append tarcmd "--block-size 80 "
append tarcmd "--label "
append tarcmd "\"$label\" "
append tarcmd "--verbose "
#if {$verbose=="on"} {
#    append tarcmd "--verbose "
#}

# Define the incremental reference filename
set fullhostname                [exec hostname]
set hostname                    [split $host "."]
set host                        [lindex $hostname 0]
set forwardToBack               [exec echo $filesys | sed "s./.:.g"]
set modFileSys                  [lindex [split $label :] 0]
append modFileSys               "::$host:"
append modFileSys               $forwardToBack
set listedIncremental           ${listFileDir}/$modFileSys

if {$currentRule=="monthly"} {
    catch {[file delete -force "$listedIncremental-*"]} result
    append tarcmd "--listed-incremental \"$listedIncremental-monthly\" "
    file delete -force $listedIncremental-monthly
} else {
    if {$incReset == "yes"} {
        catch {[file delete -force "$listedIncremental-*"]} result
    }
    switch -- $currentRule {
        weekly         {set base monthly}
        daily         {set base weekly}
    }
    append tarcmd "--listed-incremental \"${listedIncremental}-${base}\""
}

append tarcmd " \"$filesys\""

# Check on the $device variable. If this does not contain "/dev"
#        then assume we are backing up to a hard drive. Change the
#        $device variable to reflect this.
set path        [split $device "/"]
set dev         [lindex $path 1]

if {$dev != "dev"} {
    set date            [exec date]
    set today           [lindex $date 0]
    set month           [lindex $date 1]
    set day             [lindex $date 2]
    set hour            [lindex $date 3]
    set year            [lindex $date 5]
    regsub -all ":" $label "_" label2
    regsub -all "/" $label2 "." label3
    append device       "/${label3}.${currentRule}.${today}.tgz"
}

# Build the child shell script that will do the actual backup
set childID [open $child w 0755]
puts $childID "#!/bin/sh"
puts $childID ""
puts $childID "# This script is automatically created by $SELF"
puts $childID "# for backup processing"
puts $childID ""
puts $childID "# Creation date [exec date]"
puts $childID "# DO NOT EDIT!"
puts $childID ""
puts $childID "$tarcmd | $rsh -l $user $host \'$buffer > \"$device\"\'" 
close $childID

# Now execute the child shell script
# The actual files that were archived (stderr) are directed to
# to ${child}.result. The directory tree is captured in dirtree
set err [catch {exec $child 2> $listedIncremental.results} dirtree]

# Some error checking
if {$err} {
    set action "executing child tar process"
    set errorMessage "An unknown error ($dirtree) occured in the backup!"
    append errorMessage "\n\tEither the `tar' or remote `buffer' process failed."
    file delete -force "$listedIncremental-*"
    error_exit $action $errorMessage 1
}

if {$currentRule=="monthly"} { 
    file copy -force $listedIncremental-monthly $listedIncremental-weekly
}

# Parse results file for bytes written

set ok [catch {exec grep bytes $listedIncremental.results} bytes] 
puts stdout $bytes
exit 0
