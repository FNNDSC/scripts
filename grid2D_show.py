#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 

Gb_showErr      = 1
Gb_forceErr     = 0
Gstr_forceErr   = "<error>"
Gstr_ageInput   = "-x"

Gstr_synopsis 	= """
  NAME
       
      grid2D_show.sh
 
  SYNPOSIS

      grid2D_show.sh <X-ordering> <Y-ordering>

  DESC

      'grid2D_show.sh' accepts two ordering strings as generated
      by 'ordering_tabulate.sh', one for X-order and one for the Y-order.
      It generates the [row,col] positions of the group indices in 
      a 2D space.
    
  ARGS

      <X-ordering> <Y-ordering>
      The string order desription of the cluster groups. Note that the
      Y-ordering is assumed to be left-right decreasing (i.e. the left most
      value is the highest Y-group -- see the example).

  EXAMPLE
  Typical example:
		
  PRECONDITIONS

        o The <ageString> must be of form 'XXXA' as described above.
	
  POSTCONDITIONS

	o The equivalent number of days denoted by the <ageString> is returned.
        
  HISTORY

  23 March 2011
  o Initial development implementation.

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
        'error'         : 'Modifier is either "D" for days, "M" for months, "Y" for years."', 
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
        
    opts, remargs   = getopt.getopt(sys.argv[1:], 'xni:N:')
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

if Gstr_ageInput == "-x": fatal('ageSpec')
if len(Gstr_ageInput) != 4:
    if Gb_showErr:
        print >>sys.stderr, "Invalid length of <ageString>. Must be of form 'XXXM' where"
        print >>sys.stderr, "'X' is a number and 'A' is either 'D', 'M', or 'Y'."
        print >>sys.stderr, "\n"
        print >>sys.stderr, "Examples of valid <ageStrings>: 034D, 002W, 007Y, etc."
        print >>sys.stderr, "\n"
    fatal('ageStringLen')

Gstr_ageString  = Gstr_ageInput[0:3]

Gstr_ageFact    = Gstr_ageInput[3]
if Gstr_ageFact != 'D' and Gstr_ageFact != 'M' and Gstr_ageFact != 'Y':
    fatal('ageStringF')

Gf_ageInput     = string.atof(Gstr_ageString)
Gf              = Gf_ageInput
Gf_ageInDays    = {

    'D' : lambda Gf:    Gf * 1.0,
    'M' : lambda Gf:    Gf * 30.42,
    'Y' : lambda Gf:    Gf * 365.25

} [Gstr_ageFact](Gf)
 
print "%d" % Gf_ageInDays,

sys.exit(0)
