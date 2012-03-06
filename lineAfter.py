#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 

#import systemMisc as misc
from _common import systemMisc as misc

Gb_showErr                      = 1
Gb_silent                       = 0
Gstr_fileName                   = ""
Gstr_tagHoldString              = ""
Gstr_tagAfterString             = ""

Gstr_synopsis 	= """

  NAME
       
      lineAfter.py
 
  SYNPOSIS

      lineAfter.py -f <fileName> -s <tagHoldString> -u <tagAfterString>

  DESC

      'lineAfter.py' reorders pairs of lines in <fileName>. It essentially
      moves a line containing <tagHoldString> to appear directly after
      <tagAfterString>.
          
  ARGS

      -f <fileName>
      The input file to sort.

      -s <tagHoldString>
      A string that tags the line to delay.
      
      -u <tagAfterString>
      A string that tags the line after which the <holdString> should
      appear.
            		
  PRECONDITIONS

        o Valid input file.
        o Text blocks are not interleaved.
        o <tagHoldString> should appear before <tagAfterString>.
        
  POSTCONDITIONS

	o All lines corresponding to <tagHoldString> are delayed to
          appear after the next <tagAfterString>.
	
  EXAMPLE
      Typical example:

        $>lineAfter.py -f DICOMseries.std -s StudyInstance -u SeriesInstance

      will print lines containing "StudyInstance" after lines containing
      "SeriesInstance". 

  HISTORY

  22 April 2011
  o Initial development implementation.

"""

import 	os
import	sys
import	getopt
import  string
#import  systemMisc      as misc

dictErr = {
    'NoArgs'            : {
        'action'        : 'checking the command line arguments, ', 
        'error'         : 'no options specified!', 
        'exitCode'      : 10},
    'fileName'          : {
        'action'        : 'checking the -f <fileName>, ',
        'error'         : 'the <fileName> was not specified!',
        'exitCode'      : 11},
    'fileInputAccess'   : {
        'action'        : 'opening the input <fileName>, ',
        'error'         : 'an access error occurred!',
        'exitCode'      : 17},
    'fileOutputAccess'  : {
        'action'        : 'opening the output <fileName>, ',
        'error'         : 'an access error occurred!',
        'exitCode'      : 17},
    'tagHoldString'      : {
        'action'        : 'checking the -s <tagHoldString>, ',
        'error'         : 'the <tagString> was not specified!',
        'exitCode'      : 11},
    'tagAfterString'    : {
        'action'        : 'checking the -s <tagAfterString>, ',
        'error'         : 'the <tagStopString> was not specified!',
        'exitCode'      : 11},
    'tagSortString'     : {
        'action'        : 'checking the command line arguments, ',
        'error'         : 'the <tagSortString> was not specified',
        'exitCode'      : 11},
    'columnInLine'      : {
        'action'        : 'checking the command line arguments, ',
        'error'         : 'the <columnInLine> was not specified',
        'exitCode'      : 11},
    'sortExt'           : {
        'action'        : 'sorting contents to sub-file, ',
        'error'         : 'I couldn not determine the sub-file name. Extension error.',
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
    opts, remargs   = getopt.getopt(sys.argv[1:], 'f:s:u:')
except getopt.GetoptError:
    synopsis_show()
    sys.exit(1)

for o, a in opts:
    if (o == '-s'):
        Gstr_tagHoldString             = a
    if (o == '-u'):
        Gstr_tagAfterString              = a
        Gb_tagStopStringSpecified       = True
    if (o == '-f'):
        Gstr_fileName                   = a
    if (o == '-C'):
        G_columnLine                    = int(a)
    if (o == '-S'):
        Gstr_tagSortString              = a

if len(sys.argv) == 1: fatal('NoArgs')
if not len(Gstr_fileName): fatal('fileName')
if not len(Gstr_tagHoldString): fatal('tagHoldString')
if not len(Gstr_tagAfterString): fatal('tagAfterString')

try:
    FILE_input = open(Gstr_fileName)
except IOError:
    fatal('fileInputAccess')

for line in FILE_input:
    line        = line.strip()
    if contains(line, Gstr_tagHoldString):
       str_holdLine     = line
    else:
       print "%s" % line 
    if contains(line, Gstr_tagAfterString):
        print "%s" % str_holdLine

FILE_input.close()
    
sys.exit(0)
