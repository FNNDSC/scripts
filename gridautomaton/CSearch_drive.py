#!/usr/bin/env python
# 

Gstr_searchDir	= "/var/www/localhost/htdocs/recipe-dist"
Gstr_synopsis 	= """
NAME

	CSearch_drive.py

SYNOPSIS

        CSearch_drive.py [-d <dir>] -s <searchExpr>
	

DESCRIPTION

	A simple 'driver' for a C_search class instance.
	
ARGUMENTS

	-d <dir> (optional - Default 'Gstr_searchDir')
	If specified, search the "Menu" directory
	
	-s <searchExpr>
	The expression to search for.

HISTORY

28 June 2007
o Initial development implementation.

08 July 2007
o Expansion

"""

import 	os
import	sys
import	getopt
import 	C_search

def synopsis_show():
	print "%s" % Gstr_synopsis

try:
        opts, remargs   = getopt.getopt(sys.argv[1:], 'd:s:')
except getopt.GetoptError:
        synopsis_show()
        sys.exit(1)

verbose         = 0
for o, a in opts:
        if(o == '-s'):
                Gstr_searchExpr = a
	if(o == '-d'):
		Gstr_searchDir	= a
        if(o == '-x'):
                synopsis_show()
                sys.exit(1)

CSearch = C_search.C_search_m4uXML(path=Gstr_searchDir)
CSearch.searchPath_append("/var/www/localhost/htdocs/menu-dist")

print CSearch

CSearch.searchSimple(Gstr_searchExpr)
CSearch.hits_htmlGenerate()

print CSearch.searchResults_get()
print "*******"
print CSearch.XMLResults_get()
print "*******"
print "hits = %d" % CSearch.hits_count()
