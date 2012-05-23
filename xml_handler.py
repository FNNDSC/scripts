#!/usr/bin/env python
"""
 
 NAME

	xml handler classes

 DESCRIPTION

	This module contains a simple XML handler that converts the contents
	of an XML file into a python dictionary. Multiple tags occurring in the
	same record are stored as lists.
	
	Uses the 'sax' parser.
	
 PRECONDITIONS

	The keys defining a record need to passed in the constructor, as well
	as the bounding tag.
	
 HISTORY
 
 16 May 2012
 o Adaptation  / cleaning and expansion.
 o Removing dependencies on external custom modules that assume a data model

"""
import	sys

from	xml.sax			import	make_parser
from	xml.sax.handler		import	ContentHandler

import 	systemMisc 		as misc

class C_XMLhandler(ContentHandler):
    """
    This class 'handles' XML files. It can be used to construct
    a dictionary representation of an XML file, and also to extract
    specific entries from an XML file.

    The assumption is that the XML file is well formed, i.e. the
    document must have one and only one, top level element.
    
    Records in the document have a set of keys defining components
    and are contained in a bounding tag. Certain keys can have
    multiple occurrences in the record. 
    
    Consider:
    
    	<db>
    	    <record>
    	    	<name></name>
    	    	<age></age>
    	    	<like></like>
    	    	<like></like>
    	    </record>
    	    <record>
    	    	<name></name>
    	    	<age></age>
    	    	<like></like>
    	    	<like></like>
    	    </record>
    	</db>
    	
    Here, the keys are specified to the constructor as ['name', 'age', 'like_'] 
    where the trailing '_' on 'like_' indicates that the key is 'like' and can 
    occur multiple times. Internally, such keys are stored in the dictionary 
    as lists. The boundingTag is 'record'. When building the dictionary, the
    class creates new boundingTag entries with an incremental suffix.
    
    Internal structures:
    
    	self.mstr_boundingTag	= 'record'
    	self.ml_origKeys	= ['name', 'age', 'like_']
    	self.ml_keys		= ['name', 'age', 'like']
    	self.ml_Keys		= ['like']
    	
    	will result in a dictionary representation, self.mdict_XML:
    	
    	[record-1][name]	= <str> 	
    	[record-1][age]		= <str>
    	[record-1][like]	= <list>
    	
    	[record-2][name]	= <str> 	
    	[record-2][age]		= <str>
    	[record-2][like]	= <list>

    """

    def __init__(self, al_keys, astr_boundingTag = ""):
	# 
	# Member variables
	#
	# 	- Core variables
	self.__name__ 		= 'C_XMLhandler'
	self.ml_origKeys	= al_keys
	self.ml_keys		= []
	self.ml_Keys 		= [] 
	self.keys_parse()

	self.mstr_XMLfile    	= ''
	self.mdict_XML		= {}
	self.m_recordCount	= 0
		
	# The mb_inRecord is used in searching for a specific record
        self.mb_inRecord     	= False
        
        # The self.mbdict_inTag tracks which tag is currently being
        # processed, and the mdict_element contains all tags for a 
        # specific record entry.
        self.mdict_element   	= misc.dict_init(self.ml_keys, '')
        self.mdict_attrib	= misc.dict_init(self.ml_keys, '')
        # Setup the list keys
        for key in self.ml_Keys:
            self.mdict_element[key]	= []
            self.mdict_attrib[key]	= []
        self.mbdict_inTag    	= misc.dict_init(self.ml_keys, False)
        # The key defining a "top level" record
	self.mstr_boundingTag  	= astr_boundingTag
						   
    def dictXML(self):
    	return self.mdict_XML

    def keys_parse(self):
    	"""
    	Parse the original key list for any keys that have a trailing '_'
    	which indicates that these keys can occur multiple times in an
    	entry.
    	"""
    	for key in self.ml_origKeys:
    	    if key[-1] == '_': 
    	    	self.ml_Keys.append(key[0:-1])
    	    	self.ml_keys.append(key[0:-1])
    	    else:
    	    	self.ml_keys.append(key)
	                		
class C_SAX_XMLhandler(C_XMLhandler):
    def __init__(self, astr_xmlDBFile, al_keys, astr_boundingTag):
	C_XMLhandler.__init__(self, al_keys, astr_boundingTag)
	self.__name__ = 'C_SAX_XMLhandler'

        # Search-tag control.
        #+ A specific tag in the XML structure can be flagged as 
        #+ a search tag, with corresponding search text.
        self.mb_searchTagUse         = False         # Tag toggle
        self.mstr_searchTag          = ""            # Tag name
        self.mstr_searchString       = ""            # Tag value
        self.mb_dbChildFound         = 0             # Found in XML file
        
        saxparser			= make_parser()
        saxparser.setContentHandler(self)
        saxparser.parse(astr_xmlDBFile)
        
    def searchTag_define(self, astr_tag="", astr_target=""):
          """
          This specifies a 'searchTag'.
          
          PRECONDITIONS
          o The self.mdict_element structure must contain a tag = astr_tag
          
          POSTCONDITIONS
          o If searchTag could be successfully created, the mb_searchTagUse
            is set to true
            
          NOTE:
          o NOT USED CURRENTLY! Added for in-line searching while parsing
            the XML file.
          """
          self.mb_searchTagUse  = False
          if self.mdict_element.has_key(astr_tag):
            self.mstr_searchTag         = astr_tag
            self.mstr_target            = astr_target
            self.mb_searchTagUse        = True
          return self.mb_searchTagUse
          
    def b_searchTag_found(self):
          """
          Checks the internal self.mdict_element[mstr_searchTag] value
          against the mstr_target. If equal, return True, else False

	  NOTE:
	  o NOT USED CURRENTLY! Added for in-line searching while parsing
	    the XML file.
          """
          b_found       = False
          if self.mb_searchTagUse and \
             self.mdict_element[self.mstr_searchTag] == self.mstr_target:
            b_found     = True
          return b_found
	
    def internals_reset(self):
 	    for key in self.ml_keys :
 	    	if key in self.ml_Keys:
		    self.mdict_element[key]	= []
		else:
		    self.mdict_element[key]	= ''
		self.mbdict_inTag[key]	= False
		
		
    #		
    # The following callbacks are accessed by the xml.sax.ContentHandler
    # 	startElement()
    #	characters()
    #	endElement()
    def startElement(self, astr_tag, al_attrs):
    	    # print "%s: start" % astr_tag
	    if astr_tag	== self.mstr_boundingTag: self.mb_inRecord = True
	    for key in self.ml_keys:
		if astr_tag == key: 
                  self.mbdict_inTag[key]= True
                  if al_attrs.getLength():
                    ldict               = {}
                    for attrkey in al_attrs.keys():
                      asckey            = attrkey.encode('ascii')
                      value             = al_attrs[attrkey]
                      ldict[asckey]     = value.encode('ascii')
                # Add attributes?
		
    def characters(self, characters):
	    for key in self.ml_keys:
		if self.mbdict_inTag[key]:
		    if key in self.ml_Keys:
		    	self.mdict_element[key].append(characters)
		    else:
		    	self.mdict_element[key] += characters
							
    def endElement(self, astr_tag):
    	    #if astr_tag != self.mstr_boundingTag and astr_tag != 'db':
    	    #	print "%s: %s" % (astr_tag, self.mdict_element[astr_tag])
	    if astr_tag == self.mstr_boundingTag:
	    	# print "New record!"
	    	self.m_recordCount	+= 1
	    	self.mb_inRecord	= False
	    	str_recordKey		= '%s-%d' % (self.mstr_boundingTag, 
							self.m_recordCount)
	    	# print self.mdict_element
	    	self.mdict_XML[str_recordKey] = dict(self.mdict_element)
	    	# TODO: Increase speed/performance by searching if necessary
	    	# while parsing the endElement.
		self.internals_reset() 
	    else:
	    	for key in self.ml_keys:
		    if astr_tag == key:	self.mbdict_inTag[key]	= False
		    

		
		
