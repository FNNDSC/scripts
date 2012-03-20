#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 

Gb_showErr      = 1
Gb_forceErr     = 0
Gstr_forceErr   = "<error>"

Gstr_surface    = "-x"
Gstr_hemi       = "-x"
Gstr_curv       = "-x"

Gstr_synopsis 	= """
NAME

	mris_autodijk.py

SYNOPSIS

        mris_autodijk.py        -e <hemi> -s <surface> -c <curv>        \\
                                [-t <topDirectory>]                     \\
                                <SUBJ1> <SUBJ2>... <SUBJn>

DESCRIPTION

	'mris_autodijk.py' is a thin "wrapper" that creates and runs an
        underlying 'mris_pmake' process with an autodijk context.       
	
ARGUMENTS
        
        -h <hemi>
        The hemisphere on the <SUBJ> to process.
        
        -s <surface>
        The surface on <hemi> to process. Typically either 'smoothwm' or
        'pial'. Sometimes 'sphere'.
        
        -c <curv>
        The curvature overlay to use. It is sufficient to only specify the
        curvature file "root", i.e. 'H', 'K', 'K1', 'K2', etc.
        
        <SUBJ1> <SUBJ2>... <SUBJn>
        List of subjects to process. Assumes a FREESURFER env context.
		
PRECONDITIONS

        o A FREESURFER env context.
	
POSTCONDITIONS

	o For each subject, create and run an 'autodijk' instance.
        
HISTORY

    13 March 2012
    o Initial development implementation.

"""

import 	os
import	sys
import	getopt
import  string


import argparse
from _common import crun

dictErr = {
    'noHemi'            : {
        'action'        : 'checking for the input <hemi>, ', 
        'error'         : "it doesn't look like it was specified. Did you use '-h <hemi>'?", 
        'exitCode'      : 10
                            },
    'noSurface'         : {
        'action'        : 'checking the input <surface>, ', 
        'error'         : "it doesn't look like it was specified. Did you use '-s <surface>'?", 
        'exitCode'      : 11
                            },
   'noCurvature'        : {
        'action'        : 'checking the input <curvature>, ', 
        'error'         : "it doesn't look like it was specified. Did you use '-c <curvature>'?", 
        'exitCode'      : 12
                            },
   'noFSenv'            : {
        'action'        : 'checking the environment, ', 
        'error'         : "it doesn't look like the FREESURFER env has been sourced.", 
        'exitCode'      : 13
                            },
     'comArgs'          : {
        'action'        : 'checking command line arguments,', 
        'error'         : 'it seems that you have wrong number of arguments.', 
        'exitCode'      : 14
                            }
}

Gstr_SELF       = sys.argv[0]

def synopsis_show():
    print "%s" % Gstr_synopsis

def error_exit(astr_key):
    if Gb_showErr:
        print >>sys.stderr, Gstr_SELF
        print >>sys.stderr, "\n"
        print >>sys.stderr, "\tSorry, but some error occurred."
        print >>sys.stderr, "\tWhile " + dictErr[astr_key]['action']
        print >>sys.stderr, "\t" + dictErr[astr_key]['error']
        print >>sys.stderr, "\n"
        print >>sys.stderr, "Exiting to system with code %d.\n" % dictErr[astr_key]['exitCode']
    if Gb_forceErr:
        print Gstr_forceErr
    sys.exit(dictErr[astr_key]['exitCode'])

def fatal(astr_key, astr_extraMsg=""):
    if len(astr_extraMsg): print astr_extraMsg
    error_exit( astr_key)

Gstr_topDir     = os.getcwd()
    
parser = argparse.ArgumentParser(
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description=Gstr_synopsis)

parser.add_argument('subjects', metavar='SUBJ', type=str, nargs='+',
                   help='Subject list to process')
parser.add_argument('-e', '--hemi', 
                    dest='Gstr_hemi',
                    default="-x",
                    help='the hemisphere to process')
parser.add_argument('-s', '--surface', 
                    dest='Gstr_surface',
                    default="-x",
                    help='the surface to process')
parser.add_argument('-t', '--topDir', 
                    dest='Gstr_topDir',
                    default="-x",
                    help='the surface to process')
parser.add_argument('-c', '--curvature', 
                    dest='Gstr_curv',
                    default="-x",
                    help='the curvature file to process')

args            = parser.parse_args()
Gstr_hemi       = args.Gstr_hemi
Gstr_curv       = args.Gstr_curv
Gstr_surface    = args.Gstr_surface
Gstr_topDir     = args.Gstr_topDir

print len(args.subjects)

if Gstr_hemi    == '-x': fatal('noHemi')
if Gstr_surface == '-x': fatal('noSurface')
if Gstr_curv    == '-x': fatal('noCurvature')

str_curvFile    = '%s.%s.%s.crv' % (Gstr_hemi, Gstr_surface, Gstr_curv)

print str_curvFile
print Gstr_topDir

if not os.path.exists(Gstr_topDir):
    print "Target top directory not found. Creating"
    os.makedirs(Gstr_topDir)

for str_subj in args.subjects:
    str_wd      = '%s-%s-%s-%s' % (str_subj, Gstr_hemi, Gstr_surface, Gstr_curv)
    str_wdFQ    = '%s/%s' % (Gstr_topDir, str_wd)
    print str_wdFQ
    

    
sys.exit(0)
