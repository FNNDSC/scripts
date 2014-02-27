#!/bin/sh 
# the next line  restart with wish \
 exec tclsh "$0" $@

set G_SYNOPSIS "

NAME

      backup_mgr.tcl

SYNOPSIS

      backup_mgr.tcl          \[--archive <archive_set>]                \\
                              \[--backupRootDir <backupRootDir>]        \\
                              \[--tapeInit <option_init_tape_command>]  \\
                              \[--rule <force_rule>]                    \\
                              \[--init <self|filesystem>]               \\
                              \[--day <forceDay>]                       \\
                              \[--Reset]                                \\
                              \[--usage]

DESCRIPTION

        `backup_mgr.tcl' is the main backup manager. It creates and
        maintains the backup archive objects, schedules the backup
        types, stores state information to disk, etc.

        The command line arguments are almost always used only for
        debugging/testing and allow the calling process (or user)
        to override backup_mgr's default behaviour.

ARGS

    o --archive <archive_set>
            This can force backup_mgr to concentrate on a
            specific archive, and ignore whatever it initialized
            itself with. Note that at this stage, only ONE
            archive_set name will be interpreted.
    o --backupRootDir <backupRootDir>
             This specifies the root directory containing the 
             backup data folder, backup_lists, and object
             configuration files.
    o --tapeInit <option_init_tape_command>
             Any optional tape commands can be specified. These
             will be executed *before* any of the backups begin.
             Again, note that the only real command that I had
             in mind was `rewind'. Complex init sequences with
             white space won't work!
    o --rule <force_rule>
             Force backup_mgr to use rule <force_rule> irrespective
             of what should have been scheduled.
    o --day <forceDay>
             Force backup_mgr to use the ruleset for day <forceDay>.
    o --init <self|filesystem>
            Initialize tape objects (rules, priorities, hosts, etc)
            either from a stored state on disk, or recreate from
            scratch (usually encoded within this script).
    o --Reset
            Similar to above, with implicit self initialization.
            Once setup, processing will terminate without performing
            the backup.
    o --usage
            This synopsis.
#
"
# TODO
#
# (Short term)
# o        Ability to pass additional parameters to tar command
# o        More error checking
# o        State and infrastructure testing
# o        Separate configuration information
#
# o        Check `archiveDate'
# o        Check 'status'
#
# o        `nop' override in class - for overriding a scheduled cron
#        job without needing to acutally remove it.
#
# (Long term)
# o        Higher dimension array construction (i.e. > 2)
# o        Socket communication between different processes for status 
#        information?
# o        Ordering of tape archives in order of daily, weekly, monthly - 
#        thus if a daily is scheduled on the same day using the same 
#        device as the weekly/monthly, the daily will backup first, then 
#        the weekly will rewind and backup, and then the monthly will 
#        rewind and backup. Basically just to place preference on 
#        collision days.
#
# HISTORY
#
# End April 1998
# o        Initial design, testing, debugging
# o        Split into separate module components
#
# 5-11-1998
# o        Added command line interpretation -
#        allows for process to be run on specific tape set
#        with a given rule. Note that rule is forced on each
#        element of command line set.
#
# 5-14-1998
# o        General cron-related problems... cron launched apps do not
#        have shell variables set - i.e. no path!
#
# 5-15-1998
# o        Added `totalBackups' parameter to class definition. This keeps
#        track of the total number of backups per set, allowing subsequent
#        backups to fsf appropriately
#
# 6-25-1998
# o        Crontab behaviour is still not optimal. Eventhough the process is 
#        called in cron from the target directory, i.e. 
#        /root/backup/backup_mgr.tcl, the process dumps its working files 
#        to /root/backup. Apparently cron runs scheduled tasks from the 
#        owner's home directory.
#        
#        The best solution is to specify working directory and path 
#        in backup_mgr.tcl
#
# o        Working directory data path added to basic class definition
#
# 7-6-1998
# o        Sorted archive list. Lower priority archives are scheduled first, 
#        with important archives last. Priority is defined as the current 
#        rule: `none' has least priority, with `daily' more priority 
#        scaling all the way to `monthly' with the most. This addresses 
#        the problem where on a particular day one archive might have a 
#        `daily' backup scheduled, and another a `monthly'. If both 
#        archives use the same remote device, i.e. device clash, the lower 
#        priority will occur first, and then when the higher priority 
#        backup runs, it will in effect overwrite the earlier process's 
#        backup.
#
# 7-21-1998
# o        Added `date' value to class structure
#
# 1-10-2000
# o        Resurrected and began integration into new env.
#        Initial focus is on getting existing code up and running again
#        without worrying about possible redesign.
#
# 1-15-2000
# o     Testing full run!
#
# 1-20-2000
# o        Changed tape device back to nst
#
# 22 September 2004
# o        Resurrected! For the second time.
#        Made changes to reflect mgh environment
#
# January 2010
# o     CHB deployment
# o     Spec for backupRootDir
# 


###\\\
# NB NB
# The following need to be defined for a given backup system!!
###///
# The path containing the support tcl files.
lappend auto_path       /neuro/arch/scripts/tcl_packages
# The <dataPath> is the backupRootDir and contains the config files for
# a backup, as well as the actual backup tgz files for each config.
set dataPath            "/neuro/users/rudolphpienaar/backup"
# The <lst_archive> contains the names (filenames) of each backup archive
set lst_archive        {fnndsc-etc fnndsc-localUsers scanner-oc-backup fnndsc-wiki}

###\\\
###|||
###||| You shouldn't need to change anything below here!
###|||
###///


###\\\
# include --->
###///
package require         class_struct        
package require         misc                
package require         tape_misc        
package require         parval                

###\\\
# globals --->
###///

set SELF                "backup_mgr.tcl"
set ext                 "object"
set lst_base_struct     [tape_class_struct]
set delim               ">"

# Actions
set AM_remoteDevice     "communicating with remote device"
set AM_pingHost         "pinging remote host"
set AM_rsh              "attempting to rsh"
set AM_parseResults     "parsing results file"
set AM_parseStatus      "parsing status file"
set AM_backup           "performing the backup"

# Error messages
set EM_remoteDevice     "I could not contact the remote device"
set EM_pingHost         "I could not ping host"
set EM_rsh              "I could not seem to remotely log in"
set EM_parseResults     "I could not parse the results of the backup"
set EM_parseStatus      "I could not parse the status of the backup"
set EM_backup           "The backup seems to have failed"

# Error codes
set EC_remoteDevice     1
set EC_pingHost         2
set EC_rsh              3
set EC_parseResults     4
set EC_parseStatus      5
set EC_backup           6

# Week day index
set lst_weekdays        [weekdays_list]

#
# Types of backup operation (the order in action lists is important!)
#
#        o `monthly'            full (non incremental) backup
#        o `weekly'             weekly incremental
#                               - referenced to most recent monthly
#        o `daily'              daily  incremental
#                               - referenced to most recent weekly
#
set lst_actions                {monthly weekly daily none}
set lst_actionsPriority        {none daily weekly monthly}

#
# The actual archives.
#        o Each archive *must* have a set of rules (defined below)
#
#set lst_archive                 {fnndsc-etc fnndsc-localUsers fnndsc-chb}


###\\\
# Function definitions --->
###///

proc synopsis_show {} {
    global SELF G_SYNOPSIS
    set base "none"

    puts "$G_SYNOPSIS"

    shutdown 0
}

proc shutdown {exitcode} {
#
# exitcode        in        code returned to system
#
# process shut down and exit
#
    global SELF

    puts "\n'$SELF' shutting down..."
    puts "\tSending system exitcode of $exitcode\n"
    exit $exitcode
}

###\\\
# main --->
###/// 
set date                [exec date]
set today               [lindex $date 0]
set todayDate           [lindex $date 2]

set day                 $today
set archive             "void"
set rule                "void"
set init                "filesystem"
set tapeInit            "void"
set Reset               0
set usage               0

set lst_commargs        {archive rule init tapeInit usage Reset day backupRootDir}
set arr_PARVAL(0) 0
PARVAL_build commswitch $argv "--"
foreach element $lst_commargs {
    PARVAL_interpret commswitch $element
    if { $arr_PARVAL(commswitch,argnum) >= 0 } {
        set $element $arr_PARVAL(commswitch,value)
    }
}

if ![catch {set backupRootDir}] {
  set dataPath $backupRootDir
} 

if {$usage} {synopsis_show}

if {$archive != "void" } {
    set lst_archive $archive
}

if {$init == "self" || $Reset} {
    foreach tape $lst_archive {
        class_Initialise arr_${tape}_currentSet lst_actions lst_${tape}_currentSet
        class_Initialise arr_${tape}_totalSet   lst_actions lst_${tape}_totalSet
        class_Initialise arr_${tape}_rules      lst_weekdays lst_rules_$tape
        # Initialise the class according to the class definition structure
        class_Initialise arr_${tape} lst_base_struct    \ 
                "$tape                                  \ 
                {$date}                                 \
                $dataPath                               \
                arr_${tape}_currentSet                  \ 
                arr_${tape}_totalSet                    \
                arr_${tape}_rules                       \
                none                                    \ 
                $remoteHost                             \
                $remoteUser                             \ 
                $remoteDevice                           \
                $rsh $adminUser                         \
                {$notifyTape}                           \
                {$notifyTar}                            \
                {$notifyError}                          \
                ptr_${tape}_partition                   \
                {}                                      \
                {} "
        class_Dump arr_${tape} ${dataPath}/${tape}.${ext}
    }
} else {
    foreach tape $lst_archive {
        class_Initialise arr_${tape} lst_base_struct {} ${dataPath}/${tape}.${ext}
    }
}

if {$Reset} {shutdown 0}

# Sort the archives according to priority
foreach action $lst_actionsPriority {
    foreach tape $lst_archive {
        if {[tape_todayRule_get arr_$tape $day] == "$action"} {
            lappend lst_sorted_archive $tape
        }
    }
}

puts "$SELF"
puts "\tUnordered list of archives:\t$lst_archive"
puts "\tProcessing archives in order:\t$lst_sorted_archive\n"

#foreach today $lst_weekdays {
#    puts ""
    foreach tape $lst_sorted_archive {
        set ok [tape_backup_manage arr_${tape} $rule $day $tapeInit]
        if {$ok} {
            puts stdout "Status ok. Dumping $tape object to file."
            class_Dump arr_${tape} ${dataPath}/${tape}.${ext}
        }
    }
#}

if {$ok == 1}  {
    shutdown 0
} else {
    puts "WARNING"
    puts "\tSome internal error was sent back to main controlling process."
    shutdown 1
}

