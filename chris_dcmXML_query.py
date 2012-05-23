#!/usr/bin/env python
#

Gstr_fileDB	= 'dcm_MRID.xml'
Gstr_dirDB	= '../htdocs/dicom-mono'

Gb_search	= False
G_verbose	= 0

Gstr_synopsis 	= """
NAME

	chris_dcmXML_query.py

SYNOPSIS

	chris_dcmXML_query.py 	[-i <Tag>:<value>]			\\
				[-b <dataBaseDir>] [-f <dataBaseFile>]

DESCRIPTION

	This is a simple "driver" that processes a monolithic
	XML database. 
	
	The driver operates in a simple search mode:
	 
		o Search (-i ...)
		Retrieve the corresponding records that have <Tag>
		and <value>, for example: -i PatientID:4278152.
		<Tag> searches can be concatenated (see below).
		
NOTE
	The XML file *must* be well formed, i.e. contain only one
	root element.

ARGUMENTS
	
	-i <Tag>:<Value>
	The search term to find in the database. Multiple search terms
	can be concatenated together with a ',' and the result is the
	intersection of all the searches. For example:
	
		Scan:MPRAGE,Scan:DTI,ImageScanDate:2011,PatientSex:M
	
	will return all records that contain *both* MPRAGE and DTI
	scans (substring search), were scanned in 2011, and were collected
	on male patients.

	-b <dataBaseDir> (default: %s)
	The directory containing the XML database.
	
	-f <dataBaseFile> (default: %s)
	The input (monolithic) XML database to parse (relative to <dataBaseDir>). 
	
	-S
	Split the database into constituent components. The <-i> and <-h>
	flags are ignored.
	
	-v <level>
	Provide some additional (verbose) information. Currently, a <level>
	of '1' provides the number of records in the XML file; a <level> of '10'
	prints the whole database dictionary. 

HISTORY

        17-May-2012
        o Initial design and coding.
        
""" % (Gstr_dirDB, Gstr_fileDB)

# System imports
import 	getopt

# Project imports
from	C_chrisDCM	import 	*

def synopsis_show(void=0):
        print Gstr_synopsis

try:
        opts, remargs   = getopt.getopt(sys.argv[1:], 'b:i:f:xv:')
except getopt.GetoptError:
        synopsis_show()
        sys.exit(1)

for o, a in opts:
	if(o == '-i'):
		Gb_search	= True
		Gstr_search	= a
        if(o == '-b'):
                Gstr_dirDB	= a
        if(o == '-f'):
                Gstr_fileDB	= a
	if(o == '-v'):
		G_verbose	= a 
	if(o == '-x'):
		synopsis_show()
		sys.exit(1)

chrisDCM	= C_chrisDCM_XML("%s/%s" % (Gstr_dirDB, Gstr_fileDB))
dict_DB		= chrisDCM.dict_data()
if G_verbose:
    if G_verbose == 10: print chrisDCM
    print "Processed %d records." % (len(dict_DB.keys()))
if Gb_search:
    l_terms 	= Gstr_search.split(',')
    t		= 0
    for str_term in l_terms: 
        str_tag, str_value	= str_term.split(':')
        if not t:
	    d_entry = chrisDCM.search(str_tag, str_value, chrisDCM.dict_data())
	else:
            d_entry = chrisDCM.search(str_tag, str_value, d_entry)
        t += 1
    print chrisDCM.records_toStr(d_entry, "Record ")
			