#
# NAME
#
#        tape_misc.tcl
#
# DESCRIPTION
#
#        Miscellaneous tape controlling routines - largely used by the 
#        backup_mgr.tcl process
#
#
# TODO
# o        Class expansions: buffer, misc tar commands
# o        Remove verbose considerations pending testing
#
# HISTORY
# 4-28-1998
# o        After a week of development and debugging, version 0.1 (alpha) is 
#        ready
#
# 5-12-1998
# o        Miscellaneous bug tracking
#
# 5-13-1998
# o        Removed `offline' command for montly backups... it seems to be 
#        problematic on alibaba - whether the drive is giving problems or 
#        alibaba's kernel is finicky I don't know. 
#        Anyway, no more offline commands after montly backup. At least
#        that way I can actually visually verify that a backup has been made.
#
# 6-24-1998
# o        Examined ways of improving error catching around tape commands - 
#        specifically if no tape is present.
#
# 6-25-1998
# o        Used working directory of class definition to specify location
#        of working files in tape_admin_init.
#
# o        Added error checking to tape_admin_close - largely redundant, but 
#        at least it's a deeper level of error checking.
#
# o        Basic backup behaviour redefined -
# 
#        Each backup operation is preceded by a `rewind' command. This 
#        allows error checking routines to ascertain whether or not a tape 
#        is actually present in the remote device.
#
#        Additionally, this implies that each backup - daily/weekly/monthly 
#        is performed on its own tape. Of course, the first daily backup 
#        after a weekly or monthly will by necessity have less incremental 
#        data than the backup for several days later, implying an 
#        inefficient use of tape space. However, this should be weighed 
#        against the ease of program operation and is considered to be a 
#        worthwhile trade-off (i.e. using many tapes for simplicity, and 
#        having each incremental increase on an own tape).
#
# o        Moved class definition from backup_mgr into this file
#
# o        Wrapped class definition into relevant method
#
# 6-29-1998
# o        Correct behaviour when target host is dead... non-fatal error 
#        should terminate host-related backups, but not the entire process.
#
# 7-1-1998
# o        Increment rollover fixed.
#        Fixed return values and end behaviour of tape_backup_manage
#
# 7-6-1998
# o        Added tape_todayRule_get
#
# 7-13-1998
# o        Began implementing code for cycling incremental records of 
#        non-monthly archive sets.
#
# 7-21-1998
# o        Added `archiveDate' to class structure. This records the date of 
#        the last successful archive for current set, and is used primarily 
#        to determine when a forced delete of an incremental record set is 
#        required. For sets that have only a daily and/or weekly backup 
#        defined, incremental backups are made relative to the first time 
#        that the set is processed. The `archiveDate' is used to determine 
#        when this `base' should be erased.
#
# 7-28-1998
# o        Added verbose flag to client backup program
#
# 01-11-1999
# o        Resurrected code.
# o        Beautify
#
# 01-13-1999
# o        Flags to backup.tcl now require two dashes ("--")
#
# 01-14-2000
# o        Changed calling arguments to backup.tcl (GNU style)
# o        Added -force to delete command in admin_init
# o        Improved error checking around tape commands
#
# 01-17-2000
# o        Added `fortune' (need full path for cron!)
#
# 01-26-2000
# o        delete tape_global(file_results) and not file_results in 
#        tape_admin_init!
# o        Changed behaviour of tape_backup_do:
#        - Dumps object after each partition backup. Each object has the
#          current volume appended to the name
#          
# 01-28-2000
# o        Fixed up incorrect name forming for each volume backup
# 
# 22 September 2004
# o         Resurrected. Again.
#        This time, began design changes for backing up to hard drive
#        as opposed to using a tape device.
#
# 05 February 2005
# o         Replaced 'buffer' with 'cat'. After upgrading kernel to 2.6.10
#        'buffer' reported write problems. Since it's a hold over from the
#        early 1990's, perhaps it's time to retire 'buffer' anyway.
#

package provide tape_misc 0.1

set tape_global(file_results) ""
set tape_global(file_status) ""

###\\\
# Pseudo class definition --->
###///

###\\\
# Class data --->
###///

proc tape_class_struct {} { 
#
# ARGS
# *void*
#
# DESC
#
# Define class structure
#
# This routine simply returns a list defining the records 
# of the tape class
#
    set classStruct {
        name 
        archiveDate
        workingDir
        currentSet 
        totalSet 
        rules 
        currentRule  
        remoteHost
        remoteUser
        remoteDevice
        remoteScriptDir
        rsh
        adminUser
        notifyTape
        notifyTar
        notifyError
        partitions
        status
        command
    }
    return $classStruct
}

###\\\
# Class methods --->
###///

proc tape_shut_down {exitcode} {
#
# ARGS
# exitcode        in        code returned to system
#
# DESC
# process shut down and exit
#
    global SELF

    puts "`$SELF' shutting down..."
    puts "Sending system exitcode of $exitcode\n"
    exit $exitcode
}

proc tape_error {class action errorCondition exitcode {type "fatal"}} {
#
# ARGS
# class                 in              tape inwhich error occurred
# action                in              action being performed when error
#                                       occurred
# errorCondition        in              error message caught
# exitcode              in              internal error number (sent to system
#                                       on shutdown)
# type                  in (opt)        error type - if "fatal" shutdown,
#                                       else continue
#
# DESC
# process error handling procedure
#
    upvar $class tape
    global ext

    catch "exec $tape(rsh) -l $tape(remoteUser) $tape(remoteHost) \
        $tape(notifyError)"
    puts "\n\n"
    if {$type=="fatal"} {puts "FATAL ERROR"} else {puts "WARNING"}
    puts "\tSorry, but there seems to be an error."
    puts "\tFor archive process `$tape(name)',"
    puts "\twhile I was $action, I sent \n\t`$tape(command)'"
    puts "\tand received an error:-\n\t`$errorCondition'"
    puts "\tat current date, [exec date]"
    set tape(status) "failed"
    class_Dump tape $tape(workingDir)/$tape(name).${ext}
    if {$type=="fatal"} {
        puts "\nExiting with internal code $exitcode"
        tape_shut_down $exitcode
    } else {
        puts "\nInternal error code is $exitcode"
        puts "Non fatal... continuing.\n"
    }
}

proc tape_do_nothing {class} {
#
# ARGS
# class                        in                tape currently being processed
#
# DESC
# Basic `nop' procedure
#
    upvar $class tape
    global today

    puts "No backup performed for $tape(name) on $today" 
}

proc tape_canDoMonthly {{when ""}} {
#
# ARGS
# when                        in (opt)        targetDate
#
# DESC
# Simply checks whether or not today's date falls within the first 
# week (7 days) of the month. Monthly backups, per design, occur during
# the first week
#
    global todayDate

    set targetDate $todayDate
    if {[set when]!=""} {set targetDate $when}
    if {$targetDate <= 7} {
        return 1
    } else { return 0 }
}

proc tape_ruleDays_find {class rule} {
#
# ARGS
# class                 in              target tape
# rule                  in              target rule
# ruleDays              returned        number of days and list of days
#                                        with target rule
#
# DESC
# Scans a class for rules of type `rule'
#
    upvar $class tape
    
    set count 0
    foreach day [weekdays_list] {
        if {$tape(rules,$day) == $rule} {
            lappend ruleDays $day
            incr count
        }
    }
    if {$count} { 
        return "$count $ruleDays"
    } else { return $count }
}

proc tape_todayRule_get {class {forceDay "void"}} {
#
# ARGS
# class                 in              target tape
# forceDay              in (opt)        today=forceDay
# todayRule             returned        backup rule
#
# DESC
# Given an input class, determine "today's" rule 
#
    upvar $class tape
    global today
    
    if {$forceDay!="void"} {
        set day $forceDay
    } else {
        set day $today
    }
    set rule [string trimleft $tape(rules,$day)] 
    return $rule
}

proc tape_tomorrowRule_get {class} {
#
# ARGS
# class                 in              target tape
# tomorrowRule          returned        backup rule
#
# DESC
# Given an input class, determine "tomorrow's" rule 
#
    upvar $class tape
    global today lst_weekdays

    set dayOrd [expr [lsearch $lst_weekdays $today]+1]
    if {$dayOrd >= [llength $lst_weekdays]} {set dayOrd 0}
    set tomorrow [lindex $lst_weekdays $dayOrd]
    set tomorrowRule $tape(rules,$tomorrow)
    set tomorrowRule [string trimleft $tomorrowRule]
    return $tomorrowRule
}

proc tape_notice_sendMail {class subject {bodyFile "void"} {bodyContents "void"}} {
#
# ARGS
# class                 in              tape being processed
# subject               in              subject of mail message
# bodyFile              in (opt)        filename containing body of message
# bodyContents          in (opt)        body string
#
#
# DESC
# Sends a mail message to a tape's adminUser
#
# A mail message containing the `subject' is sent to a target tape's 
# adminUser. If an optional bodyFile is sent, the contents of this 
# file are mailed to the adminUser as the message's body.
#
# HISTORY
# 14 July 2000
# o Changed `mail' to `mailx' for usage on SGI IRIX.
#
# 22 September 2004
# o Changed 'mailx' back to 'mail' for Linux
# 
# 04 November 2010
# o Added [pid] to tmp msg file -- address collisions on the same
#   filesystem for different backups running concurrently.
#

    set str_pid	[pid]
    set tmpfile	"/tmp/msg-$str_pid"

    upvar $class tape

    if {$bodyFile=="void" && $bodyContents=="void"} {
        exec mail -s "$subject" $tape(adminUser) < /dev/null
    } elseif {$bodyFile!="void" && $bodyContents=="void"} {
        exec mail -s "$subject" $tape(adminUser) < $bodyFile
    } elseif {$bodyContents!="void"} {
        set ok [catch {exec echo $bodyContents >$tmpfile} commline]
        exec mail -s "$subject" $tape(adminUser) < $tmpfile 
        file delete -force $tmpfile
    }
}

proc tape_admin_init {class} {
#
# ARGS
# class         in              tape archive about to be processed
#
# DESC
# Perform initial admin operations for a backup tape set
#
# Before implementing a backup, some general admin functions are 
# performed, specifically the deletion of files containing old backup 
# status and info. New empty files are created which will contain result 
# and status information
#
# The proper data path for the working directory is read from class 
# definition
#
#
    upvar $class tape
    global tape_global

    set file_results $tape(name).$tape(currentRule).$tape(currentSet,$tape(currentRule)).results.log
    set tape_global(file_results) $tape(workingDir)/$file_results
    file delete -force $tape_global(file_results)
    set file_status $tape(name).$tape(currentRule).$tape(currentSet,$tape(currentRule)).status.log
    set tape_global(file_status) $tape(workingDir)/$file_status
    file delete -force $tape_global(file_status)
}

proc tape_admin_close {class volume label results} {
#
# ARGS
# class         in              tape being processed
# volume        in              current partition that has been
#                                       backed up
# label         in              name of current archive
# results       in              the path/filenames that have been
#                                       backed up
#
# DESC
# Perform closing admin for each successfully backup up tape set.
#
# The results of an archive process (the path/files that are returned 
# from the remote backup.tcl process) are written to a results file. 
# Additionally, these results are parsed and some status information 
# is also extracted and written to a status file. 
# 
# The error checking on the $results string is somewhat redundant... if 
# validResults != -1 then validStatus is per definition == -1 as well.
#
#
    upvar $class tape
    global tape_global
    global AM_parseResults AM_parseStatus
    global EC_parseResults EC_parseStatus

    set tape(status) "ok"
    puts "ok.\n"
    puts "Backup of $volume complete."
    puts "End date: [exec date]\n"
    set fileResults [open $tape_global(file_results) a]
    # Check for valid results
    set validResults [lsearch $results "killed:"]
    if {$validResults != -1} {
        set tape(status) "failed"
        tape_error tape $AM_parseResults \
                "Remote backup process was killed!" $EC_parseResults fatal
    }
    puts $fileResults "$results"
    set fileStatus [open $tape_global(file_status) a]
    # Check for valid status
    set validStatus [lsearch $results bytes]
    if {$validStatus == -1} {
        set tape(status) "failed"
        tape_error tape $AM_parseStatus \
                "No `bytes' string found" $EC_parseStatus fatal
    }
    set bytesWritten [lindex $results [expr [lsearch $results bytes]+2]]
    puts $fileStatus "Archive status for backup `$label':"
    puts $fileStatus "\tResults parsed at [exec date]"
    puts $fileStatus "\tTotal bytes written: $bytesWritten\n"
    close $fileResults
    close $fileStatus
}

proc tape_currentSet_inc {class} {
#
# ARGS
# class         in                target tape
#
# DESC
# Increment the current rule's set number for class with implied rollover.
#
# Note: The first number in a set is 0 not 1!
#
#
    upvar $class tape

    incr tape(currentSet,$tape(currentRule))
    if {$tape(currentSet,$tape(currentRule))>[expr $tape(totalSet,$tape(currentRule)) -1]} {
        set tape(currentSet,$tape(currentRule)) 0
    }
}

proc tape_control {class command} {
#
# ARGS
# class         in              current tape being processed
# command       in              command sent to tape control program
#                                       `mt'
# status        returned        boolean status of executed command
#
# DESC
# Wrapper built around the tape controller.
#
# This routine controls the actual tape access from the manager process.
# Typically this would include management operations such as `rewind',
# `offline', etc. The actual backup to the tape and corresponding access
# is implemented in the remote program `backup.tcl' which is called by
# this manager process. On being called, the `notifyTape' field of the 
# target class is executed on the class's remote host.
# 
# Rudimentary error checking is performed on the status of the executed
# command, and an `ok' flag is returned
#
# HISTORY
# 22 September 2004
# o Added check on $remoteDevice. If not 'dev' then assume we are backing
#   up to hard drive. In that case, replace the 'mt' command with a simple
#   'echo'.
#
#
    upvar $class tape
    global AM_remoteDevice EC_remoteDevice
    
    set tape(command) $command
    set MT "mt"
    puts -nonewline "\nTape: $tape(command)... "
    flush stdout

    catch "exec $tape(rsh) -l $tape(remoteUser) $tape(remoteHost) \
        $tape(notifyTape)" notifyResult
        
    # Check on the remoteDevice. If this is /dev/something we can assume that
    #        it is a tape device. If not, then assume we are backing up to hard
    #        drive. Replace the MT with "echo"
    set path        [split $tape(remoteDevice) "/"]
    set dev         [lindex $path 1]
    if {$dev != "dev"} {
            set MT "echo"
    }
    
#     puts "exec $tape(rsh) -l $tape(remoteUser) $tape(remoteHost) $MT -f $tape(remoteDevice) \
#         $tape(command)" 

    set err [catch "exec $tape(rsh) -l $tape(remoteUser) $tape(remoteHost) $MT -f $tape(remoteDevice) \
        $tape(command)" result ]

    if {$err} {
        set status "failed"
        puts "$err ${status}. :-("
        tape_error tape $AM_remoteDevice $result $EC_remoteDevice
    } else {
        set status "ok"
        puts "${status}."
    }
    
    return $status
}

proc tape_incReset {class date {silent "void"}} {
# 
# ARGS
# class         in              current tape being processed
# date          in              target date
# silent        in (opt)        optional verbose flag. If set, don't
#                                       echo output
# incReset      returned        "yes | no" depending on date conditions
#
# DESC
# Determines whether or not an incremental is required for tape
# on date `date' - only relevant to tape sets that have no
# monthly backup defined.
# 
#
    upvar $class tape

    set monthlyDays [tape_ruleDays_find tape monthly]
    set incReset "no"
    if {![lindex $monthlyDays 0]} {
        if {$silent=="void"} {
            puts "\nNo monthly backup rule found in set `$tape(name)'"
        }
        set lastArchive $tape(archiveDate)
        set lastMonth [lindex $lastArchive 1]
        set thisMonth [lindex $date 1]
        if {$lastMonth!=$thisMonth} {
            if {$silent=="void"} {
                puts "Forcing incremental reset"
            }
            set incReset "yes" 
        } else {
            if {$silent=="void"} {
                puts "No incremental reset required"
            }
            set incReset "no"
        }
        puts ""
    }
    return $incReset
}

proc tape_label_create {class volumeName {maxLength 80}} {
#
# ARGS
# class         in              current tape being processed
# volumeName    in              label pathname
# label         returned        tape label
#
# DESC
# Constructs the label name for a volume archive. Note that there is
# length limit for the tar command. This proc creates a tar-friendly
# label.
#
#
    upvar $class tape
    global date tape_global ext

    set month   [lindex $date 1]
    set day     [lindex $date 2]
    set year    [lindex $date 5]
    set host    [lindex [split $volumeName ":"] 0]
    set filesys [lindex [split $volumeName ":"] 1]

    set label "$tape(name)::${host}:${filesys}-$tape(currentRule)"
    
    # If label is too long, hack a shorter one...
    if {[string length $label] > $maxLength} {
        puts "Volume label name is too long! Creating a shorter name."
        set ldir [split $filesys "/"]
        set basename [lindex $ldir [expr [llength $ldir] - 1]]
        set label "$tape(name)::${host}:${basename}-$tape(currentRule)"
    }
    append label "-${month}.${day}.${year}"
    return $label
}

proc tape_backup_do {class} {
#
# ARGS
# class         in              current tape being processed
# backup_done   returned        status of backup set. If `1' all
#                               backups in current set completed
#                               successfully. If `0', one backup in
#                               current set failed (typically if
#                               remote host did not respond)
#                               and subsequent backups of set suspended.
#
# DESC
# Builds the arguments that are sent to the remote process that actually 
# performs the tape backup
#
#
    upvar $class tape
    global AM_pingHost AM_rsh 
    global EC_pingHost EC_rsh 
    global date tape_global ext

    set month [lindex $date 1]
    set day [lindex $date 2]
    set year [lindex $date 5]
    # Assume the backup will proceed without error unless proven wrong!
    set backup_done 1
    set partitions [split $tape(partitions) ","]
    set incReset [tape_incReset tape $date]
    tape_admin_init tape 
    foreach volume $partitions {
        set host [lindex [split $volume ":"] 0]
        set filesys [lindex [split $volume ":"] 1]
        set tape(command) "ping -c 3 $host"
        puts -nonewline "\nChecking if $host is alive... "
        flush stdout
        set dead [catch {eval exec $tape(command)} result]
        if {$dead} {
            tape_error tape $AM_pingHost $result $EC_pingHost warn
            # set backup_done 0
            # break
        }
        puts "ok."
        set label "$tape(name)::${host}:${filesys}-$tape(currentRule)"
        append label "-${month}.${day}.${year}"
        set label [tape_label_create $class $volume]
        puts "Starting $tape(currentRule) backup of $volume..."
        puts "Start date: [exec date]"
        puts -nonewline "\n\t$label - "
        set tape(command) "$tape(rsh) $host "
        append tape(command) "$tape(remoteScriptDir)/backup.tcl "
        append tape(command) "--user $tape(remoteUser) "
        append tape(command) "--host $tape(remoteHost) "
        append tape(command) "--device $tape(remoteDevice) "
        append tape(command) "--label \"$label\" "
        append tape(command) "--listFileDir $tape(listFileDir) "
        append tape(command) "--filesys \"$filesys\" "
        append tape(command) "--currentRule $tape(currentRule) "
        append tape(command) "--buffer  cat "
        append tape(command) "--rsh $tape(rsh) "
        append tape(command) "--incReset $incReset "
        if {$tape(currentRule) != "monthly"} {
            append tape(command) "--verbose on" 
        } else {
            append tape(command) "--verbose off"
        }

        # Audio notification of backup start
        catch "exec $tape(rsh) -l $tape(remoteUser) $tape(remoteHost) \
                eval $tape(notifyTar)" notifyResult
        # Start the backup
        set someError [catch {eval exec "$tape(command)"} results]
        if {$someError} {
            tape_error tape $AM_rsh $results $EC_rsh
            set backup_done 0
        } else { tape_admin_close tape $volume $label $results }
        if {!$dead && !$someError} {
            set tape(archiveDate) [exec date]
            set volname [exec echo $volume | sed "s./.:.g"]
            # The following "Dump" is for debugging purposes
            #class_Dump tape $tape(workingDir)/$tape(name).${volname}.${ext}
        }
    }
    if {!$dead && !$someError} {
        tape_currentSet_inc tape
        puts "Sending status mail to $tape(adminUser)"
        tape_notice_sendMail tape "Backup status for tape -$tape(name)-" $tape_global(file_status)
    }
    return $backup_done
}

proc tape_backup_manage {class {forceRule "void"} {forceDay "void"} {tapeInit "void"}} {
#
# ARGS
# class         in              current tape being processed
# forceRule     in (opt)        contains a rule type, forcing
#                                       operation to default to forceRule
# forceDay      in (opt)        contains a day name, forcing operation
#                                       to default to forceDay's rule
# tapeInit      in (opt)        list of tape initialisation commands
#                                       (e.g. rewind)
#
# DESC
# Entry point to main tape processes.
#
# General manager - directs program flow depending on tape's
# current backup rule.
#
#
    upvar $class tape
    global today lst_weekdays todayDate

    if {$forceDay!="void"} {set today $forceDay}
    set tape(currentRule) [string trimleft $tape(rules,$today)]
    set backup_status 1
    if {$forceRule!="void"} {set tape(currentRule) $forceRule}
    if {$tape(currentRule) != "none"} {
        switch -- $tape(currentRule) {
            monthly { 
                if {[tape_canDoMonthly] || $forceRule=="monthly"} {
                    puts "Performing monthly backup for `$tape(name)' on $today"
                    tape_control tape rewind
                    set backup_status [tape_backup_do tape]
                    tape_control tape offline
                } else {tape_do_nothing tape}
            }
            weekly {
                puts "Performing weekly backup for `$tape(name)' on $today"
                if {$tapeInit!="void"} {
                    puts "Performing tape initialisation."
                    foreach command $tapeInit {
                        tape_control tape $command
                    }
                }
                tape_control tape rewind
                set backup_status [tape_backup_do tape]
                tape_control tape offline
            }
            daily {
                puts "Performing daily backup for `$tape(name)' on $today"
                # Deterimine if $today is the first daily backup of the week
                class_get dailyRules tape rules
                set firstDay [lsearch [list_order dailyRules $lst_weekdays] daily]
                set firstDay [lindex $lst_weekdays $firstDay]
                if {$tapeInit!="void"} {
                    puts "Performing tape initialisation."
                    foreach command $tapeInit {
                        tape_control tape $command
                    }
                }
                tape_control tape rewind
                set backup_status [tape_backup_do tape]
                tape_control tape offline
            }
            default {
                tape_do_nothing tape
            }
        }
        # Check status of backup
        if {$backup_status == 1} {
            puts "Archive of set `$tape(name)' completed successfully."
        } else {
            puts "Archive of set `$tape(name)' encountered an error."
            puts "Some hosts may not have been backed up! Check log files."
        }
    } else { tape_do_nothing tape }

    # Now determine tomorrow's rule for this tapeset
    set tomorrowRule [tape_tomorrowRule_get tape]
    if {($tomorrowRule=="monthly") && !([tape_canDoMonthly [expr $todayDate+1]])} {
        return $backup_status
    }
    if {$tomorrowRule!="none"} {
        set message "Insert -$tape(name)- $tomorrowRule tape no. "
        switch -- [exec uname] {
            Linux   { set tomorrowDate [exec date --date "1 day"] }
            FreeBSD { set tomorrowDate [exec date -v+1d] }
            Darwin  { set tomorrowDate [exec date -v+1d] }
            default { set tomorrowDate [exec date --date "1 day"] }
        }
        if {[tape_incReset tape $tomorrowDate silent]=="yes"} {
            append message "$tape(totalSet,$tomorrowRule) (inc reset tape)"
        } else {append message "$tape(currentSet,$tomorrowRule)"}
        puts "\nSending notification to $tape(adminUser)..."
        puts "********************\n"
        tape_notice_sendMail tape "$message" "void" [exec /opt/local/bin/fortune]
    }
    return $backup_status
}
