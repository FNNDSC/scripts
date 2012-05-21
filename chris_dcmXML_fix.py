#!/usr/bin/env python
#

Gstr_fileDB	= '/chb/users/dicom/files/dcm_MRID.xml'

Gb_verbose	= False

Gstr_synopsis 	= """
NAME

	chris_dcmXML_fix.py

SYNOPSIS

	chris_dcmXML_fix.py	[-f <inputXML>]

DESCRIPTION

	This is a simple script that 'fixes' the malformed XML
	database file of CHRIS-1.0. The file does not contain
	a single root element; rather each <PatientRecord> is
	is root element.
	
	This script adds a
	
	<db>
		...
	</db>
	
	tag around the contents and so forms a valid XML file.


ARGUMENTS
	
	-f <inputXML> (default: %s)
	The input (monolithic) XML database to parse.	
	
	-v
	Provide some additional information (verbose). 

HISTORY

        17-May-2012
        o Initial design and coding.
        
""" % (Gstr_fileDB)

# System imports
import 	os
import 	sys
import 	getopt

def synopsis_show(void=0):
        print Gstr_synopsis

try:
        opts, remargs   = getopt.getopt(sys.argv[1:], 'b:i:f:Sxv')
except getopt.GetoptError:
        synopsis_show()
        sys.exit(1)

for o, a in opts:
        if(o == '-f'):
                Gstr_fileDB	= a
	if(o == '-v'):
		Gb_verbose	= 1 
	if(o == '-x'):
		synopsis_show()
		sys.exit(1)

fdcm = open(Gstr_fileDB)
l_lines	= fdcm.readlines()

print """<?xml version="1.0"?>
<db>
"""

for line in l_lines[1:]:
    print line,
    
print "</db>"

