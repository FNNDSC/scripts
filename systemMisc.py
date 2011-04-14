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

def error_exit(         astr_func,
                        astr_action,
                        astr_error,
                        aexitCode):
        print "%s: FATAL ERROR"
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



