#!/usr/bin/env python
# 

Gstr_inputFile		= "-x"
Gstr_outputFile		= "-x"
Gstr_INseparator	= ""
Gstr_OUTseparator	= " "
Gi_numberFields		= 0

Gstr_synopsis 	= """
NAME

	tp.py

SYNOPSIS

        tp.py			-i <inputFile>				\\
	 			[-s <inputLineElementSep>]		\\
				[-S <outputLineElementSep>]		\\
				[-o <outputFile>]			\\
				[-n <numberFields>]
	

DESCRIPTION

	'tp.py' is a text file "transposer". An <inputFile> is flipped
	(i.e. transposed) so that all row elements become column elements
	and all columns become rows.
	
	Output is stored by default in <inputFile>.tp or in <outputFile>
	if specified on command line.
	
ARGUMENTS

	-i <inputFile>
	The file to transpose.
	
	-s <inputElementSep> (optional field separator in input rows)
	Defaults to white space. This defines the separation string between
	each element in each row of the <inputFile>. For an '/etc/passwd'
	file, for example, this would be the ":" string. 
	
	-S <outputLineElementSep> (optional field separator in output rows)
	Defaults to space. If specified, defines the separation between
	each element in each row of the <outputFile>.
	
	-o <outputFile> (optional output filename)
	If omitted, the output file is simply <inputFile>.tp, otherwise
	the output is written to <outputFile>.
	
	-n <numberFields> (optional field number in input)
	If specified, only process input lines that contain <numberFields>
	fields (list elements). Useful if input lines parse to variable
	lengths, for example comments embedded in a file header.
	
PRECONDITIONS

	o Each row of the input file must contain a constant number of
	  elements. If variable-length elements in input rows, the
	  <numberFields> specifier can be used to only process rows
	  of <numberFields> length.
	
POSTCONDITIONS

	o Each row of the <inputFile> is stored as a column in the
	  <outputFile>.

HISTORY

27 June 2008
o Initial development implementation.

"""

import 	os
import	sys
import	getopt

def synopsis_show():
    print "%s" % Gstr_synopsis

try:
        opts, remargs   = getopt.getopt(sys.argv[1:], 'i:o:s:S:n:')
except getopt.GetoptError:
        synopsis_show()
        sys.exit(1)

verbose         = 0
for o, a in opts:
        if(o == '-s'):
		Gstr_INseparator	= a
        if(o == '-S'):
		Gstr_OUTseparator	= a
        if(o == '-i'):
		Gstr_inputFile		= a
        if(o == '-o'):
		Gstr_outputFile		= a
        if(o == '-n'):
		Gstr_val		= a
		try:
			Gi_numberFields	= int(Gstr_val)
		except ValueError:
			print "Must specify integer number of fields."
			sys.exit(10)			
	if(o == '-x'):
                synopsis_show()
                sys.exit(1)

if Gstr_inputFile == "-x":
	print "Input file must be specified with '-i <inputFile>'."
	print "Need help? Try starting with '-x'."
	sys.exit(1)

l_inputLine	= []
l_inputProc	= []
try:
	l_inputLine = map(str.strip, open(Gstr_inputFile).readlines())
except IOException:
	print "Input file <%s> raised an exception. Does it exist?\n" % Gstr_inputFile
	sys.exit(11)
	
if Gstr_outputFile == "-x": Gstr_outputFile = "%s.tp" % Gstr_inputFile

lines	= len(l_inputLine)
for i in range(0, lines):
    if(len(Gstr_INseparator)):
	l_inputLine[i]	= l_inputLine[i].split(Gstr_INseparator)
    else:	
	l_inputLine[i]	= l_inputLine[i].split
    if Gi_numberFields:
	    if len(l_inputLine[i]) == Gi_numberFields:
		    l_inputProc.append(l_inputLine[i])
    else:
	    l_inputProc.append(l_inputLine[i])
	     
l_outputLine	= map(list, zip(*l_inputProc))

FILEout		= open(Gstr_outputFile, 'w')
for line in l_outputLine:
	FILEout.write(Gstr_OUTseparator.join(line))
	FILEout.write('\n')

