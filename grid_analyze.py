#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 

Gb_showErr      = 1
Gb_silent       = 0
Gstr_findStr    = ""
Gstr_workingDir = ""

Gstr_synopsis 	= """

  NAME
       
      grid_analyze.py 
 
  SYNPOSIS

      grid_analyze.py -s <findRegEx> [-w <workingDir>]

  DESC

      'grid_analyze.py' accepts a find (1) compatible <findRegEx>
      that describes the grid cases to analyze. For each "hit" off the
      find call, this script reads the grid and X/Y ordering files building
      C_ggrid and C_spectrum summation objects.
    
  ARGS

      -s <findRegEx>
      A find (1) compatible string defining the grid cases to analyze.
      To protect from the shell, this string should be enclosed in 
      quotes, i.e. "<findRegEx>".
      
      -w <workingDir> (Optional)
      Perform the analysis from the specified <workingDir>.

  EXAMPLE
  Typical example:
        $>grid_analyze.py -s "lh*frontal*pial*"
		
  PRECONDITIONS

        o Completed curvature analysis run.
        
  POSTCONDITIONS

	o Analysis of grid and spectral components.
        
  HISTORY

  11 April 2011
  o Initial development implementation.

"""

import 	os
import	sys
import	getopt
import  string
from    numpy   import *
import  systemMisc      as misc
import  C_ggrid         as grid
import  C_spectrum      as spectrum

dictErr = {
    'NoArgs'            : {
        'action'        : 'checking the command line arguments, ', 
        'error'         : 'no options specified!', 
        'exitCode'      : 10},
    'findRegEx'         : {
        'action'        : 'checking the -s <FindRegEx>, ',
        'error'         : 'the <FindRegEx> was not specified!',
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

try:
    opts, remargs   = getopt.getopt(sys.argv[1:], 'hxs:')
except getopt.GetoptError:
    sys.exit(1)

for o, a in opts:
    if (o == '-x' or o == '-h'):
        synopsis_show()
        sys.exit(1)
    if (o == '-s'):
        Gstr_findStr    = a

Gstr_findStr += "grid"
if len(sys.argv) == 1: fatal('NoArgs')
if not len(Gstr_findStr): fatal('FindRegEx')

if len(Gstr_workingDir):
    try:
        chdir(Gstr_workingDir)
    except OSError:
        fatal('workingDir', 'Current Working Dircectory: %s' % Gstr_workingDir)
    Gstr_workingDir = os.getcwd()        

verbose         = 0
str_findCmd     = 'find . -iname "%s"' % Gstr_findStr
lstr_hitsRaw    = misc.system_procRet(str_findCmd)

str_fileHits    = lstr_hitsRaw[1]
lstr_hitsAll    = str_fileHits.split('\n')
lstr_hits       = filter(len, lstr_hitsAll)

count           = 0
for str_filePath in lstr_hits:
    (str_stem, str_ext) = os.path.splitext(str_filePath)
    print str_filePath
    str_gridFile = '%s.grid' % str_stem
    str_xordFile = '%s.xord' % str_stem
    str_yordFile = '%s.yord' % str_stem
    Cg           = grid.C_ggrid(str_gridFile)
    if not count:
        Cg_sum          = Cg
        Csp_xord        = spectrum.C_spectrum_permutation(Cg_sum.cols_get())
        Csp_xord.printAsHistogram_set(True)
        Csp_xord.name_set('X-ordering')
        Csp_yord        = spectrum.C_spectrum_permutation(Cg_sum.cols_get())
        Csp_yord.printAsHistogram_set(True)
        Csp_yord.name_set('Y-ordering')
        Csp_xyord       = spectrum.C_spectrum_permutation2D(Cg_sum.cols_get())
        Csp_xyord.printAsHistogram_set(True)
        Csp_xyord.name_set('XY-ordering')
        Csp_xyord.printConcise_set(True)
    else:
        Cg_sum   = Cg_sum + Cg
    str_xord = Csp_xord.component_fadd(str_xordFile)
    str_yord = Csp_yord.component_fadd(str_yordFile)
    str_xyord = Csp_xyord.component_add('%s%s' % (str_xord, str_yord))
    count += 1

if count:
    print Cg_sum
    print Csp_xord
    print Csp_yord
    print Csp_xyord
else: fatal('NoHits')

sys.exit(0)
