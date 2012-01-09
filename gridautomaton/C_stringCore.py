#!/usr/bin/env python
"""
NAME

        C_stringCore

DESCRIPTION
	
        'C_stringCore' is a wrapper about a python cStringIO
        class. It provides means to write/read to and from
        a StringIO contents.

NOTES

HISTORY

06 February 2008
o Design consolidated from several sources.

"""

# System modules
import 	os
import 	sys
from 	string 		import 	*
from 	cStringIO 	import 	StringIO
from 	cgi 		import 	*

class C_stringCore:
	"""
	This class is a wrapper about a cStringIO instance, keeping
        track of an internal file-string instance and syncing its
        contents to an internal string buffer.
        """
	# 
	# Member variables
	#
	# 	- Core variables
	mstr_obj	= 'C_stringCore';	# name of object class
        mstr_name	= 'void';		# name of object variable
        m_id		= -1; 			# id of agent
        m_iter		= 0;			# current iteration in an
                                		# 	arbitrary processing 
						#	scheme
        m_verbosity	= 0;			# debug related value for 
						#	object
        m_warnings	= 0;              	# show warnings 
						#	(and warnings level)
	
	#
	#	- Class variables
	mstr_core		= ""		# The actual HTML core of
						#	the region
	mStringIO		= None		# A file string buffer that
						# 	functions as a 
						#	scratch space for
						#	the core
	
	#
	# Methods
	#
	# Core methods - construct, initialise, id
	def core_construct(	self,
				astr_obj	= 'C_core',
				astr_name	= 'void',
				a_id		= -1,
				a_iter		= 0,
				a_verbosity	= 0,
				a_warnings	= 0) :
		self.mstr_obj		= astr_obj
		self.mstr_name		= astr_name
		self.m_id		= a_id
		self.m_iter		= a_iter
		self.m_verbosity	= a_verbosity
		self.m_warnings		= a_warnings
	def __str__(self):
		print 'mstr_obj\t\t= %s' 	% self.mstr_obj
		print 'mstr_name\t\t= %s' 	% self.mstr_name
		print 'm_id\t\t\t= %d' 		% self.m_id
		print 'm_iter\t\t\t= %d'	% self.m_iter
		print 'm_verbosity\t\t= %d'	% self.m_verbosity
		print 'm_warnings\t\t= %d'	% self.m_warnings
		return 'This class functions as a string file handler.'
	def __init__(self):
		self.core_construct()
		self.mstr_core	        = ""
		self.mStringIO		= StringIO()
		
	
	#
	# core methods
        def strout(self, astr_text=""):
            if(len(astr_text)): 
                self.write(astr_text)
                print "%s" % self.strget()
	def reset(self, astr_newCore = ""):
	    self.mStringIO.close()
	    self.mstr_core	= astr_newCore
	    self.mStringIO 	= StringIO()
            self.mStringIO.write(astr_newCore)
        def strget(self):
            return self.mStringIO.getvalue()
	def dump(self):
            print "%s" % self.strget()
	def write(self, astr_text):
            if isinstance(astr_text, list):
              astr_text         = '\n'.join(astr_text)
	    self.mStringIO.write(astr_text)
            self.mstr_core      = self.strget()
            return astr_text
            
		