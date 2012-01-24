# NAME
#
#	C_spectrum
#
# DESCRIPTION
#
#	'C_spectrum' is the atom class that defines grid-based
#	"spectra". Each group cluster from an arbitrary analysis
#	can be thought of as a specific spectral harmonic. This class
#	abstracts the management of these spectra.
#
#
# HISTORY
#
# 24 March 2011
# o Initial development implementation.
#

# System imports
import 	os
import 	os.path
import 	sys
import	string
import	types
import	itertools

import	numpy		as np
import 	copy

import	systemMisc	as misc

class C_spectrum :
	# 
	# Class member variables -- if declared here are shared
	# across all instances of this class
	#
	mdictErr = {
	    'Keys'	  : {
		'action'	: 'initializing base class, ', 
		'error'	 	: 'it seems that no member keys are defined.', 
		'exitCode'      : 10},
	    'Save'	      : {
		'action'	: 'attempting to pickle save self, ',
		'error'	 	: 'a PickleError occured',
		'exitCode'      : 12},
            'SaveMat'           : {
                'action'        : 'attempting to save MatLAB friendly spectrum, ',
                'error'         : 'an IOerror occured',
                'exitCode'      : 13},
	    'Load'              : {
	        'action'        : 'attempting to pickle load object, ',
	        'error'         : 'a PickleError occured',
	        'exitCode'      : 14}
	}
	
	#
	# Methods
	#
	# Core methods - construct, initialise, id
	
	def error_exit(		self,
				astr_key,
				ab_exitToOs = 1
				):
	    print "%s:: FATAL ERROR" % self.mstr_obj
	    print "\tSorry, some error seems to have occurred in <%s::%s>" \
	    		% (self.__name__, self.mstr_def)
	    print "\tWhile %s" 		% C_spectrum.mdictErr[astr_key]['action']
	    print "\t%s"		% C_spectrum.mdictErr[astr_key]['error']
	    print ""
	    if ab_exitToOs:
	    	print "Returning to system with error code %d" % \
	    				  C_spectrum.mdictErr[astr_key]['exitCode']
	        sys.exit(C_spectrum.mdictErr[astr_key]['exitCode'])
	    return C_spectrum.mdictErr[astr_key]['exitCode']

	def fatal(self, astr_key, astr_extraMsg=""):
	    if len(astr_extraMsg): print astr_extraMsg
	    self.error_exit( astr_key)
	
	def warn(self, astr_key, astr_extraMsg=""):
	    b_exitToOS  = 0
	    if len(astr_extraMsg): print astr_extraMsg
	    self.error_exit( astr_key, b_exitToOS)
	    
	def core_construct(	self,
				astr_obj	= 'C_spectrum',
				astr_name	= 'void',
				a_id		= -1,
				a_iter		= 0,
				a_verbosity	= 0,
				a_warnings	= 0) :
		if not len(self.ml_keys):
		    self.error_exit("initializing base class",
				    "Class has no spectrum keys defined", 
				    1)
		self.mstr_obj		= astr_obj
		self.mstr_name		= astr_name
		self.m_id		= a_id
		self.m_iter		= a_iter
		self.m_verbosity	= a_verbosity
		self.m_warnings		= a_warnings
		
	def __init__(self, *args):
	    self.__name__ 	= 'C_spectrum'
	    self.mstr_obj	= 'C_spectrum';	# name of object class
            self.mstr_name	= 'unnamed';	# name of object variable
	    self.mstr_def	= 'void';	# name of function being processed
            self.m_id		= -1; 		# int id
            self.m_iter		= 0;		# current iteration in an
                                		#+ arbitrary processing 
						#+ scheme
            self.m_verbosity	= 0;		# debug related value for 
						#+ object
            self.m_warnings	= 0;            # show warnings 
						#+ (and warnings level)
	    self.mdict_keyIndex	= {};		# lookup of keys to indices
	    self.mdict_spectrum	= {};		# the actual spectrum
	    self.mNumKeys       = 0;
	    self.mb_printHist 	= False;	# If true, print an actual
						#+ histogram representation
	    self.mb_printAsRow  = False;	# If true, print spectrum as a
						# row, else print as column
	    self.mb_printConcise = False;	# If true, print concise 
						#+ version of spectrum
	    self.m_cellWidth 	 = 12		# For row printing, the width
						#+ of a column
	    self.mf_totalPower	 = 0.0;
						
	    c = args[0]
	    if type(c) is types.ListType:
	    	self.ml_keys = c
	    if type(c).__name__ == 'ndarray':
	        ilist = range(1, np.size(c)+1)
	        self.ml_keys = misc.list_i2str(ilist)
	        if len(args) >= 2:
	            if type(args[1] is types.ListType):
	            	if len(args[1]) == np.size(c):
	            	    self.ml_keys = args[1]

	    self.core_construct()
	    self.mdict_keyIndex = misc.dict_init(self.ml_keys, 0)
	    self.mdict_spectrum	= misc.dict_init(self.ml_keys, 0)
	    if type(c).__name__ == 'ndarray':
	        self.mdict_spectrum = misc.dict_init(self.ml_keys, 
							c.tolist())
	    self.keys_index()
	    if isinstance(c, int):
	    	self.component_add(c)
	    if type(c) is types.TupleType:
	    	for component in c:
	    	    self.component_add(component)
	    self.mNumKeys = len(self.ml_keys)

	def arr_set(self, arr):
	   """
	   DESC
		Given array input <arr>, overwrite internal 
		data with elements as defined in <arr>
		
	   ARGS
	   	arr		in		array to process; can
	   					be 'ndarray' or 'list'
	   	
	   PRECONDITIONS
	   	o self.ml_keys must be valid.
	   	
	   POSTCONDITIONS
	   	o If unable to set array, return False. Make no change
	   	  to internal data.
	   """
	   b_setOK = False
	   if type(arr).__name__ == 'ndarray':
	        self.mdict_spectrum = misc.dict_init(self.ml_keys, 
							arr.tolist())
	        b_setOK = True
	   if type(arr) is types.ListType:
	        self.mdict_spectrum = misc.dict_init(self.ml_keys, arr)
	        b_setOK = True
	   if b_setOK:	self.keys_index()
	   return b_setOK
	
	def name_get(self):
	    """
	    	Return the 'mstr_name' of the object
	    """
	    return self.mstr_name

	def spectrumKeys_get(self):
	   """
	   	Return the self.ml_keys
	   """
	   return self.ml_keys
	    	
	def arr_get(self):
	   """
	   	Get the internal "spectrum" as a numpy array
	   """
	   arr 	 = np.arange(len(self.ml_keys))
	   count = 0
	   for key in self.ml_keys:
	   	arr[count] = self.mdict_spectrum[key]
	   	count += 1
	   return arr
			    
	def printAsHistogram_set(self, aval):
	    self.mb_printHist = aval
        
        def printAsRow_set(self, aval):
            self.mb_printAsRow = aval
            
        def printColWidth_set(self, aval):
            self.m_cellWidth = aval
			    
	def printConcise_set(self, aval):
	    self.mb_printConcise = aval
	
	def name_set(self, aval):
	    self.mstr_name = aval		    
			    
	def core_print(self):
		str_t = ""
		str_t += 'mstr_sobj\t\t= %s\n' 	% self.mstr_obj
		str_t += 'mstr_name\t\t= %s\n' 	% self.mstr_name
		str_t += 'm_id\t\t\t= %d\n' 	% self.m_id
		str_t += 'm_iter\t\t\t= %d\n'	% self.m_iter
		str_t += 'm_verbosity\t\t= %d\n'% self.m_verbosity
		str_t += 'm_warnings\t\t= %d\n'	% self.m_warnings
		return str_t

	def __str__(self):
	    b_canPrint 		= True
	    b_printedAtLeastOne	= False
	    b_firstColPrinted	= False
	    # Determine the 'longest' key for appropriate width setting
	    longestKeyLength 	= 0
	    for field in self.ml_keys:
	    	if len(field) > longestKeyLength: longestKeyLength = len(field)
	    str_t = ""
	    if self.mstr_name != "void": 
	    	# check for spectral components > 0
	    	if self.arr_get().max() or not self.mb_printConcise: 
	    	    str_t += '%s---+\n' % self.mstr_name
	    	    str_blank = ''
	    	    for ch in range(1,len(self.mstr_name)):
	    	    	str_blank += ' '
	    	    str_t += '%s    |\n' % str_blank
	    	    str_t += '%s    V\n' % str_blank
	    if not self.mb_printAsRow:
	        for field in self.ml_keys:
	           if self.mb_printConcise and int(self.mdict_spectrum[field]) == 0:
	           	b_canPrint = False
	           else:
	           	b_canPrint = True
	           if b_canPrint:
	               f_sum = self.sum()	
	    	       str_t += "%5d - %-*s: %5d (%06.2f%s) " % (self.mdict_keyIndex[field], 
					          longestKeyLength + 2, field, 
					   	  self.mdict_spectrum[field],
					   	  float(self.mdict_spectrum[field])/float(f_sum)*100,
					   	  '%')
	    	       if self.mb_printHist:
	    	           for star in range(0, self.mdict_spectrum[field]):
	    	           	str_t += "*"
	    	       str_t += "\n" 
	    else:
	    	for key in self.ml_keys:
	    	    if self.mb_printConcise and not self.mdict_spectrum[key]:
	    	    	b_canPrint 		= False
	    	    else:
	    	    	b_canPrint 		= True
	    	    	if not b_firstColPrinted:
	    	    	    str_t += '+'
	    	    	    b_firstColPrinted   = True
	    	    	b_printedAtLeastOne 	= True
	    	    	for i in range(0, self.m_cellWidth):
	    	    	    str_t += '-'
	    	    	str_t += '+'
	    	if b_printedAtLeastOne: str_t += "\n"
	    	b_firstColPrinted		= False
	    	for key in self.ml_keys:
	    	    if self.mb_printConcise and not self.mdict_spectrum[key]:
	    	    	b_canPrint 		= False
	    	    else:
	    	    	b_canPrint 		= True
	    	    	if not b_firstColPrinted:
	    	    	    str_t += '|'
	    	    	    b_firstColPrinted   = True
	    	    if b_canPrint:
	    	        str_t += str(self.mdict_spectrum[key]).center(self.m_cellWidth)
	    	        str_t += "|"
	    	if b_printedAtLeastOne: str_t += "\n"
	    	b_firstColPrinted		= False
	    	for key in self.ml_keys:
	    	    if self.mb_printConcise and not self.mdict_spectrum[key]:
	    	    	b_canPrint 		= False
	    	    else:
	    	    	b_canPrint 		= True
	    	    	if not b_firstColPrinted:
	    	    	    str_t += '|'
	    	    	    b_firstColPrinted   = True
	    	    if b_canPrint:
	    	        str_t += ('(%d) %s' % (self.mdict_keyIndex[key], key)).center(self.m_cellWidth)
	    	        str_t += "|"
	    	if b_printedAtLeastOne: str_t += "\n"
	    	b_firstColPrinted		= False
	    	for key in self.ml_keys:
	    	    if self.mb_printConcise and not self.mdict_spectrum[key]:
	    	    	b_canPrint 		= False
	    	    else:
	    	    	b_canPrint 		= True
	    	    	if not b_firstColPrinted:
	    	    	    str_t += '+'
	    	    	    b_firstColPrinted   = True
	    	    	for i in range(0, self.m_cellWidth):
	    	    	    str_t += '-'
	    	    	str_t += '+'
	    	if b_printedAtLeastOne: str_t += "\n"
	    return str_t

	def keys_index(self):
	    count = 1;
	    for field in self.ml_keys:
	    	self.mdict_keyIndex[field] = count
	    	count += 1

	def component_add(self, componentID, aval=1, ab_overwrite=False):
	    """
	    ARGS
	    	componentID	string or int	component name or index
	    	aval		int		value to add
	    	ab_overwrite	bool		if True, overwrite the
	    					component value with <aval>,
	    					otherwise add <aval> to
	    					current value.
	    DESC
	    	Add (or set) a component described by <componentID>
	    	to the base spectrum.

	    RET
	    	Return component if successful, False if not.
	    """
	    b_ret = False
	    if isinstance(componentID, types.StringTypes):
	    	if componentID in self.ml_keys:
	    	    if ab_overwrite:
   		        self.mdict_spectrum[componentID] = aval;
   		    else:
   		        self.mdict_spectrum[componentID] += aval;
		    b_ret = componentID
	    elif isinstance(componentID, int):
	    	if componentID >= 1 and componentID <= len(self.ml_keys):
	    	    if ab_overwrite:
	    	        self.mdict_spectrum[self.ml_keys[componentID-1]] = aval
	    	    else:
	    	        self.mdict_spectrum[self.ml_keys[componentID-1]] += aval
	    	    b_ret = componentID
	    return b_ret
	    	    
 	def component_shift(self, al_fromToHarmonic, amount=1):
	    """
	    ARGS
	    	al_fromToHarmonic  list: string or int	component name or index
	    	amount		   float		amount to shift

	    DESC
	    	Shifts a "quanta" of spectral energy from the <fromHarmonic>
	    	to the <toHarmonic>.
	    	
	    	If the <fromHarmonic> does not contain <amount> spectral
	    	"energy", no shift is performed.
	    	
	    RETURN
	    	The amount of energy shifted. If no shift, returns zero.
	    """	    	    
	    ret = 0
	    fromHarmonic	= al_fromToHarmonic[0]
	    toHarmonic		= al_fromToHarmonic[1]
	    b_validFromHarmonic	= False
	    b_validToHarmonic	= False
	    if isinstance(fromHarmonic, types.StringTypes):
	    	if fromHarmonic in self.ml_keys: b_validFromHarmonic = True
	    if isinstance(toHarmonic, types.StringTypes):
	    	if toHarmonic in self.ml_keys: b_validToHarmonic = True
	    if isinstance(fromHarmonic, int):
	    	if fromHarmonic >=1 and fromHarmonic <= self.mNumKeys:
	    	    fromHarmonic = self.ml_keys[fromHarmonic-1]
	    	    b_validFromHarmonic = True	
	    if isinstance(toHarmonic, int):
	    	if toHarmonic >=1 and toHarmonic <= self.mNumKeys:
	    	    toHarmonic = self.ml_keys[toHarmonic-1]
	    	    b_validToHarmonic = True	
	    
	    if b_validFromHarmonic and b_validToHarmonic:
	        if self.mdict_spectrum[fromHarmonic] >= amount:
	            self.mdict_spectrum[fromHarmonic] -= amount
		    self.mdict_spectrum[toHarmonic]   += amount
		    ret = amount

	    return ret
	    
	def component_fadd(self, astr_fileName, aval=1):
	    """
	    	Add a component contained in <astr_fileName>
	    	to the base spectrum.
	    	
	    	Return component if successful, False if not.
	    """
	    b_ret = False
	    if isinstance(astr_fileName, types.StringTypes):
	    	try:
	    	    f = open(astr_fileName)
	    	    componentID = string.strip(f.read())
	    	    if componentID in self.ml_keys:
		        self.mdict_spectrum[componentID] += aval;
		        b_ret = componentID
	    	except IOError:
	    	    b_ret = False 
	    return b_ret

	def sum(self):
	    """
	    	Sum the spectral values together over the
	    	whole range
	    """
	    return sum(self.arr_get())
	   
	def __add__(self, cs):
	   """
	   	Add two spectra together, return a new 
	   	spectrum with keys as ordered and named
	   	by self.
	   """
	   C_add    = C_spectrum(self.arr_get() + cs.arr_get(), self.ml_keys)
	   
	   return C_add

	def save(self, astr_fileName):
	    """
	    	Saves the object to file using 'pickle'
	    """
	    try:
	    	pickle.dump(self, astr_fileName)
	    except PickleError: self.fatal('Save')
	    
        def saveMat(self, astr_fileName):
            """
                Saves the spectrum as a text file that can be
                read into MatLAB. This is a column dominant matrix,
                with the first column the spectral component names
                and the second column the spectral values.
            """
            try:
	    	fmat = open(astr_fileName, 'w')
            except IOError: self.fatal('SaveMat')
            for key in self.ml_keys:
            	fmat.write('%15s%5d\n' % (key, self.mdict_spectrum[key]))
            fmat.close()

	def load(self, astr_fileName):
	    """
	    	Load the object from file using 'pickle'. Overwrite
	    	current internals.
	    """
	    try:
	    	self = pickle.load(self, open(astr_fileName))
	    except PickleError: self.fatal('Load')
		    
	def dominant_harmonic(self):
	    """
	        Returns a single string denoting the dominant harmonic
	        of the spectrum. If there is no dominant component, 
	        return None
	    """
	    l_max = self.max_harmonics()
	    if len(l_max) == 1:
	    	return l_max[0]
	    else:
	    	return None	    
		    
	def max_harmonics(self):    
	    """
	    	Return as standard list the keys of the object that
	    	correspond to the maximum value of the spectrum.
	    """
	    a_sp		= self.arr_get()
	    f_max		= a_sp.max()
	    l_maxComponents	= []
	    for key in self.ml_keys:
	    	if self.mdict_spectrum[key] == f_max:
	    	    l_maxComponents.append(key)
	    return l_maxComponents
	   
        def max(self):
	    """
	    	Return the max value of the spectrum
	    """
	    return self.arr_get().max()
	
class C_spectrum_color(C_spectrum):
	"""
		A simple derived class with a hard-coded key list.
	"""

	def __init__(self, *args):
	    self.mstr_obj	= 'C_spectrum_color';
	    self.ml_keys	= [	'red', 'yellow', 'green', 'blue', 
				 	'magenta', 'cyan', 'white', 'black']
	    if not len(args): args = self.ml_keys
	    C_spectrum.__init__(self, *args)
	    self.__name__	= 'C_spectrum_color';

class C_spectrum_permutation(C_spectrum):
	"""
		A spectrum based on building a combined permutation of
		group indices.
	"""	

	def __init__(self, gridSize):
	    self.mlstr_perm1D	= []
	    l_permAll = list(itertools.permutations(range(1,gridSize+1)))
	    for l_perm in l_permAll:
	    	str_perm1D = "".join(["%s" % el for el in l_perm])
	    	self.mlstr_perm1D.append(str_perm1D)
	    C_spectrum.__init__(self, self.mlstr_perm1D)
	    self.__name__	= 'C_spectrum_permutation';

class C_spectrum_permutation2D(C_spectrum):
	"""
		A spectrum based on building a combined permutation of
		group indices in a 2D grid.
	"""
	
	def __init__(self, gridSize):
	    self.mlstr_perm1D	= []
	    self.mlstr_perm2D	= []
	    l_permAll = list(itertools.permutations(range(1,gridSize+1)))
	    for l_perm in l_permAll:
	    	str_perm1D = "".join(["%s" % el for el in l_perm])
	    	self.mlstr_perm1D.append(str_perm1D)
	    for str_permA in self.mlstr_perm1D:
	    	for str_permB in self.mlstr_perm1D:
	    	    str_key = "%s%s" % (str_permA, str_permB)
	    	    self.mlstr_perm2D.append(str_key)
	    C_spectrum.__init__(self, self.mlstr_perm2D)
	    self.__name__	= 'C_spectrum_permutation2D';
	    
