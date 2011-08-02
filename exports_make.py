#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 


Gb_showErr                      = 1
Gb_silent                       = 0
Gstr_style                      = "Linux"

Gstr_synopsis 	= """

  NAME

        exports_make.py

  SYNOPSIS

        exports_make.pys --style <'Darwin'|'Linux'> [-v <verbosityLevel>]
                          <DIR1> <DIR2> ... <DIRn>

  DESC

        'exports_make.bash' generates and prints to stdout an exports
        file for either Darwin or Linux, exporting the <DIR> <DIR2>...
        to all the remote subnets that subserve the FNNDSC.

  ARGS

        -v <verbosityLevel> (Optional)
        Verbosity level. A value of '10' is a good choice here.

        -s <'Darwin'|'Linux'>
        Style of /etc/exports to use.

  HISTORY

  26 April 2011
  o Initial design and coding.
"""

import 	os
import	sys
import	getopt
import  string
import  argparse
import  systemMisc      as misc

dictErr = {
    'NoArgs'            : {
        'action'        : 'checking the command line arguments, ', 
        'error'         : 'no options specified!', 
        'exitCode'      : 10},
    'BadStyle'          : {
        'action'        : 'checking the "-s" argument, ',
        'error'         : 'style should be either "-s Linux" or "-s Darwin".',
        'exitCode'      : 10},
    'NoHits'            : {
        'action'        : 'evaluating <findRegEx>, ',
        'error'         : 'no grids were found.',
        'exitCode'      : 13}
}

Gstr_SELF       = sys.argv[0]

def synopsis_show():
    print "%s" % Gstr_synopsis

def error_exit(astr_key, ab_exitToOS=1):
    if Gb_showErr:
        print >>sys.stderr
        print >>sys.stderr, Gstr_SELF
        print >>sys.stderr, "\n"
        print >>sys.stderr, "\tSorry, but some error occurred."
        print >>sys.stderr, "\tWhile " + dictErr[astr_key]['action']
        print >>sys.stderr, "\t" + dictErr[astr_key]['error']
        print >>sys.stderr, "\n"
        print >>sys.stderr, "Exiting to system with code %d.\n" % dictErr[astr_key]['exitCode']
    if ab_exitToOS:
        sys.exit(dictErr[astr_key]['exitCode'])

def fatal(astr_key, astr_extraMsg=""):
    if len(astr_extraMsg): print astr_extraMsg
    error_exit( astr_key)

def warn(astr_key, astr_extraMsg=""):
    b_exitToOS  = 0
    if len(astr_extraMsg): print astr_extraMsg
    error_exit( astr_key, b_exitToOS)

def contains(theString, theQueryValue):
    return theString.find(theQueryValue) > -1

try:
    opts, remargs   = getopt.getopt(sys.argv[1:], 'f:s:u:S:C:')
except getopt.GetoptError:
    synopsis_show()
    sys.exit(1)

for o, a in opts:
    if (o == '-s'):
        Gstr_tagStartString             = a
    if (o == '-u'):
        Gstr_tagStopString              = a
        Gb_tagStopStringSpecified       = True
    if (o == '-f'):
        Gstr_fileName                   = a
    if (o == '-C'):
        G_columnLine                    = int(a)
    if (o == '-S'):
        Gstr_tagSortString              = a

if len(sys.argv) == 1: fatal('NoArgs')
if not len(Gstr_fileName): fatal('fileName')
if not len(Gstr_tagStartString): fatal('tagStartString')
if not len(Gstr_tagStopString): fatal('tagStopString')
if not len(Gstr_tagSortString): fatal('tagSortString')
if G_columnLine <=0: fatal('columnInLine')

try:
    FILE_input = open(Gstr_fileName)
except IOError:
    fatal('fileInputAccess')


# Delete any previous sorts...
misc.system_pipeRet('rm %s.* 2>/dev/null' % Gstr_fileName)

arrstr_window           = []
dictFILE_output         = {}
Gstr_sortExt            = ""
b_sort                  = False
for line in FILE_input:
    line        = line.strip()
    if contains(line, Gstr_tagStartString):
       b_sort   = True
    if b_sort:
        arrstr_window.append(line)
        if contains(line, Gstr_tagSortString):
            lstr        = line.split()
            str_sort    = lstr[G_columnLine-1]
            str_sortExt = str_sort.strip('[]')
    if contains(line, Gstr_tagStopString):
        b_sort          = False
        if not len(str_sortExt): fatal('sortExt')
        str_outputFileName = '%s.%s' % (Gstr_fileName, str_sortExt)
        if str_outputFileName not in dictFILE_output.keys():
            try:
                dictFILE_output[str_outputFileName] = open(str_outputFileName, 'w')
            except IOError:
                fatal('fileOutputAccess', 'Output file = %s' % str_outputFileName);
        for line in arrstr_window:
            dictFILE_output[str_outputFileName].write('%s\n' % line)
        arrstr_window     = []

FILE_input.close()
for str_file in dictFILE_output.keys():
    dictFILE_output[str_file].close()
    
sys.exit(0)
