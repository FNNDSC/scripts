#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
Gstr_inputVolume	= "-x"
Gstr_thresholdNorm	= "-x"

Gstr_synopsis 	= """
NAME

        vol_thFind.py

SYNOPSIS

        vol_thFind.py  			-v <inputVolume>		\\
					-t <thresholdNorm>		
	
DESCRIPTION

        Analyzes the intensity range in <inputVolume>, and maps the 
        corresponding normal threshold value <thresholdNorm> to the
        volume intensity ranges.
	
ARGUMENTS
	
	-v <inputVolume>
	The input volume to process.
	
	-t <thresholdNorm>
	The normalized threshold value to map. "0" corresponds to the
        minimum intensity and "1" corresponds to the max intensity.

PRECONDITIONS
    
	o Uses 'mris_calc' to determine the actual intensity values.

POSTCONDITIONS

	o Mapped threshold is echo'd to stdout.

HISTORY

11 May 2009
o Initial development implementation.

"""

import 	os
import	sys
import	getopt
from	systemMisc	import	*
import  subprocess      as sub

dictErr	= {
    'noInputVolume'	: {
	'action'	: 'checking command line arguments,', 
	'error'		: 'it seems that no "-v <inputVolume>" was specified.', 
	'exitCode'	: 12
			    },
    'noInputVolumeExist'     : {
        'action'        : 'checking input volume,', 
        'error'         : 'it seems that the input volume does not exist.', 
        'exitCode'      : 13
                            },
    'noThreshold'	: {
	'action'	: 'checking command line arguments,', 
	'error'		: 'it seems that no "-t <thresholdNorm>" was specified.', 
	'exitCode'	: 14
			    }
}

def synopsis_show():
    print "%s" % Gstr_synopsis

def error_exit(         astr_func,
                        astr_action,
                        astr_error,
                        aexitCode):
        print "%s: FATAL ERROR" % 'vol_thFind.py'
        print "\tSorry, some error seems to have occurred in <%s::%s>" \
                % ('vol_thFind', astr_func)
        print "\tWhile %s"                                  % astr_action
        print "\t%s"                                        % astr_error
        print ""
        print "Returning to system with error code %d"      % aexitCode
        sys.exit(aexitCode)

def fatal(astr_key, astr_extraMsg=""):
    if len(astr_extraMsg): print astr_extraMsg
    error_exit(	astr_key, 
		dictErr[astr_key]['action'],
		dictErr[astr_key]['error'],
		dictErr[astr_key]['exitCode'])

try:
        opts, remargs   = getopt.getopt(sys.argv[1:], 'v:t:')
except getopt.GetoptError:
        synopsis_show()
        sys.exit(1)

verbose         = 0
for o, a in opts:
	if(o == '-v'):
                Gstr_inputVolume	= a
	if(o == '-t'):
                Gstr_thresholdNorm 	= a
	if(o == '-x'):
                synopsis_show()
                sys.exit(1)

if Gstr_inputVolume 	== "-x": fatal('noInputVolume')
if Gstr_thresholdNorm	== "-x": fatal('noThreshold')

b_inputVolume   = file_exists(Gstr_inputVolume)
if not b_inputVolume: fatal('noInputVolumeExist')

p               = sub.Popen('mris_calc %s stats' % Gstr_inputVolume, 
                            shell=True, stdout=sub.PIPE, stderr=sub.PIPE)
output,errors   = p.communicate()
l_errors        = str2lst(errors, '\n')

l_min           = str2lst(l_errors[2])
l_max           = str2lst(l_errors[3])

f_min           = float(l_min[2])
f_max           = float(l_max[2])
f_range         = f_max - f_min
f_Nth           = float(Gstr_thresholdNorm)

f_th            = (f_range * f_Nth) + f_min
print f_th

