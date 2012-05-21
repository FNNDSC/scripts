#
# NAME
#
#	chris_dcmXML
#
# DESCRIPTION
#
#	The 'chris_dcmXML' contains the information of a single record in the 
#	CHRIS system. The 'dcmXML' refers specifically to the fact that
#	this record is based off the input DICOM image data, and retrieved
#	from parsing an XML file (or stream?) containing the information.
#
# HISTORY
#
# 16 May 2012
# o Initial development implementation.
#
#

# System imports
import 	os
import 	sys
import	string
from	xml.sax		import	make_parser
from 	xml_handler	import	C_SAX_XMLhandler

import 	systemMisc 	as misc

class C_chrisDCM:
	
    def __init__(self):
	# 
	# Member variables
	#
	# 	- Core variables - generic
	self.__name__		= 'C_chrisDCM';	
	self.__objName__	= 'C_chrisDCM';
	self.mdict_data		= {}
	self.ml_keys		= [
		'recordCtime',
		'PatientID',
		'Directory',
		'PatientName',
		'PatientAge',
		'PatientSex',
		'PatientBirthday',
		'ImageScanDate',
		'ScannerManufacturer',
		'ScannerModel',
		'ScannerID',
		'SoftwareVer',
		'Scan_',
		'User_',
		'Group_'
	]
	
    def __str__(self):
    	return self.records_toStr(self.mdict_data)

    def records_toStr(self, adict, astr_recordPrefix=""):
	str_out = ""
	for record in sorted(adict.iterkeys()):
	    str_out  	+= "\n%s%s\n" % (astr_recordPrefix, record)
	    d_entry	= adict[record]
	    for key in self.ml_keys:
		if key[-1] == "_":
	    	    for val in d_entry[key[0:-1]]:
	    		str_out += "%20s: %60s\n" % (key[0:-1], val)
	    	else:
	    	    str_out += "%20s: %60s\n" % (key, d_entry[key])
	return str_out
		
    def error_exit(         self,
                                astr_action,
                                astr_error,
                                aexitCode):
            print "\nFATAL ERROR!"
            print "\tSorry, some error seems to have occurred in '%s'." \
                        % (self.__objName__)
            print "\tWhile %s"                                  % astr_action
            print "\t%s"                                        % astr_error
            print ""
            print "Returning to system with error code %d."     % aexitCode
            sys.exit(aexitCode)
		
    def keys(self, *args):
    	if len(args):
    	    l_keys	= args[0]
    	    if type(l_keys) is types.ListType:
       	  	self.ml_keys = l_keys
       	return self.ml_keys  

    def search(self, str_tag, str_value, adict):
     	_d_hit	= {}
      	c		= 0
      	for d_record in adict.values():
      	   b_hit 	= False
      	   if str_tag + '_' in self.ml_keys:
      	   	for el in d_record[str_tag]:
      	   	    if str_value in el: b_hit = True
    	   elif str_value in d_record[str_tag]: b_hit = True
    	   if b_hit:
    	    	c	+= 1
    	     	_d_hit[c] = d_record
        return _d_hit
       
    def dict_data(self):
    	return self.mdict_data
		
class C_chrisDCM_XML(C_chrisDCM):
	"""
	This specialization simply accepts an XML data file as its
	input constructor and reads file contents into a dictionary
	structure, self.mdict_data.
	"""

	def __init__(self, astr_xmlDBFile, astr_boundingTag='PatientRecord'):
	    """
	    Constructor for the XML parsing code. The class module
	    assumes that the actual XML filename corresponds to the
	    idCode being searched.
	    """
	    self.__name__		= 'C_chrisDCM_XML';	
	    self.mstr_xmlDBFile		= astr_xmlDBFile
	    self.mstr_boundingTag	= astr_boundingTag
	    self.mb_XMLparsed		= 0
	    C_chrisDCM.__init__(self)
	    if not misc.file_exists(astr_xmlDBFile):
		self.error_exit('accessing XML file %s:' % astr_xmlDBFile,
				'File not found.',
				1)
	    self.mc_handler	= C_SAX_XMLhandler(astr_xmlDBFile, 
					self.keys(), self.mstr_boundingTag)
	    self.mdict_data	= self.mc_handler.dictXML()


           