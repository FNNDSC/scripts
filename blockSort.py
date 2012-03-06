#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 

from _common import systemMisc as misc

Gb_showErr                      = 1
Gb_silent                       = 0
Gstr_fileName                   = ""
Gstr_tagStartString             = ""
Gstr_tagStopString              = ""
Gstr_tagSortString              = ""
G_columnLine                    = -1

Gstr_synopsis 	= """

  NAME
       
      blockSort.py
 
  SYNPOSIS

      blockSort.py -f <fileName> -s <tagStartString> -u <tagStopString> \\
                   -S <tagSortString> -C <columnInLine>

  DESC

      'blockSort.py' sorts an input <fileName> into multiple smaller files
      based off a single pass through <fileName>. Text lines that are delimited
      between <tagStartString> and <tagStopString> (including) are appended
      to new files. The name of these new files are based on the text in
      <columnInLine> of matches to <tagSortString>. For example, if this
      text is <sortText>, the output sorted file is <fileName>.<sortText>
          
  ARGS

      -f <fileName>
      The input file to sort.

      -s <tagStartString>
      A string that tags the line on which to start applying the filter.
      
      -u <tagStopString>
      A string that tags the line on which to stop applying the filter.

      -S <tagSortString> -C <columnInLine>
      A string that defines where to append the filtered text. The
      <columnInLine> of <tagSortString> is used to create a new file,
      <fileName>.<columnInLine> which contains all sorted lines that
      conform to the search tags.
      		
  PRECONDITIONS

        o Valid input file.
        o Text blocks are not interleaved.
        
  POSTCONDITIONS

	o Input is filtered into multiple smaller files.
	
  EXAMPLE
      Typical example:

        $>blockSort.py -f DICOMseries.std -s Dicom-Data -u RESPONSE     \\
                        -S StudyInstanceUID -C 3

      will sort the input file 'DICOMseries.std' into smaller files.
      These sorted files' names will have an extention built from the
      3rd column of a line containing "StudyInstanceUID", and will contain
      all text lines between those starting with "Dicom-Data" up to and
      inlcuding the line containing "RESPONSE".

      This has the practical effect of sorting a single file with many
      different StudyInstanceUIDs into separate files, each containing
      a single StudyInstanceUID.

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
    'tagStartString'         : {
        'action'        : 'checking the -s <tagStartString>, ',
        'error'         : 'the <tagString> was not specified!',
        'exitCode'      : 11},
    'tagStopString'     : {
        'action'        : 'checking the -s <tagStopString>, ',
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
    if contains(line, Gstr_tagStopString) or contains(line, "Releasing"):
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
