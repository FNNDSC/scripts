# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

package ifneeded class_struct 0.1 [list tclPkgSetup $dir class_struct 0.1 {{class_struct.tcl source {array_associate class_Dump class_Initialise class_get list_order}}}]
package ifneeded misc 0.1 [list tclPkgSetup $dir misc 0.1 {{misc.tcl source {clint deref weekdays_list}}}]
package ifneeded parval 0.1 [list tclPkgSetup $dir parval 0.1 {{parval.tcl source {PARVAL_build PARVAL_interpret PARVAL_nullify PARVAL_print}}}]
package ifneeded tape_misc 0.1 [list tclPkgSetup $dir tape_misc 0.1 {{tape_misc.tcl source {tape_admin_close tape_admin_init tape_backup_do tape_backup_manage tape_canDoMonthly tape_class_struct tape_control tape_currentSet_inc tape_do_nothing tape_error tape_incReset tape_notice_sendMail tape_ruleDays_find tape_shut_down tape_todayRule_get tape_tomorrowRule_get}}}]
