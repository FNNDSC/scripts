#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 

Gb_showErr                      = 1
Gb_silent                       = 0
Gstr_fileName                   = ""
Gstr_tagStartString             = ""
Gstr_tagStopString              = ""
Gb_tagStopStringSpecified       = False
G_skipLines                     = -1

Gstr_synopsis 	= """

  NAME
       
      blockFilter.py
 
  SYNPOSIS

      blockFilter.py -f <fileName> -s <tagStartString> -k <skipLines>   \
                                   -u <tagStopString>

  DESC

      'blockFilter.py' filters the contents of <filename>. It does this
      by filtering out the line containing <tagString> as well as skipping
      the following <skipLines>.
          
  ARGS

      -f <fileName>
      The input file to filter.

      -s <tagString>
      A string that tags the line on which to start applying the filter.
      
      -k <skipLines>
      The number of lines (in addition to the <tagString> line) to skip.

      -u <tagStopString>
      A string that tags the line on which to stop applying the filter. If
      specified will override <skipLines>.

  EXAMPLE
      Typical example:

        $>blockFilter.py -f output.log -t Unknown -k 16

      will remove from <output.log> any lines containing the string
      "Unknown" as well the 16 lines *after* this line.
		
  PRECONDITIONS

        o Valid input file.
        
  POSTCONDITIONS

	o Filtered file is dumped to stdout
	
  HISTORY

  22 April 2011
  o Initial development implementation.

"""

import 	os
import	sys
import	getopt
import  string
import  systemMisc      as misc

dictErr = {
    'NoArgs'            : {
        'action'        : 'checking the command line arguments, ', 
        'error'         : 'no options specified!', 
        'exitCode'      : 10},
    'fileName'          : {
        'action'        : 'checking the -f <filename>, ',
        'error'         : 'the <filename> was not specified!',
        'exitCode'      : 11},
    'fileAccess'          : {
        'action'        : 'opening the <filename>, ',
        'error'         : 'an access error occurred!',
        'exitCode'      : 17},
    'tagStartString'         : {
        'action'        : 'checking the -s <tagStartString>, ',
        'error'         : 'the <tagString> was not specified!',
        'exitCode'      : 11},
    'skipLines'         : {
        'action'        : 'checking the -k <skipLines>, ',
        'error'         : 'the <skipLines> was not specified!',
        'exitCode'      : 11},
    'tagStopString'     : {
        'action'        : 'checking the -s <tagStopString>, ',
        'error'         : 'the <tagStopString> was not specified!',
        'exitCode'      : 11},
    'skiptagStopString' : {
        'action'        : 'checking the command line arguments, ',
        'error'         : 'you must specify one of "-k <skipLines>" or "-u <tagStopString>"',
        'exitCode'      : 11},
    'workingDir'        : {
        'action'        : 'checking on the working directory, ',
        'error'         : 'it seems that an invalid dirSpec was given.',
        'exitCode'      : 12},
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
    opts, remargs   = getopt.getopt(sys.argv[1:], 'f:s:k:u:')
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
    if (o == '-k'):
        G_skipLines                     = int(a)

if len(sys.argv) == 1: fatal('NoArgs')
if not len(Gstr_fileName): fatal('fileName')
if not len(Gstr_tagStartString): fatal('tagStartString')
if G_skipLines == -1 and not len(Gstr_tagStopString): fatal('skiptagStopString')

try:
    FILE_input = open(Gstr_fileName)
except IOError:
    fatal('fileAccess')

b_safe          = True
skipCount       = 0
for line in FILE_input:
    line        = line.strip()
    #print "%s" % line.strip()
    if contains(line, Gstr_tagStartString):
       b_safe   = False
    if b_safe: print line
    else:
        skipCount += 1
    if skipCount > G_skipLines and G_skipLines != -1:
        b_safe          = True;
        skipCount       = 0
    if contains(line, Gstr_tagStopString) and Gb_tagStopStringSpecified:
        b_safe          = True;

FILE_input.close()

sys.exit(0)
