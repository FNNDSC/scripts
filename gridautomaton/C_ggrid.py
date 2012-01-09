# NAME
#
#	C_ggrid
#
# DESCRIPTION
#
#	'C_ggrid' is the atom class that process group-based
#        2D positional grids.
#
#
# HISTORY
#
# 31 March 2011
# o Initial development implementation.
#
# December 2011
# o Signifcant enhancements and expansion.
#

# System imports
import 	os
import 	os.path
import 	sys
import	string
import	types
import	itertools

import	systemMisc	as misc
import 	numpy 		as np

import 	cPickle		as pickle
import  copy

from 	C_spectrum	import *

class C_ggrid :
	# 
	# Class generic variables: shared across all instances
	# of this class:
	#
        mdictErr = {
	    'Constructing'      : {
	        'action'        : 'attempting to construct grid, ',
	        'error'         : 'an internal calling API error occurred.',
	        'exitCode'      : 1},
	    'ConstructingArray' : {
	        'action'        : 'attempting to construct from array arg, ',
	        'error'         : 'an internal calling API error occurred.',
	        'exitCode'      : 2},
	    'ReadGrid'          : {
	        'action'        : 'attempting to read grid file, ',
	        'error'         : 'I could not access the file.',
	        'exitCode'      : 10},
	    'Operands'          : {
	        'action'        : 'checking operands, ',
	        'error'         : 'internal grids are not the same size.',
	        'exitCode'      : 11},
	    'Save'              : {
	        'action'        : 'attempting to pickle save self, ',
	        'error'         : 'a PickleError occured.',
	        'exitCode'      : 12},
	    'Load'              : {
	        'action'        : 'attempting to pickle load object, ',
	        'error'         : 'a PickleError occured.',
	        'exitCode'      : 13}
	}

	#
	# Methods
	#
	# Core methods - construct, initialise, id

	def error_exit( self,
				astr_key,
				ab_exitToOs=1
				):
	    print "%s::%s:" % ( self.mstr_obj, self.mstr_name )
	    print "\tSorry, some error seems to have occurred in <%s::%s>" \
	    		% ( self.__name__, self.mstr_def )
	    print "\tWhile %s" 		 % C_ggrid.mdictErr[astr_key]['action']
	    print "\t%s"		 % C_ggrid.mdictErr[astr_key]['error']
	    print ""
	    if ab_exitToOs:
	    	print "Returning to system with error code %d" % \
	    				  C_ggrid.mdictErr[astr_key]['exitCode']
	        sys.exit( C_ggrid.mdictErr[astr_key]['exitCode'] )
	    return C_ggrid.mdictErr[astr_key]['exitCode']

	def fatal( self, astr_key, astr_extraMsg="" ):
	    if len( astr_extraMsg ): print astr_extraMsg
	    self.error_exit( astr_key )

	def warn( self, astr_key, astr_extraMsg="" ):
	    b_exitToOS = 0
	    if len( astr_extraMsg ): print astr_extraMsg
	    self.error_exit( astr_key, b_exitToOS )

	def __init__( self, *args, **kwargs ):
	    """
	    NAME
		 Constructor
		 
	    SYNOPSIS	    
	    	C_ggrid(<np_array>, 	<SpectrumClassObject> [,b_initFromArr])
	    	C_ggrid(<fileName>,	<SpectrumClassObject> [,b_initFromArr])
	    	C_ggrid(<N>,		<SpectrumClassObject> [,b_initFromArr])
	    			
	    DESCRIPTION
	        Constructor for the C_ggrid base class. The core data
	        components of a C_ggrid are a 2D array of 
	        <SpectrumClassObject>. The actual spectrum of each
	        <SpetrumClassObject> is also available as a 
	        convenience array, self.ma_grid, where each index
	        is a copy of the elements in the spectral dictionary 
	        of the corresponding spectrum object. 
	        
		Since the <SpectrumClassObject> keeps its spectrum in
		a dictionary structure, the self.ma_grid is independent
		of the dictionary elements. Changes to one do not
		affect the other. The 'internals_sync()' method
		re-synchronizes data.
	        	        
	        The first argument defines the grid size and possible initial
	        array values. The second argument is a spectrum object
	        to copy into each grid location. 
	        
	        The third argument, if specified, denotes the direction
	        of spectral initialization, 
	        
		Based on the type of the first argument, the following
		internal array sizes and values are created:
			        
	            <np_array>: 	
	                If two-element vector of ([row, col]):
	                		Creates internal array of [row x col]
	                		and initializes to zero. Initializes
	                		grid spectra accordingly.
	                		
	                If ND array stucture:
	            			Initializes internal array with
	        			passed values and then initializes
	        			spectrum at each grid index based 
	        			on array value at corresponding 
	        			grid. This array can be either
	        			2D or 3D.
	        			  
	            <fileName>: 	
	            			Reads array from <fileName>, 
	        			initializes internal array and
	        			initializes internal spectrum 
	        			based on array. Typically, the
	        			<fileName> contains a 2D array,
	        			i.e. a single spectral component
	        			at each grid index.
	        			  
	            <N>: 		
	            			Int argument. Uses <N> to specify
	            			internal array size, and copies
	            			<SpectrumClassObject> to each grid
	            			element. Also copies the the
	            			spectral array to each internal
	            			grid array.
	        
	        It is important to understand that the internal grid
	        "array" is in fact an array of arrays (since each grid 
	        element, or spectrum, contains its own spectral array).
	        However, it is possible to initialize the internal array
	        with either a 2D or ND structure. In the case of ND
	        initializer, each 2D grid index is a 1D array of size N, 
	        and this array is used to initialize the 
	        <SpectrumClassObject>. 
	        
	        In the case of a 2D initializer, each 2D grid index
	        is a single value, and taken to imply a spectral 
	        index. Only this index in the <SpectrumClassObject>
	        is initialized.
	        
	            <SpectrumClassObject>:
	            			Sets each internal "spectral"
	            			object to <SpectrumClassObject>.
	            			Initializes internal array from
	            			<SpectrumClassObject>. If 
	            			called with first argument of type
	            			<fileName> or <np_array>, will
	            			re-initialize the internal array
	            			to <SpectrumClassObject>.

		    <b_initFromArr>:
		    			Boolean var. If specified, and if
		    			True, force grid initialization from
		    			array, else force array initialization
		    			from spectral grid.
		
	    """
	    self.__name__ 	 = "C_ggrid"
	    self.mstr_obj	 = 'C_ggrid';	# name of object class
            self.mstr_name	 = '<unnamed>';	# name of object variable
	    self.mstr_def	 = 'constructor';# name of function being processed
            self.m_id		 = -1; 		# int id
            self.m_iter		 = 0;		# current iteration in an
                                		#+ arbitrary processing 
						#+ scheme
            self.m_verbosity	 = 0;		# debug related value for 
						#+ object
            self.m_warnings	 = 0;            # show warnings 
						#+ (and warnings level)

	    self.mstr_gridFileName 	 = ""	# file containing numeric grid	
	    self.ma_grid       		 = None	# array grid (of np_arrays)
	    self.macs_grid		 = None	# grid of spectrum types
	    self.m_rows			 = 0
	    self.m_cols			 = 0
	    self.mb_initializeFromArr	 = True

	    for key, value in kwargs.iteritems():
	    	if key == 'name': self.mstr_name = value

	    if len( args ) == 2:
		    c = args[0]
		    if type( c ) is types.StringType:
		    	self.mstr_gridFileName = c
	                try:
	                   self.ma_grid = np.genfromtxt( self.mstr_gridFileName )
	                except IOError: self.fatal( 'ReadGrid' )
	                self.mb_initializeFromArr = True
	            if type( c ).__name__ == 'ndarray':
	            	# Examine the array. If the first element is type
	            	# ndarray, assume the array is spectral grid data.
	            	# If the first element is type int, assume that the
	            	# array denotes the size of grid to create.
	            	if len( c ) == 2:
	            	    if type( c[0] ).__name__ == 'int64' and \
	            	       type( c[1] ).__name__ == 'int64':
	            	        self.ma_grid = np.zeros( ( c[0], c[1] ),
							dtype='object' )
	                        self.mb_initializeFromArr = False
	                    if type( c[0] ).__name__ == 'ndarray':
	           	        self.ma_grid = c.copy()
	                        self.mb_initializeFromArr = True
	                else: fatal( 'ConstructingArray' )
	            if type( c ) is types.IntType:
	            	# If constructed with single int, create
	            	# zeroes grid of [c x c] 
	            	self.ma_grid = np.zeros( ( c, c ), dtype='object' )
	                self.mb_initializeFromArr = False
	            # 
	            # At this point, the shape of the grid should
	            # be known.
	            #
	       	    l_dim = self.ma_grid.shape;
	    	    self.m_rows = l_dim[0]
	    	    self.m_cols = l_dim[1]

	    	    #
	    	    # Now, copy the spectrum object to the internal grid
	    	    #
	    	    cspectrum = args[1]
	    	    self.macs_grid	 = np.zeros( ( self.m_rows, self.m_cols ),
							dtype='object' )
	    	    for row in np.arange( 0, self.m_rows ):
	    	    	for col in np.arange( 0, self.m_cols ):
	    	    	    #print "setting row: %d, col: %d" % (row, col)
	    	    	    #print cspectrum
									# self.macs_grid[row, col] = copy.deepcopy(cspectrum)
									# use cPickle instead of deepcopy
									self.macs_grid[row, col] = pickle.loads( pickle.dumps( cspectrum, -1 ) )


	    	    if len( args ) == 3:
	    	    	self.mb_initializeFromArr = int( args[2] )

	    	    #
	    	    # Construct internals
	    	    #	This essentially links the ma_grid and each spectral
	    	    #   grid.
	    	    #
	            self.internals_sync( self.mb_initializeFromArr )

	    else:
	   	self.fatal( 'Constructing' )

	def internals_sync( self, ab_setFromArray, *args ):
	    """
	    DESC
		Synchronize the internal spectral class data and 
		the internal array representations. Since the
		helper array is independent from the data in each
		spectral components, spectral data can be
		out-of-sync. This method resynchronizes one
		to the other.
		
	    ARGS
	    	ab_setFromArray	bool	True: set spectral values from
	    				      	internal array values
	    				False: set array values
	    				 	from internal spectral
	    				 	grid 
	    				 	
	    VARIABLE ARGS
	    	aa_index	array	Array of 2D grid locations
	    				that should be referenced
	    				for updating. If this argument
	    				is not passed and is not of 
	    				type 'ndarray', then all
	    				indices are updated.
	    """
	    b_initArrayIsSingleComponent = False
	    if type( self.ma_grid[0, 0] ).__name__ != 'ndarray':
	    	b_initArrayIsSingleComponent = True
	    aa_index = self.ma_grid
	    a_flat = misc.array2DIndices_enumerate( aa_index.shape )
	    if len( args ):
	    	a = args[0]
	    	if type( a ).__name__ == 'ndarray':
	    	    a_flat = a
	    for v_index in a_flat:
	    	row = v_index[0]
	    	col = v_index[1]
		if ab_setFromArray:
		    if not b_initArrayIsSingleComponent:
		        self.macs_grid[row, col].arr_set( 
						self.ma_grid[row, col] )
		    else:
		    	b_overwrite = True
		    	self.macs_grid[row, col].component_add( 
						self.ma_grid[row, col],
						b_overwrite )
		    	self.ma_grid[row, col] = \
		    	    		self.macs_grid[row, col].arr_get()
		else:
		    self.ma_grid[row, col] = \
		    	np.array( self.macs_grid[row, col].arr_get() )
		self.spectrumDefaults_set( row, col )

        def rows_get( self ):
            return self.m_rows

        def cols_get( self ):
            return self.m_cols

        def spectralArray_set( self, anp_gridLocation, anp_value ):
 	    """
 	    ARGS
 	        anp_gridLocation	numpy array	array of grids to set
 	        anp_value		numpy array	spectral array value
 	        
 	    DESC
 	        Set the array value at the passed <anp_gridLocation>(s) to
 	        <anp_value>. 
 	        
 	        NB!!
 	        <anp_gridLocation> is a column dominant vector of 2D grid
 	        locations. This requires a rather convoluted set of
 	        brackets sometimes, i.e.: 
		NB!!

 	        Grid array and spectral objects are synchronized.
 	    """
 	    locations, cols = anp_gridLocation.shape
 	    ret = 0
 	    for location in np.arange( 0, locations ):
 	    	row, col = anp_gridLocation[location]
 	    	self.ma_grid[row, col] = anp_value.copy()
 	    	self.macs_grid[row, col].arr_set( anp_value )
 	    	ret += 1
 	    return ret

	def spectralArray_get( self, anp_gridLocation ):
 	    """
 	    ARGS
 		anp_gridLocation	numpy array	array of grids to set
 		
 	    RET
 	        nparray of spectra.
 		
 	    DESC
 		Gets the spectral arrays at the passed <anp_gridLocation>(s)
 		
 		<anp_gridLocation> is a column dominant vector of 2D grid
 		locations.
 	    """
 	    locations, cols 	 = anp_gridLocation.shape
 	    np_gridSpectra	 = np.zeros( ( locations ), dtype='object' )
 	    for location in np.arange( 0, locations ):
 	    	row, col = anp_gridLocation[location]
 	    	np_gridSpectra[location] = ( self.ma_grid[row, col] ).copy()
 	    return np_gridSpectra

 	def spectrumArr_get( self, row, col ):
 	    """
		Return the spectral array at [row, col]
 	    """
 	    return self.ma_grid[row, col]

 	def spectrum_get( self, row, col ):
 	    """
 	    	Return the spectrum (object) at [row, col]
 	    """
 	    return self.macs_grid[row, col]

        def spectrumDefaults_set( self, row, col ):
            """
            	Sets some generic defaults for passed spectrum
            """
            self.macs_grid[row, col].name_set( '(%d, %d)' % ( row, col ) )
            self.macs_grid[row, col].printAsRow_set( True )
            self.macs_grid[row, col].printConcise_set( True )
            self.macs_grid[row, col].printColWidth_set( 15 )

	def core_print( self ):
		str = ""
		str += 'mstr_sobj\t\t= %s\n' 	 % self.mstr_obj
		str += 'mstr_name\t\t= %s\n' 	 % self.mstr_name
		str += 'm_id\t\t\t= %d\n' 	 % self.m_id
		str += 'm_iter\t\t\t= %d\n'	 % self.m_iter
		str += 'm_verbosity\t\t= %d\n'	 % self.m_verbosity
		str += 'm_warnings\t\t= %d\n'	 % self.m_warnings
		return str

	def __str__( self ):
	    str = ""
	    str += 'Object internal name: %s\n' % self.mstr_name
	    str += 'Raw grid:\n'
	    str += '%s\n\n' % np.array_str( self.ma_grid )
	    str += 'Spectra:\n'
	    for row in np.arange( 0, self.m_rows ):
	    	for col in np.arange( 0, self.m_cols ):
	    	    str += "%s" % self.macs_grid[row, col]
	    	str += "\n"
	    return str

	def gridarr_get( self ):
	    """
	    	Return the internal ma_grid
	    """
	    return self.ma_grid

    	def __add__( self, cg ):
    	    """
    	    	Adds two grids together, returning the result as a new
    	    	grid. For each grid cell (which contains a spectrum)
    	    	a new spectrum is created which is the sum of the 
    	    	constituent spectra.
    	    """
    	    if self.ma_grid.shape != cg.ma_grid.shape: self.fatal( 'Operands' )
    	    C_add = C_ggrid( self.ma_grid, self.macs_grid[0, 0] )
    	    C_add.ma_grid = self.ma_grid + cg.ma_grid
    	    b_setFromArray = True
    	    C_add.internals_sync( b_setFromArray )
#	    for row in np.arange(0, self.m_rows):
#		for col in np.arange(0, self.m_cols):
#		    spectrum_self = self.macs_grid[row, col]
#		    spectrum_cg   = cg.macs_grid[row, col]
#		    C_add.macs_grid[row, col] = spectrum_self + spectrum_cg
#		    C_add.spectrumDefaults_set(row, col)
    	    return C_add

	def save( self, astr_fileName ):
	    """
	    	Saves the object to file using 'pickle'
	    """
	    try:
	    	pickle.dump( self, astr_fileName )
	    except PickleError: self.fatal( 'Save' )

	def load( self, astr_fileName ):
	    """
	    	Load the object from file using 'pickle'. Overwrite
	    	current internals.
	    """
	    try:
	    	self = pickle.load( self, open( astr_fileName ) )
	    except PickleError: self.fatal( 'Load' )
