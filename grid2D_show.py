#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 

Gb_indexOne     = 0
Gb_showCoords   = 0
Gstr_Xorder     = ""
Gstr_Yorder     = ""
Gb_showErr      = 1
Gb_saveFile     = 0
Gb_silent       = 0
Gstr_saveFile   = ""

Gstr_synopsis 	= """
  NAME
       
      grid2D_show.py 
 
  SYNPOSIS

      grid2D_show.py [-c] [-z] [-s|S <saveFile>] -X <X-ordering> -Y <Y-ordering>

  DESC

      'grid2D_show.py' accepts two ordering strings as generated
      by 'ordering_tabulate.sh', one for X-order and one for the Y-order.
      It generates the [row,col] positions of the group indices in 
      a 2D space.
    
  ARGS

      -c (Optional)
      Show the coordinates of the groups and not their indices.

      -z (Optional)
      When used in conjunction with '-c', do not use zero as the first
      coordinate. Index (0,0) for example is expressed as (1,1).

      -x <X-ordering> -y <Y-ordering>
      The string order desription of the cluster groups. Note that the
      Y-ordering is assumed to be left-right decreasing (i.e. the left most
      value is the highest Y-group -- see the example).

      -s <saveFile>
      Save the grid to <saveFile>. If a '-S' is used, then save output
      and also be silent (i.e. no output to console).

  EXAMPLE
  Typical example:
        $>grid2D_show.sh 4312 4321
        4 0 0 0 
        0 3 0 0
        0 0 0 2
        0 0 1 0
		
  PRECONDITIONS

        o The <X-ordering> and <Y-ordering> strings must be the same length.
	
  POSTCONDITIONS

	o A 2D grid of spatial positioning of the groups relative to each
	  other is shown in a matrix.
        
  HISTORY

  23 March 2011
  o Initial development implementation.

"""

import 	os
import	sys
import	getopt
import  string
from    numpy   import *

dictErr = {
    'NoArgs'            : {
        'action'        : 'checking the command line arguments, ', 
        'error'         : 'No options specified!', 
        'exitCode'      : 10},
    'XstringLen'        : {
        'action'        : 'checking the -X <X-ordering>, ',
        'error'         : 'The X-ordering was not specified!',
        'exitCode'      : 11},
    'YstringLen'        : {
        'action'        : 'checking the -Y <Y-ordering>, ',
        'error'         : 'The Y-ordering was not specified!',
        'exitCode'      : 12},
    'XYstringLen'       : {
        'action'        : 'checking the length of <X-ordering> and <Y-ordering>, ', 
        'error'         : 'The strings have unequal length.', 
        'exitCode'      : 13
                            }
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
    opts, remargs   = getopt.getopt(sys.argv[1:], 'X:Y:czxhs:S:')
except getopt.GetoptError:
    sys.exit(1)

for o, a in opts:
    if (o == '-x' or o == '-h'):
        synopsis_show()
        sys.exit(1)
    if (o == '-X'):
        Gstr_Xorder      = a
    if (o == '-Y'):
        Gstr_Yorder      = a
    if (o == '-c'):
        Gb_showCoords   = 1
    if (o == '-s'):
        Gb_saveFile     = 1
        Gstr_saveFile   = a
    if (o == '-S'):
        Gb_saveFile     = 1
        Gstr_saveFile   = a
        Gb_silent       = 1
    if (o == '-z'):
        Gb_indexOne     = 1

if len(sys.argv) == 1: fatal('NoArgs')
if not len(Gstr_Xorder): fatal('XstringLen')
if not len(Gstr_Yorder): fatal('YstringLen')

verbose         = 0
Xlen            = len(Gstr_Xorder)
Ylen            = len(Gstr_Yorder)

if Xlen != Ylen: fatal('XYstringLen')

M = zeros((Xlen, Ylen))
for group in range(0, Xlen):
  ch_groupIDX   = Gstr_Xorder[group]
  col           = Gstr_Xorder.find(ch_groupIDX)
  row           = Gstr_Yorder.find(ch_groupIDX)
  if Gb_indexOne and Gb_showCoords:
      col+=1
      row+=1
  if Gb_showCoords:
    print '%s: %s, %s' % (ch_groupIDX, row, col)
  else:
      M[row, col] = ch_groupIDX
if not Gb_showCoords and not Gb_silent: print M
if Gb_saveFile:
    savetxt(Gstr_saveFile, M, '%2d')


sys.exit(0)
