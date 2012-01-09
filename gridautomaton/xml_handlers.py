#!/usr/bin/env python
# 
# NAME
#
#        xml kedasa-derived handler classes
#
# DESCRIPTION
#
#        This module contains a "base" XML kedasa content handler as well as
#        SAX- and DOM-based specialisations.
#
# PRECONDITIONS
#
#        These classes are built on an underlying "data" class that contains
#        information about the xml structure of the documents being parsed
#        (kedasa).
#
# HISTORY
#
# 31 May 2006
# o Initial development implementation - adapted from Chapter 3 of
#   "Python & XML" by C.A. Jones and F.L. Drake, 2002
#
# 11 July 2006
# o Class hierarchy development and consolidation.
#
# 11 April 2007
# o Dependency on underlying 'kedasa' classes generalized.
#

import        sys

from        xml.sax                        import        make_parser
from        xml.sax.handler                import        ContentHandler
from        xml.dom.ext.reader.Sax2        import        FromXmlStream
from        xml.dom.ext                import        PrettyPrint

from        kedasa                        import         *

class C_kXMLHandler(ContentHandler):
        # 
        # Member variables
        #
        #         - Core variables
        mstr_obj        = 'C_kXMLHandler';        # name of object class
        mstr_name        = 'void';                # name of object variable
        m_id                = -1;                         # id of agent
        m_iter                = 0;                        # current iteration in an
                                                #         arbitrary processing 
                                                #        scheme
        m_verbosity        = 0;                        # debug related value for 
                                                #        object
        m_warnings        = 0;                      # show warnings 
                                                #        (and warnings level)
        
        #
        #        - Class variables
        #        Core variables - specific
        mC_struct        = C_kedasa();
        mb_paren2tag   = False                  # a control flag. If True
                                                #+ convert '{' to '<' and
                                                #+ '}' to '<' in the tag
                                                #+ value string
                                                
        mstr_XMLfile        = ''
        mstr_mainTag        = ''                        # the main child tag for the
                                                #        particular XML file
        mb_inRecord     = False
        mdict_element   = {}
        mbdict_inTag    = {}
        
        #
        # Methods
        #
        # Core methods - construct, initialise, id
        def core_construct(        self,
                                astr_obj        = 'C_kXMLHandler',
                                astr_name        = 'void',
                                a_id                = -1,
                                a_iter                = 0,
                                a_verbosity        = 0,
                                a_warnings        = 0) :
                self.mstr_obj                = astr_obj
                self.mstr_name                = astr_name
                self.m_id                = a_id
                self.m_iter                = a_iter
                self.m_verbosity        = a_verbosity
                self.m_warnings                = a_warnings
                self.internals_reset()
        
        def __str__(self):
                print 'mstr_obj\t\t= %s'         % self.mstr_obj
                print 'mstr_name\t\t= %s'         % self.mstr_name
                print 'm_id\t\t\t= %d'                 % self.m_id
                print 'm_iter\t\t\t= %d'        % self.m_iter
                print 'm_verbosity\t\t= %d'        % self.m_verbosity
                print 'm_warnings\t\t= %d'        % self.m_warnings
                return 'This class is the base definition for the XML kXML handlers.'
        
        def __init__(self, aC_struct, astr_mainTag = ""):
                self.mC_struct                = aC_struct
                self.mstr_mainTag        = astr_mainTag        
                self.core_construct()
                
        def paren2tag_replace(self, astr_key):
          str_value                     = self.mdict_element[astr_key]
          str_value                     = str_value.replace('{', '<')
          str_value                     = str_value.replace('}', '>')
          self.mdict_element[astr_key]  = str_value
          
                                
class C_SAX_kXMLHandler(C_kXMLHandler):
        # 
        # Member variables
        #
        #         - Core variables
        mstr_obj        = 'C_SAX_kXMLHandler';        # name of object class
        mstr_name        = 'void';                # name of object variable
        m_id                = -1;                         # id of agent
        m_iter                = 0;                        # current iteration in an
                                                #         arbitrary processing 
                                                #        scheme
        m_verbosity        = 0;                        # debug related value for 
                                                #        object
        m_warnings        = 0;                      # show warnings 
                                                #        (and warnings level)
        
        #
        #        - Class variables
        #        Core variables - specific

        # Search-tag control.
        #+ A specific tag in the XML structure can be flagged as 
        #+ a search tag, with corresponding search text.
        mb_searchTagUse         = False         # Tag toggle
        mstr_searchTag          = ""            # Tag name
        mstr_searchString       = ""            # Tag value
        mb_dbChildFound         = 0             # Found in XML file
        
        #mstr_idCode             = "LSP-000"

        def searchTag_define(self, astr_tag="", astr_target=""):
          """
          This specifies a 'searchTag'.
          
          PRECONDITIONS
          o The self.mdict_element structure must contain a tag = astr_tag
          
          POSTCONDITIONS
          o If searchTag could be successfully created, the mb_searchTagUse
            is set to true
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
          """
          b_found       = False
          if self.mb_searchTagUse and \
             self.mdict_element[self.mstr_searchTag] == self.mstr_target:
            b_found     = True
          return b_found
                
        def idCode_setTarget(self, astr_target):
          """
          A historical and obsolete call using an old model of
          search-tag checking.
          """
          self.searchTag_define("idCode", astr_target)
          #self.mstr_idCode        = astr_target


        #
        # Methods
        #
        # Core methods - construct, initialise, id
        def core_construct(        self,
                                astr_obj        = 'C_SAX_kXMLHandler',
                                astr_name        = 'void',
                                a_id                = -1,
                                a_iter                = 0,
                                a_verbosity        = 0,
                                a_warnings        = 0) :
                self.mstr_obj                = astr_obj
                self.mstr_name                = astr_name
                self.m_id                = a_id
                self.m_iter                = a_iter
                self.m_verbosity        = a_verbosity
                self.m_warnings                = a_warnings
                self.internals_reset()
        
        
        def internals_reset(self):
             for key in self.mC_struct.ml_keys :
                self.mdict_element[key]        = ''
                self.mbdict_inTag[key]        = False
                
        def __str__(self):
                print 'mstr_obj\t\t= %s'         % self.mstr_obj
                print 'mstr_name\t\t= %s'         % self.mstr_name
                print 'm_id\t\t\t= %d'                 % self.m_id
                print 'm_iter\t\t\t= %d'        % self.m_iter
                print 'm_verbosity\t\t= %d'        % self.m_verbosity
                print 'm_warnings\t\t= %d'        % self.m_warnings
                return 'This class is a SAX specialisation of the XML kXMLHandler.'
        
        def __init__(self, aC_struct, astr_mainTag):
                C_kXMLHandler.__init__(self, aC_struct, astr_mainTag)
                self.core_construct()        
        
        def startElement(self, astr_tag, al_attrs):
            #print "%s: start" % astr_tag
            if astr_tag        == self.mstr_mainTag: mb_inRecord = True
            for key in self.mC_struct.ml_keys:
                if astr_tag == key: 
                  self.mbdict_inTag[key]= True
                  if al_attrs.getLength():
                    ldict               = {}
                    for attrkey in al_attrs.keys():
                      asckey            = attrkey.encode('ascii')
                      value             = al_attrs[attrkey]
                      ldict[asckey]     = value.encode('ascii')
                    self.mC_struct.mdict_sgmlCore[key].attributes_setDict(ldict)
                # Add attributes?
                
        def characters(self, characters):
            for key in self.mC_struct.ml_keys:
                if self.mbdict_inTag[key]:        
                    self.mdict_element[key] += characters
                                                        
        def endElement(self, astr_tag):
            #print "%s: end" % astr_tag
            if astr_tag == self.mstr_mainTag:
                self.mb_inRecord        = False
                if not self.mb_searchTagUse or self.b_searchTag_found():
                #if self.mdict_element["idCode"] == self.mstr_idCode:
                        #print "****************************************"
                    for key in self.mC_struct.ml_keys:
                        if self.mb_paren2tag: self.paren2tag_replace(key)
                        str_value       = self.mdict_element[key]
                        self.mC_struct.mdict_sgmlCore[key].value_set(str_value)
                        #print "%40s : %30s" % (key, self.mdict_element[key])
                        self.mb_dbChildFound = 1;
                self.internals_reset() 
            else:
                for key in self.mC_struct.ml_keys:
                    if astr_tag == key:        self.mbdict_inTag[key]        = False
                    
class C_DBsplit_SAX_kXMLHandler(C_SAX_kXMLHandler):
        """
        A derived class that "splits" a monolithic XML database
        into many constituent "stand-alone" files        
        
        NOTE
        o This class is *very* specific to the particular implementation
          of the monolithic m4u recipe structure.
        """                    
        #
        #        - Class variables
        #        Core variables - specific
        m_mainTagCount        = 0
        mFileDBOutput        = None
        
        def __str__(self):
                print 'mstr_obj\t\t= %s'         % self.mstr_obj
                print 'mstr_name\t\t= %s'         % self.mstr_name
                print 'm_id\t\t\t= %d'                 % self.m_id
                print 'm_iter\t\t\t= %d'        % self.m_iter
                print 'm_verbosity\t\t= %d'        % self.m_verbosity
                print 'm_warnings\t\t= %d'        % self.m_warnings
                return 'This class is a SAX-based XML db "splitter".'
        
        def __init__(        self, aC_struct, astr_mainTag, 
                        astr_configHeader='recipe-XMLDB', astr_cgiBase='/var/www/localhost'):
                C_kXMLHandler.__init__(self, aC_struct, astr_mainTag)
                self.core_construct()
                self.mFileDBOutput                = C_xmlDB(aC_struct, 
                                                          astr_configHeader,
                                                          astr_cgiBase)
        
        def endElement(self, astr_tag):
            if astr_tag == self.mstr_mainTag:
                self.mb_inRecord        = False
                str_localpath                 = '%s.xml' % self.mdict_element["idCode"]
                print "Splitting: %s" % str_localpath
                for key in self.mC_struct.ml_keys:
                    self.mC_struct.mdict_sgmlCore[key].value_set(self.mdict_element[key])
                self.m_mainTagCount += 1;
                # Populate internal memory with contents parsed from monolithic
                self.mFileDBOutput.mdict_sgmlCore= self.mC_struct.mdict_sgmlCore
                # Note that the XML_save() call is mono/distributed aware...
                self.mFileDBOutput.XML_save()                
                self.internals_reset() 
            else:
                for key in self.mC_struct.ml_keys:
                    if astr_tag == key:        self.mbdict_inTag[key]        = False

#
# Basic operation: read the idCode into SGML Core. Remove from the
# DOM hierarchy, save the hierarchy, and return to main program.
#
class C_DOM_kXMLHandler(C_kXMLHandler):
        # 
        # Member variables
        #
        #         - Core variables
        mstr_obj        = 'C_DOM_kXMLHandler';        # name of object class
        mstr_name        = 'void';                # name of object variable
        m_id                = -1;                         # id of agent
        m_iter                = 0;                        # current iteration in an
                                                #         arbitrary processing 
                                                #        scheme
        m_verbosity        = 0;                        # debug related value for 
                                                #        object
        m_warnings        = 0;                      # show warnings 
                                                #        (and warnings level)
        
        #
        #        - Class variables
        #        Core variables - specific
        mXMLdoc                = None

        #
        # Methods
        #
        # Core methods - construct, initialise, id
        def core_construct(        self,
                                astr_obj        = 'C_DOM_kXMLHandler',
                                astr_name        = 'void',
                                a_id                = -1,
                                a_iter                = 0,
                                a_verbosity        = 0,
                                a_warnings        = 0) :
                self.mstr_obj                = astr_obj
                self.mstr_name                = astr_name
                self.m_id                = a_id
                self.m_iter                = a_iter
                self.m_verbosity        = a_verbosity
                self.m_warnings                = a_warnings
                self.internals_reset()
        
        def internals_reset(self):
             for key in self.mC_struct.ml_keys :
                self.mdict_element[key]        = ''
                self.mbdict_inTag[key]        = False
                
        def __str__(self):
                print 'mstr_obj\t\t= %s'         % self.mstr_obj
                print 'mstr_name\t\t= %s'         % self.mstr_name
                print 'm_id\t\t\t= %d'                 % self.m_id
                print 'm_iter\t\t\t= %d'        % self.m_iter
                print 'm_verbosity\t\t= %d'        % self.m_verbosity
                print 'm_warnings\t\t= %d'        % self.m_warnings
                return 'This class is a DOM specialisation of the XML kXMLHandler.'
        
        def __init__(self, aC_struct, astr_mainTag):
                C_kXMLHandler.__init__(self, aC_struct, astr_mainTag)
                self.core_construct()
                
        def parse(self, astr_inputStream):
                #sys.stdout.write("%40s" % "Parsing XML document...")
                sys.stdout.flush()
                self.mXMLdoc          = FromXmlStream(astr_inputStream)
                self.mstr_XMLfile = astr_inputStream        
                #print "%40s\n" % "[ ok ]"
        
        def elements_listAll(self, alstr_tag):
                #
                # PRECONDITIONS
                # o alstr_tag is a list of text tag names
                #
                # POSTCONDITIONS
                # o Each tag in the passed list is found in the XML database
                #   and its text value printed. This is across all the 
                #   entries in the XML database.
                #
                for database in self.mXMLdoc.childNodes:
                    for dbChild in database.childNodes:
                        for record in dbChild.childNodes:
                            if record.nodeType == record.ELEMENT_NODE:
                                str_tag = record.tagName
                                if str_tag in alstr_tag:
                                    for value in record.childNodes:
                                        if value.nodeType == value.TEXT_NODE:
                                            str_data = value.data
                                            print "%s:\t%s" % (str_tag, str_data)
                                            
        def element_extract(self, astr_tag, astr_value, ab_removeElement = 0):
                #
                # PRECONDITIONS
                # o str_tag is a tag name to search for
                # o str_value is the value of the tag to extract
                #
                # POSTCONDITIONS
                #         - element_extract('idCode', 'LSP-001')
                #          will extract the node (and its children) containing 
                #          an 'idCode' of 'LSP-001'
                #        - if <ab_removeElement>, then the dbChild containing the
                #          target tag value is removed from the database.
                #
                
                b_targetFound        = 0
                for database in self.mXMLdoc.childNodes:
                    for dbChild in database.childNodes:
                        for record in dbChild.childNodes:
                            if record.nodeType == record.ELEMENT_NODE:
                                str_tag = record.tagName
                                for value in record.childNodes:
                                    if value.nodeType == value.TEXT_NODE:
                                        str_data = value.data
                                self.mdict_element[str_tag] = str_data
                                if str_tag == astr_tag and str_data == astr_value:
                                    b_targetFound = 1
                        if b_targetFound:                        
                            for key in self.mC_struct.ml_keys:
                                self.mC_struct.mdict_sgmlCore[key].value_set(self.mdict_element[key])
                            if ab_removeElement:
                                database.removeChild(dbChild)
                                str_edittedDBName        = "%s.edt" % self.mstr_XMLfile
                                file_edittedDBName        = open(str_edittedDBName, 'w')
                                PrettyPrint(self.mXMLdoc, file_edittedDBName)
                            return b_targetFound
                return b_targetFound
                                                                        
        def element_extractFirst(self):
                #
                # PRECONDITIONS
                # o Assumes primarily that the XML database consists of a single entry
                #   as in the case of the distributed database. Will still work on an
                #   input monolithic database, though.
                #
                # o Design was derived from the monolithic case, so some extra looping
                #   and redundant flags are present.
                #
                # POSTCONDITIONS
                # o Reads the first element in the XML database and populates internal
                #   kedasa structure.
                #
                # NOTE:
                # o Does not properly handle attribute lists.
                #
                
                b_targetFound        = 0
                b_tagValueFound = 0
                dataCount       = 0
                for database in self.mXMLdoc.childNodes:
                    for dbChild in database.childNodes:
                        for record in dbChild.childNodes:
                            if record.nodeType == record.ELEMENT_NODE:
                                str_tag = record.tagName
                                for value in record.childNodes:
                                    if value.nodeType == value.TEXT_NODE:
                                        str_data        = value.data
                                        b_tagValueFound = 1
                                if b_tagValueFound:
                                    self.mdict_element[str_tag] = str_data
                                    self.mC_struct.mdict_sgmlCore[str_tag].value_set(str_data)
                                    b_tagValueFound     = 0
                                    dataCount += 1
                                b_targetFound = 1
                return dataCount
        
        def element_listFirst(self, alstr_tag):
                #
                # PRECONDITIONS
                # o alstr_tag is a list of text tag names
                #
                # POSTCONDITIONS
                # o Each tag in the passed list is found in the XML document
                #   and its text value printed.
                #
                
                l_data         = []
                i        = 0
                                
                for str_tag in alstr_tag:
                    l_data.append([])
                    for tag in self.mXMLdoc.getElementsByTagName(str_tag):
                        b_hit         = 1
                        tag.normalize()
                        l_data[i].append(tag.firstChild.data)
                    i = i + 1
                        
                for j in range(0, i):
                        print l_data[j][0]
                        
                
                
