#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 

Gb_showErr              = 1
Gb_forceErr             = 0
Gstr_forceErr           = "<error>"
Gstr_ageInput           = "-x"
Gstr_outputFormat       = "D"
Gstr_synopsis 	        = """
NAME

	unitAge_calc.py

SYNOPSIS

        unitAge_calc.py 	[-D|W|M|Y] [-n] [-N <forceError>] -i <ageString>

DESCRIPTION

	'unitAge_calc.py' accepts as input an <ageString> of format 'XXXA' where
        'X' denotes a numeric character [0-9] and 'A' denotes a modifier and is
        either 'D' (for Days), 'M' (for Months), 'W' (for Weeks) or 'Y' (for Years).

        The script simply calculates the age in the unit (D|W|M|Y) by its input
        string and echoes to stdout.
	
ARGUMENTS

        -D, -W, -M, -Y
        Specify the output age type: either days ('D'), weeks ('W') months ('M'),
        or years ('Y'). The default is 'D'.

        -n (OPTIONAL)
        If specified, suppress printing output stderr messages. This is useful
        if the script is called from 'awk' and there is no simple mechanism
        for filtering to /dev/null.

        -N <forceError> (OPTIONAL)
        If specified, and if any error has occurred, print <forceError> to
        <stdout> irrespective of '-n'.

	-i <ageString>
	The age string to process. 
		
PRECONDITIONS

        o The <ageString> must be of form 'XXXA' as described above.
	
POSTCONDITIONS

	o The equivalent number of days (or months or years) denoted by the 
          <ageString> is returned.
        o For month output, the age in days is divided by 30.4375.
        o For year  output, the age in days is divided by 365.25.
        
HISTORY

17 July 2009
o Initial development implementation.

05 August 2009
o D|M|Y expansion.

25 April 2011
o W expansion

"""

import 	os
import	sys
import	getopt
import  string

dictErr = {
    'ageStringLen'        : {
        'action'        : 'checking the input <ageString>, ', 
        'error'         : 'I counted the wrong number of characters.', 
        'exitCode'      : 10
                            },
    'ageSpec'           : {
        'action'        : 'checking the input <ageString>, ', 
        'error'         : "it doesn't look like it was specified. Did you use '-i <ageString>'?", 
        'exitCode'      : 10
                            },
    'comArgs'          : {
        'action'        : 'checking command line arguments,', 
        'error'         : 'it seems that you have wrong number of arguments.', 
        'exitCode'      : 11
                            },
    'ageStringF'         : {
        'action'        : 'checking age modifier, I read an incorrect character.', 
        'error'         : 'Modifier is either "D" for days, "W" for weeks, "M" for months, "Y" for years."', 
        'exitCode'      : 12
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

try:
    opts, remargs   = getopt.getopt(sys.argv[1:], 'xni:N:DWMY')
except getopt.GetoptError:
    if Gb_showErr: print Gstr_forceErr
    sys.exit(1)

verbose         = 0

for o, a in opts:
        
    if (o == '-x'):
        synopsis_show()
        sys.exit(1)
    if (o == '-n'):
        Gb_showErr      = 0
    if (o == '-N'):
        Gb_forceErr     = 1
        Gstr_forceErr   = a
    if (o == '-i'):
        Gstr_ageInput   = a
    if (o == '-D' or o == '-W' or o == '-M' or o == '-Y'):
        Gstr_outputFormat = o[1]

if Gstr_ageInput == "-x": fatal('ageSpec')
if len(Gstr_ageInput) != 4:
    if Gb_showErr:
        print >>sys.stderr, "Invalid length of <ageString>. Must be of form 'XXXA' where"
        print >>sys.stderr, "'X' is a number and 'A' is either 'D', 'W', 'M', or 'Y'."
        print >>sys.stderr, "\n"
        print >>sys.stderr, "Examples of valid <ageStrings>: 034D, 002W, 007Y, etc."
        print >>sys.stderr, "\n"
    fatal('ageStringLen')

Gstr_ageString  = Gstr_ageInput[0:3]

Gstr_ageFact    = Gstr_ageInput[3]
if Gstr_ageFact != 'D' and Gstr_ageFact != 'W' and Gstr_ageFact != 'M' and Gstr_ageFact != 'Y':
    fatal('ageStringF')

Gf_ageInput     = string.atof(Gstr_ageString)
Gf              = Gf_ageInput
Gf_ageInDays    = {

    'D' : lambda Gf:    Gf * 1.0,
    'W' : lambda Gf:	Gf * 7.0,
    'M' : lambda Gf:    Gf * 30.4375,
    'Y' : lambda Gf:    Gf * 365.25

} [Gstr_ageFact](Gf)

Gstr_output     = {

    'D' : lambda Gf_ageInDays :    "%d"    % Gf_ageInDays,
    'W' : lambda Gf_ageInDays :    "%d"	   % (Gf_ageInDays / 7.0),
    'M' : lambda Gf_ageInDays :    "%d"    % (Gf_ageInDays / 30.4375),
    'Y' : lambda Gf_ageInDays :    "%d"    % (Gf_ageInDays / 365.25)

} [Gstr_outputFormat](Gf_ageInDays)
 
print "%s" % Gstr_output

sys.exit(0)
