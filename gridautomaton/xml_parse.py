#!/usr/bin/env python
#

Gstr_fileDB        = '../htdocs/fileDB.xml'
Gstr_cgiBase        = '/srv/www'
Gstr_handler        = 'sax'
Gb_split        = 0

Gstr_synopsis         = """
NAME

        xml_parse.py

SYNOPSIS

        xml_parse.py [-b <cgiBase>] [-i <idCode> [-f <dataBase>] [-h sax|dom]] [-S]

DESCRIPTION

        This is a simple "driver" that processes a monolithic
        'm4u' XML recipe database. 
        
        The driver operates in one of two modes:
         
                o Search (-i ...)
                Retrieve the specified <idCode> from the monolithic
                database. You can select to use either the fast
                'sax' method, or the slower 'dom' method.
                
                o Split (-S)
                This uses a SAX approach to splitting each individual
                recipe in the monolithic database into its own
                file.

        Its main purpose is simply to provide a platform to develop
        the necessary machinary to interact with the monolithic 
        XML database.

ARGUMENTS
        
        -b <cgiBase>
        The base cgi dir on the localhost.
        
        -i <idCode>
        The search term (idCode) to find in the database.
        
        -f <dataBase> (optional - will default to '../htdocs/fileDB.xml')
        The input (monolithic) XML database to parse. 
        
        -h sax|dom
        Choose the handler: sax or dom.
        
        -S
        Split the database into constituent components. The <-i> and <-h>
        flags are ignored.

HISTORY

31 May 2006
        o Initial design and coding.

11 July 2006
        o Fleshed out command line arguments.

September 2006
        o DOM extensions
        o Split front end
        
11 April 2007
        o removed explicit dependency on specific internal structure.
        o abstracted to more general kedasa structure.

"""

# System imports
import         os
import         sys
import         getopt
from        xml.sax                import        make_parser
from         xml_handlers        import        C_SAX_kXMLHandler
from         xml_handlers        import        C_DBsplit_SAX_kXMLHandler
from        xml_handlers        import         C_DOM_kXMLHandler
from        m4uRecipe        import         *

# 3rd party imports

# Project imports

def synopsis_show(void=0):
        print Gstr_synopsis

try:
        opts, remargs   = getopt.getopt(sys.argv[1:], 'b:i:f:h:Sx')
except getopt.GetoptError:
        synopsis_show()
        sys.exit(1)

Gstr_idCode        = "LSP-050"
verbose         = 0
for o, a in opts:
        if(o == '-b'):
                Gstr_cgiBase        = a
        if(o == '-i'):
                Gstr_idCode        = a
        if(o == '-f'):
                Gstr_fileDB        = a
        if(o == '-h'):
                Gstr_handler        = a 
        if(o == '-S'):
                Gb_split        = 1 
        if(o == '-x'):
                synopsis_show()
                sys.exit(1)
                
Gc_m4u        = C_m4uRecipe()
if Gstr_handler == 'sax' and not Gb_split:
        c_SAXhandler                = C_SAX_kXMLHandler(Gc_m4u, "recipe")
        saxparser                = make_parser()
        c_SAXhandler.idCode_setTarget(Gstr_idCode)
        saxparser.setContentHandler(c_SAXhandler)
        saxparser.parse(Gstr_fileDB)

        m4u_HTML                = C_m4uRecipe_HTML('./global.css')
        m4u_HTML.mdict_sgmlCore        = c_SAXhandler.m4u.mdict_sgmlCore
        m4u_HTML.prettyPrint()
elif Gstr_handler == 'dom' and not Gb_split:
        c_DOMhandler                = C_DOM_kXMLHandler(Gc_m4u, "recipe")
        c_DOMhandler.parse(Gstr_fileDB)
        b_removeRecipeFromDB        = 1
        c_DOMhandler.element_extractFirst()
        print c_DOMhandler.mdict_element
        #c_DOMhandler.elements_list(['idCode', 'title', 'author', 'ingredients'])
        #c_DOMhandler.element_extract('idCode', Gstr_idCode, b_removeRecipeFromDB)
        
        #m4u_HTML                = C_m4uRecipe_HTML('./global.css')
        #m4u_HTML.mdict_sgmlCore        = c_DOMhandler.m4u.mdict_sgmlCore
        #m4u_HTML.prettyPrint()

if Gb_split:
        #
        # The "split" operation parses a monolithic xml data base
        # and separates into multiple smaller files. Each file is
        # an xml database containing a single entry.
        #
        # The "split" is a temporary and highly customized operation
        # geared specifically towards monolithic m4u recipe XML databases.
        #
        c_SAXhandler                = C_DBsplit_SAX_kXMLHandler(Gc_m4u, "recipe", "recipe-XMLDB", Gstr_cgiBase)
        saxparser                = make_parser()
        saxparser.setContentHandler(c_SAXhandler)
        saxparser.parse(Gstr_fileDB)
        print "Successfully split %d entries from the original database" % \
                c_SAXhandler.m_mainTagCount
        
