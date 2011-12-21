#!/usr/bin/env python
# 
# NAME
#
#	systemMisc
#
# DESCRIPTION
#
#	The 'systemMisc' module contains some helper functions to 
#	facilitate system-type interaction.
#
# HISTORY
#
# 05 April 2006
# o Initial design and coding.
#
# 14 December 2006
# o Added data handling convenience routines
#
# January 2008
# o Miscellaneous text / string handling
#

# System imports
import 		os
import 		sys
import		time
import		string
import          re
import          types
import          commands
from 		subprocess	import *
from            cStringIO       import StringIO
from            numpy           import *

def array2DIndices_enumerate(arr):
        """
        DESC
            Given a 2D array defined by arr, prepare an explicit list
            of the indices.
            
        ARGS
            arr        in                 2 element array with the first
                                          element the rows and the second
                                          the cols
        
        RET
            A list of explicit 2D coordinates.
        """
        
        rows            = arr[0]
        cols            = arr[1]
        arr_index       = zeros( (rows*cols, 2) )
        count           = 0
        for row in arange(0, rows):
           for col in arange(0, cols):
               arr_index[count] = array( [row, col])
               count = count+1
        return arr_index

def error_exit(         astr_func,
                        astr_action,
                        astr_error,
                        aexitCode):
        print "FATAL ERROR"
        print "\tSorry, some error seems to have occurred in <%s::%s>" \
                % ('systemMisc', astr_func)
        print "\tWhile %s"                                  % astr_action
        print "\t%s"                                        % astr_error
        print ""
        print "Returning to system with error code %d"      % aexitCode
        sys.exit(aexitCode)

def printf(format, *args):
	sys.stdout.write(format % args)

def list_removeDuplicates(alist):
    """
    Removes duplicates from an input list
    """
    #d = {}
    #print alist
    #for x in alist:
      #d[x] = x
    #alist = d.values()

    alist = list(set(alist))
    return alist

def b10_convertFrom(anum10, aradix, *args):
    """
        ARGS
        anum10            in      number in base 10
        aradix            in      convert <anum10> to number in base
                                  + <aradix>
        
        OPTIONAL
        forcelength       in      if nonzero, indicates the length
                                  + of the return array. Useful if
                                  + array needs to be zero padded.
        
        DESC
        Converts a scalar from base 10 to base radix. Return
        an array.
        
        NOTE:
        "Translated" from a MatLAB script of the same name.
    """
    i = 0;
    k = 0;
    
    # Cycle up in powers of radix until the largest exponent is found.
    # This is required to determine the word length
    while (pow(aradix,i)) <= anum10:
        i = i+1;
    forcelength = i

    # Optionally, allow user to specify word length
    if len(args): forcelength = args[0]

    # Check that word length is valid
    if(forcelength and (forcelength < i)):
        error_exit('b10_convertFrom',                    
                   'checking on requested return array', 
                   'specified length is too small',
                   1)

    numm = anum10;
    num_r = zeros((1, forcelength));
    if(i):
        k = forcelength - i;
    else:
        k = forcelength - 1;

    if(anum10==1):
        num_r[(0,k)] = 1;
        return num_r;

    for j in arange(i,0,-1):
        num_r[(0,k)] = fix(numm / pow(aradix,(j-1)));
        numm = numm % pow(aradix, (j-1));
        k = k+1;
    return num_r

def permutations_find(a_dimension, a_depth, *args):
    """
    
         SYNOPSIS
         
              [I, D] = permutations_find(a_dimension, a_depth, *args)
        
         ARGS
         
           INPUT
           a_dimension         int32           number of dimensions
           a_depth             int32           depth of neighbours to find
        
           OPTIONAL
           av_row              array           row vector that is optionally
                                               added to each I and D row. This
                                               is useful for expressing a 
                                               permutation in terms of an
                                               actual offset baseline vector.
           
           OUTPUT
           I                   cell           a cell array containing 
                                                  "indirect" neighbour 
                                                   information. Each index
                                                   of the cell array is a row - order
                                                   matrix of "index" distant
                                                   indirect neighbours
           D                   cell           a cell array containing 
                                                   "direct" neighbour 
                                                   information. Each index
                                                   of the cell array is a row - order
                                                   matrix of "index" distant
                                                   direct neighbours
        
         DESC
               This method determines the neighbours of a point in an
               n - dimensional discrete space. The "depth" (or ply) to
               calculate is `a_depth'.
        
               Indirect neighbours are non-orthogonormal.
               Direct neighbours are orthonormal.
               
               This operation is identical to finding all the permutations
               of a given set of elements.
        
        
         PRECONDITIONS
               o The underlying problem is discrete.
        
         POSTCONDITIONS
               o I cell array contains the Indirect neighbours
               o D cell array contains the Direct neighbours
               o size{I} = size{D}
               o size{I} = a_depth
        
         HISTORY
         20 December 2011
         o Translated from MatLAB script of same name.
         
    """
    if (a_depth<1):
        D       = None;
        I       = None;
        l_D     = []
        l_I     = {}
        return I, D;

    # Allocate space for neighbours structure
    D = zeros( (1, a_depth), dtype='object');
    I = zeros( (1, a_depth), dtype='object');
    l_D = [0] * a_depth
    l_I = [0] * a_depth

    # Pre-allocate internal data structures
    v_rowOffset     = zeros( (1, a_dimension) );
    b_rowOffset     = 0;
    if len(args):
        av_rowOffset = args[0];
        rows, cols   = av_rowOffset.shape
        if rows == 1 and size(av_rowOffset)==a_dimension:
            v_rowOffset     = av_rowOffset;
            b_rowOffset     = 1;

    d                   = 1;
    hypercube           = pow((2*d+1), a_dimension);
    hypercubeInner      = 1;
    orthogonals         = 2*a_dimension;
    l_D[0]              = zeros( (orthogonals, a_dimension) )
    l_I[0]              = zeros( (hypercube - orthogonals -1, a_dimension) );
    D[0,0]              = zeros( (orthogonals, a_dimension) );
    I[0,0]              = zeros( (hypercube - orthogonals -1, a_dimension) );
    for d in arange(1,a_depth):
        hypercubeInner  = hypercube;
        hypercube       = pow(2*d+1,a_dimension);
        l_D[d]          = zeros( (orthogonals, a_dimension) )
        l_I[d]          = zeros( (hypercube - orthogonals - hypercubeInner))
        D[0, d]          = zeros( (orthogonals, a_dimension) );
        I[0, d]          = zeros( (hypercube - orthogonals -
                                   hypercubeInner, a_dimension));
    # Offset and "current" vector
    M_bDoffset      = ones( (1, a_dimension) ) * -a_depth;
    M_current       = ones( (1, a_dimension) );
    M_currentAbs    = ones( (1, a_dimension) );

    # Index counters
    M_ii            = zeros( (1, a_depth) );
    M_dd            = zeros( (1, a_depth) );

    # Now we loop through *each* element of the last hypercube
    # and assign it to the appropriate matrix in the I,D structures
    for i in arange(0,hypercube):
        str_progress    = 'iteration %5d (of %5d) %3.2f' % \
                                (i, hypercube-1, i/(hypercube-1)*100);
        M_current       = b10_convertFrom(i, (2*a_depth+1), a_dimension);
        M_current       = M_current + M_bDoffset;
        M_currentAbs    = abs(M_current);
        neighbour       = max(max(M_currentAbs));
        if(sum(M_currentAbs) > neighbour):
            l_I[int(neighbour-1)][M_ii[0, neighbour-1]]   = M_current
            I[0,neighbour-1][M_ii[0, neighbour-1]]        = M_current;
            M_ii[0, neighbour-1] += 1;
        else: 
            if(sum(M_currentAbs) == neighbour and neighbour):
                l_D[int(neighbour-1)][M_dd[0, neighbour-1]]     = M_current
                D[0, neighbour-1][M_dd[0, neighbour-1]]         = M_current;
                M_dd[0, neighbour-1] += 1;

    if b_rowOffset:
        for layer in arange(0, neighbour):
            rowsI, colsI   = I[layer].shape;
            rowsD, colsD   = D[layer].shape;
            M_OI           = tile(v_rowOffset, (rowsI, 1));
            M_OD           = tile(v_rowOffset, (rowsD, 1));
            I[0, layer]    = I[0, layer] + M_OI;
            D[0, layer]    = D[0, layer] + M_OD;
    return l_I, l_D


def base10toN(num, n):
    """Change a num to a base-n number.
    Up to base-36 is supported without special notation."""
    num_rep={10:'a',
         11:'b',
         12:'c',
         13:'d',
         14:'e',
         15:'f',
         16:'g',
         17:'h',
         18:'i',
         19:'j',
         20:'k',
         21:'l',
         22:'m',
         23:'n',
         24:'o',
         25:'p',
         26:'q',
         27:'r',
         28:'s',
         29:'t',
         30:'u',
         31:'v',
         32:'w',
         33:'x',
         34:'y',
         35:'z'}
    new_num_string=''
    current=num
    while current!=0:
        remainder=current%n
        if 36>remainder>9:
            remainder_string=num_rep[remainder]
        elif remainder>=36:
            remainder_string='('+str(remainder)+')'
        else:
            remainder_string=str(remainder)
        new_num_string=remainder_string+new_num_string
        current=current/n
    return new_num_string

def list_i2str(ilist):
    """
    Convert an integer list into a string list.
    """
    slist = []
    for el in ilist:
        slist.append(str(el))
    return slist
        
"""
The attribute* set of functions process strings/dictionaries of the
form:

        <key1>=<value1> <key2>=<value2> <key3>=<value3>

the separator in the above string is a space, although this can
be somewhat arbitrary.
"""

def attributes_toStr(**adict_attrib):
        strIO_attribute = StringIO()
        for attribute in adict_attrib.keys():
            str_text = ' %s="%s"' % (attribute, adict_attrib[attribute])
            strIO_attribute.write(str_text)
        str_attributes = strIO_attribute.getvalue()
        return str_attributes

def attributes_dictToStr(adict_attrib):
        strIO_attribute = StringIO()
        for attribute in adict_attrib.keys():
            str_text = ' %s="%s"' % (attribute, adict_attrib[attribute])
            if len(adict_attrib[attribute]):
                strIO_attribute.write(str_text)
        str_attributes = strIO_attribute.getvalue()
        return str_attributes
        
def attributes_strToDict(astr_attributes, astr_separator = " "):
  """
  This is logical inverse of the dictToStr method. The <astr_attributes>
  string *MUST* have <key>=<value> tuples separated by <astr_separator>.
  """
  adict = {}
  alist = str2lst(astr_attributes, astr_separator)
  for str_pair in alist:
    alistTuple  = str2lst(str_pair, "=")
    adict.setdefault(alistTuple[0], alistTuple[1].strip(chr(0x22)+chr(0x27)))
  return adict

def str_blockIndent(astr_buf, a_tabs=1, a_tabLength=4):
    """
    For the input string <astr_buf>, replace each '\n'
    with '\n<tab>' where the number of tabs is indicated
    by <a_tabs> and the length of the tab by <a_tabLength>
    
    Trailing '\n' are *not* replaced.
    """
    b_trailN    = False
    length      = len(astr_buf)
    ch_trailN   = astr_buf[length-1]
    if ch_trailN == '\n': 
      b_trailN  = True
      astr_buf  = astr_buf[0:length-1]
    str_ret     = astr_buf
    str_tab     = ''
    str_Indent  = ''
    for i in range(a_tabLength):
        str_tab = '%s ' % str_tab
    for i in range(a_tabs):
        str_Indent  = '%s%s' % (str_Indent, str_tab)
    str_ret = re.sub('\n', '\n%s' % str_Indent, astr_buf)
    str_ret = '%s%s' % (str_Indent, str_ret)
    if b_trailN: str_ret = str_ret + '\n'
    return str_ret
			
def valuePair_fprint(astr_name, afvalue=None, leftCol=40, rightCol=40):
	if afvalue != None:
	    print '%*s:%*f' 	% (leftCol, astr_name, rightCol, afvalue)
	else:
	    printf('%*f', leftCol, astr_name)
def valuePair_sprint(astr_name, astr_value, leftCol=40, rightCol=40):
	if len(astr_value):
	    print '%*s:%*s' 	% (leftCol, astr_name, rightCol, astr_value)
	else:
	    printf('%*s', leftCol, astr_name)
def valuePair_dprint(astr_name, avalue=None, leftCol=40, rightCol=40):
	if avalue != None:
	    print '%*s:%*d' 	% (leftCol, astr_name, rightCol, avalue)
	else:
	    printf('%*d', leftCol, astr_name)
	
def html(astr_string, astr_tag = "p"):	
	print """
	<%s>
	%s
	</%s>
	""" % (astr_tag, astr_string, astr_tag)
	
def PRE(astr_string):
	print """
	<pre>
	%s
	</pre>
	""" % astr_string
	
def P(astr_string):
	print "<p>%s</p>" % astr_string

def system_eval(str_command, b_echoCommand = 0):
	if b_echoCommand: printf('<p>str_command = %s</p>', str_command)
	fp_stdout 	= os.popen(str_command)
	str_stdout	= ''
	while(1):
		str_line = fp_stdout.readline()
		if str_line:
			str_stdout = str_stdout + str_line
		else:
			break	
	if b_echoCommand: printf('<p>str_line = %s</p>', str_line)
	if b_echoCommand: printf('<p>str_stdout = %s</p>', str_stdout)
	return str_stdout
	
def system_pipeRet(str_command, b_echoCommand = 0):
	if b_echoCommand: printf('<p>str_command = %s</p>', str_command)
	fp_stdout 	= os.popen(str_command)
	str_stdout	= ''
	while(1):
		str_line = fp_stdout.readline()
		if str_line:
			str_stdout = str_stdout + str_line
		else:
			break
	retcode		= fp_stdout.close()	
	if b_echoCommand: printf('<p>str_line = %s</p>', str_line)
	if b_echoCommand: printf('<p>str_stdout = %s</p>', str_stdout)
	return retcode, str_stdout

def system_procRet(str_command, b_echoCommand = 0):
	if b_echoCommand: printf('<p>str_command = %s</p>', str_command)
	str_stdout	= os.popen(str_command).read()
	retcode		= os.popen(str_command).close()
	return retcode, str_stdout
	
def subprocess_eval(str_command, b_echoCommand = 0):
    if b_echoCommand: printf('%s', str_command)
    b_OK	= True
    retcode	= -1    
    p = Popen(string.split(str_command), stdout=PIPE, stderr=PIPE)
    str_stdout, str_stderr = p.communicate()
    try:
	str_forRet	= str_command + " 2>/dev/null >/dev/null"
	retcode 	= call(str_forRet, shell=True)
    except OSError, e:
	b_OK	= False
    return retcode, str_stdout, str_stderr
    
def getCommandOutput2(command):
    child = os.popen(command)
    data = child.read( )
    err = child.close( )
    if err:
        raise RuntimeError, '%r failed with exit code %d' % (command, err)
		
def file_exists(astr_fileName):
    try:
	fd	= open(astr_fileName)
	if fd: fd.close()
	return True
    except IOError:
	return False

def exefile_existsOnPath(astr_fileName):
	try:
		return open(astr_fileName)
	except IOError:
		return None

def str_dateStrip(astr_datestr, astr_sep = '/'):
  """
  Simple date strip method. Checks if the <astr_datestr>
  contains <astr_sep>. If so, strips these from the string
  and returns result.
  
  The actual stripping entails falling through two layers
  of exception handling... so it is something of a hack.
  """
  try:
    index = astr_datestr.index(astr_sep)
  except:
    return astr_datestr.encode('ascii')
  
  try:
    tm  = time.strptime(astr_datestr, '%d/%M/%Y')
  except:
    try:
      tm = time.strptime(astr_datestr, '%d/%M/%y')
    except:
      error_exit('str_dateStrip', 'parsing date string',
                 'no conversion was possible', 1)
  tstr = time.strftime("%d%M%Y", tm)
  return tstr.encode('ascii')

def currentDate_formatted(astr_format = 'US', astr_sep = '/'):
	str_year 	= time.localtime()[0]
    	str_month 	= time.localtime()[1]
    	str_day		= time.localtime()[2]
	if astr_format	== 'US':
	    str_date	= '%02d%s%02d%s%s' % \
	    	(str_month, astr_sep, str_day, astr_sep, str_year)
	else:
	    str_date	= '%s%s%02d%s%02d' % \
	    	(str_year, astr_sep, str_month, astr_sep, str_day)
	return string.strip(str_date)

def dict_init(al_key, avalInit = None):
  adict = {}
  if type(avalInit) is types.ListType:
      adict = dict(zip(al_key, avalInit))
  else:
      adict = dict.fromkeys(al_key, avalInit)
  return adict
  
def str2lst(astr_input, astr_separator=" "):
  """
  Breaks a string at <astr_separator> and joins into a 
  list. Steps along all list elements and strips white
  space.

  The list elements are explicitly ascii encoded.
  """
  alistI        = astr_input.split(astr_separator)
  alistJ        = []
  for i in range(0, len(alistI)):
    alistI[i]   = alistI[i].strip()
    alistI[i]   = alistI[i].encode('ascii')
    if len(alistI[i]):
      alistJ.append(alistI[i])
  return alistJ

def make_xlat(*args, **kwds):
  """
  Replaces multiple patterns in a single pass.
  From "Python Cookbook", O'Reilly, pg39
  
  USAGE:
  translate     = make_xlat(adict)
  translate(text)
  """
  adict = dict(*args, **kwds)
  rx    = re.compile("|".join(map(re.escape, adict)))
  def one_xlat(match):
    return adict[match.group(0)]
  def xlat(text):
    return rx.sub(one_xlat, text)
  return xlat



