#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 

Gb_showErr      = 1
Gb_silent       = 0
Gstr_findStr    = ""
Gstr_workingDir = ""

Gb_iname	= False
Gb_wholename	= False

Gstr_synopsis 	= """

  NAME
       
      features_determine.py 
 
  SYNPOSIS

      features_determine.py -s|-w <findRegEx> [-D <workingDir>]

  DESC

      'features_determine.py' accepts a find (1) compatible <findRegEx>
      that describes the sub-matrix image snapshots to analyze. For each 
      "hit" off the find call, this script attempts to find some useful 
      descriptive features.
      
      Currently these features are:
      
              - weighted image centroid of whole matrix
              - density (actual and binary) of whole matrix
              - weighted image centroid of "lower" triangular matrix
              - weighted image centroid of "upper" triangular matrix
              - density (actual and binary) of "lower" triangular matrix
              - density (actual and binary) of "upper" triangular matrix
              
      Each of the above are saved to separate text files.
      
  ARGS

      -s|-w <findRegEx>
      A find (1) compatible string defining the grid cases to analyze.
      To protect from the shell, this string should be enclosed in 
      quotes, i.e. "<findRegEx>".
      
      If a '-s' is passed, then the find will execute a 

		  find . -iname <findRegEx>

      otherwise, if a '-w' is passed, then the find will instead execute
      
		  find . -wholename <findRegEx>
      
      -D <workingDir> (Optional)
      Perform the analysis from the specified <workingDir>.

  EXAMPLE
  Typical example:
        $>centroids_determine.py -s "*dat"
		
  PRECONDITIONS

        o Completed set of filtered RGB data matrices from CAM runs
        
  POSTCONDITIONS

	o Set of files containing features:
	
                x <fileStem>.crd          -- whole matrix centroid
                x <fileStem>.dty          -- whole matrix density
	        x <fileStem>-lower.crd    -- lower triangular matrix centroid
                x <fileStem>-lower.dty    -- lower triangular matrix density
                x <fileStem>-upper.crd    -- upper triangular matrix centroid
                x <fileStem>-upper.dty    -- upper triangular matrix density
        
  HISTORY

  10 January 2011
  o Initial development implementation.

"""

import 	os
import	sys
import	getopt
import  string
import  numpy           as np
import  systemMisc      as misc

dictErr = {
    'NoArgs'            : {
        'action'        : 'checking the command line arguments, ', 
        'error'         : 'no options specified!', 
        'exitCode'      : 10},
    'findRegEx'         : {
        'action'        : 'checking the -s|-w <FindRegEx>, ',
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
    opts, remargs   = getopt.getopt(sys.argv[1:], 'hxs:w:D:')
except getopt.GetoptError:
    sys.exit(1)

for o, a in opts:
    if (o == '-x' or o == '-h'):
        synopsis_show()
        sys.exit(1)
    if (o == '-s'):
        Gstr_findStr    = a
        Gb_iname	= True
    if (o == '-w'):
        Gstr_findStr    = a
        Gb_wholename	= True
    if (o == '-D'):
        Gstr_workingDir = a        
       
if len(sys.argv) == 1: fatal('NoArgs')
if not len(Gstr_findStr): fatal('FindRegEx')

if len(Gstr_workingDir):
    try:
        os.chdir(Gstr_workingDir)
    except OSError:
        fatal('workingDir', 'Current Working Dircectory: %s' % Gstr_workingDir)
    Gstr_workingDir = os.getcwd()        

verbose         = 0
if Gb_iname:
    str_findCmd = 'find . -iname "%s" 2>/dev/null' % Gstr_findStr
elif Gb_wholename:
    str_findCmd = 'find . -wholename "%s" 2>/dev/null' % Gstr_findStr

lstr_hitsRaw    = misc.system_procRet(str_findCmd)

str_fileHits    = lstr_hitsRaw[1]
lstr_hitsAll    = str_fileHits.split('\n')
lstr_hits       = filter(len, lstr_hitsAll)

count           = 0
for str_filePath in lstr_hits:
    (str_stem, str_ext) = os.path.splitext(str_filePath)
    count       += 1    
    print "\n%s" % str_filePath
    a_mat       = np.loadtxt(str_filePath)
    rows, cols  = a_mat.shape
    a_lowerMask = np.tri(rows, cols, k=0)       # Create lower and
    a_upperMask = a_lowerMask.transpose()       # upper masks for the data
    a_matUpper  = a_mat * a_upperMask
    a_matLower  = a_mat * a_lowerMask

    a_c         = misc.com_find2D(a_mat) / a_mat.shape
    a_d         = misc.density(a_mat)
    a_cUpper    = misc.com_find2D(a_matUpper) / a_mat.shape
    a_cLower    = misc.com_find2D(a_matLower) / a_mat.shape
    a_dUpper    = misc.density(a_matUpper, a_upperMask)
    a_dLower    = misc.density(a_matLower, a_lowerMask)

    print a_c
    print a_cLower, a_cUpper
    print a_d
    print a_dLower, a_dUpper
    str_c       = '%s.crd'       % str_stem
    str_d       = '%s.dty'       % str_stem
    str_cUpper  = '%s-upper.crd' % str_stem
    str_cLower  = '%s-lower.crd' % str_stem
    str_dUpper  = '%s-upper.dty' % str_stem
    str_dLower  = '%s-lower.dty' % str_stem
    np.savetxt(str_c,      a_c,      fmt='%5.5f', delimiter='\t', newline=' ')    
    np.savetxt(str_d,      a_d,      fmt='%5.5f', delimiter='\t', newline=' ')    
    np.savetxt(str_cUpper, a_cUpper, fmt='%5.5f', delimiter='\t', newline=' ')    
    np.savetxt(str_cLower, a_cLower, fmt='%5.5f', delimiter='\t', newline=' ')    
    np.savetxt(str_dUpper, a_dUpper, fmt='%5.5f', delimiter='\t', newline=' ')    
    np.savetxt(str_dLower, a_dLower, fmt='%5.5f', delimiter='\t', newline=' ')    
        
sys.exit(0)
