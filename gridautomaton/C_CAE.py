# NAME
#
#        C_CAE
#
# DESCRIPTION
#
#        The 'C_CAE' is the main definition class that creates 
#        a cellular automaton environment.
#
# HISTORY
#
# 16 December 2011
# o Initial development implementation.
#

from C_ggrid            import *
from C_spectrum_CAM     import *
from copy import deepcopy

import systemMisc       as misc
import numpy            as np
import itertools
import cPickle
import pickle

class C_CAE:
        # 
        # Class member variables -- if declared here are shared
        # across all instances of this class
        #
        mdictErr = {
            'Keys'          : {
                'action'        : 'initializing base class, ',
                'error'         : 'it seems that no member keys are defined.',
                'exitCode'      : 10},
            'Save'              : {
                'action'        : 'attempting to pickle save self, ',
                'error'         : 'a PickleError occured',
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

        def dprint( self, level, str_txt ):
            """
                Simple "debug" print... based on verbosity level.
            """
            if level <= self.m_verbosity: print str_txt

        def verbosity_set( self, level ):
            self.m_verbosity = level

        def error_exit( self,
                                astr_key,
                                ab_exitToOs=1
                                ):
            print "%s:: FATAL ERROR" % self.mstr_obj
            print "\tSorry, some error seems to have occurred in <%s::%s>" \
                            % ( self.__name__, self.mstr_def )
            print "\tWhile %s" % C_spectrum.mdictErr[astr_key]['action']
            print "\t%s" % C_spectrum.mdictErr[astr_key]['error']
            print ""
            if ab_exitToOs:
                print "Returning to system with error code %d" % \
                                C_spectrum.mdictErr[astr_key]['exitCode']
                sys.exit( C_spectrum.mdictErr[astr_key]['exitCode'] )
            return C_spectrum.mdictErr[astr_key]['exitCode']

        def fatal( self, astr_key, astr_extraMsg="" ):
            if len( astr_extraMsg ): print astr_extraMsg
            self.error_exit( astr_key )

        def warn( self, astr_key, astr_extraMsg="" ):
            b_exitToOS = 0
            if len( astr_extraMsg ): print astr_extraMsg
            self.error_exit( astr_key, b_exitToOS )

        def __init__( self, *args ):
            self.__name__ = 'C_CAE'
            self.mstr_obj = 'C_CAE';      # name of object class
            self.mstr_name = 'unnamed';    # name of object variable
            self.mstr_def = 'void';       # name of function being processed
            self.m_id = -1;           # int id
            self.m_iter = 0;            # current iteration in an
                                                #+ arbitrary processing 
                                                #+ scheme
            self.m_verbosity = 0;            # debug related value for 
                                                #+ object
            self.m_warnings = 0;            # show warnings 
                                                #+ (and warnings level)

            # The core data containers are grids of cellular automata 
            # machines
            self.mgg_current = None          # Current grid
            self.mgg_next = None          # Next iteration grid            

            # For the most part, the CAE accepts the same constructor
            # pattern as the C_ggrid:
            if len( args ) == 2:
                    # Grid spectral elements are of type C_spectrum_CAM
                    print "Creating current state grid...", ; misc.tic()
                    self.mgg_current = C_ggrid( *args, name='currentState' )
                    print "done. %s" % misc.toc()
                    print "Creating next state grid...", ; misc.tic()
                    self.mgg_next = C_ggrid( *args, name='nextState' )
                    print "done. %s" % misc.toc()

            self.m_rows = self.mgg_current.rows_get()
            self.m_cols = self.mgg_current.cols_get()

            self.__neighbors = {}

        def initialize( self, *args, **kwargs ):
            """
            ARGS
                    *args[0]        nparray        initialize each CAM with
                                                   corresponding element of
                                                   nparray. Assumes that
                                                   size(nparray) == size(grid).
                                                   Passes array value at
                                                   [row, col] to CAM at 
                                                   [row, col].
                                                   
            DESC
            
                Generates an initial distribution across the world grid.
            
            KWARGS
            
                The pattern of initialization is specified by the kwargs:
                
                  pattern = "random" | "corners" | "diagonal"
                    
                    Choose elements either randomly on the grid, or only on the
                    corners, or only along the diagonal.
                    
                  elements = "canonical" | <N> | "all"
                    
                    "canonical"
                    The number of grid elements to initialize. If "canonical",
                    initialize only as many elements as there are spectral
                    components in the CAM. Each successive element initializes
                    a single successive spectral component.
                    
                    <N>  
                    Initialize <N> elements.
                    
                    "all"
                    Initialize all elements.
                    
            PRECONIDTIONS:
                o Internal grids must exist
                
            POSTCONDITIONS:
                o The "current" and "next" are initialized based on pattern
                  of args.
                o If an array is passed as first unnamed argument, values in
                  the array are used to initialize the grid (provided that the
                  array is the same size as grid). In such a case, all kwargs
                  are ignored. If array size is not same as grid, no
                  initialization is performed.
            """

            if len( args ):
                a_init = args[0]
                if type( a_init ).__name__ == 'ndarray':
                    rows, cols = a_init.shape
                    if rows == self.m_rows and cols == self.m_cols:
                        for row in np.arange( 0, rows ):
                            for col in np.arange( 0, cols ):
                                value = a_init[row, col]
                                self.mgg_current.spectrum_get( row, col ).spectrum_init( value )
            # self.mgg_next = copy.deepcopy( self.mgg_current )
            # use cPickle instead of deepcopy
            self.mgg_next = cPickle.loads( cPickle.dumps( self.mgg_current, -1 ) )

        def dict_createFromGridLocations( self, A_points ):
            """
                Given an array of grid locations, <A_points>, construct
                and return a dictionary of next state spectra located at each of
                the <A_points> and indexed by the spectra name.
            """
            dict_spectrum = {}
            if A_points != None:
                for point in A_points:
                    row, col = point
                    dict_spectrum[self.mgg_next.spectrum_get( row, col ).name_get()] = \
                        self.mgg_next.spectrum_get( row, col )
            return dict_spectrum

        def state_transition( self ):
            """
            The state transition machine for the CAE; determines the
            "next" state from the "current".
            
            PRECONDITIONS:
                o The "current" == "next" state
        
            TRANSITION:
                o The "next" state is changed according to "current" state
                  in a decoupled element-by-element fashion.
                
            POSTCONDITIONS:
                o Once each element in the "current" state has been processed,
                  the "next" state is copied into the "current" state.
                o A state transition is now complete.
                o Returns the number of elements processed.
            
            Primitive support for multithreaded/parallelization is planned...
            """

            # Process the current grid, and determine all the changes required to
            # transition to the next state.
            elementProcessedCount = 0
            misc.tic()
            for row in np.arange( 0, self.m_rows ):
                for col in np.arange( 0, self.m_cols ):
                    dict_nextStateNeighbourSpectra = {}
                    A_neighbours = None

                    key = str( row ) + ':' + str( col )
                    if self.__neighbors.has_key( key ):
                      # we already have the neighbors
                      A_neighbours = self.__neighbors[key]
                    else:
                      # we don't have the neighbors, so let's calculate them
                      A_neighbours = \
                          misc.neighbours_findFast( 2, 1,
                                      np.array( ( row, col ) ),
                                      gridSize=np.array( ( self.m_rows, self.m_cols ) ),
                                      wrapGridEdges=False,
                                      returnUnion=True,
                                      includeOrigin=False )
                      self.__neighbors[key] = A_neighbours

                    dict_nextStateNeighbourSpectra = \
                        self.dict_createFromGridLocations( A_neighbours )
                    deltaSelf, deltaNeighbour = \
                        self.mgg_current.spectrum_get( row, col ).nextStateDelta_determine( 
                                                dict_nextStateNeighbourSpectra )
                    if deltaNeighbour:
                        for update in deltaNeighbour.keys():
                            elementProcessedCount += 1
                            updateRule = deltaNeighbour[update]
                            dict_nextStateNeighbourSpectra[update].nextState_process( updateRule )
            print "Update loop time: %f seconds (%d elements processed)." % \
                        ( misc.toc(), elementProcessedCount )

            # Now update the current state with the next state
            misc.tic()
            b_setFromArray = False
            self.mgg_next.internals_sync( b_setFromArray )
            print misc.toc( sysprint="Synchronization: %f seconds." )
            misc.tic()
            # self.mgg_current    = copy.deepcopy(self.mgg_next)
            # use cPickle instead of deepcopy
            self.mgg_current = cPickle.loads( cPickle.dumps( self.mgg_next, -1 ) )
            print misc.toc( sysprint="next->current deepcopy: %f seconds.\n" )
            return elementProcessedCount

        def currentSpectralArray_get( self, anp_gridLocation ):
            """
            Return the spectral array at a given location in the current grid.
            """
            return self.mgg_current.spectralArray_get( anp_gridLocation )

        def spectrum_get( self, row, col ):
            """
            Return the spectrum (from the current state) at the given location
            """
            return self.mgg_current.spectrum_get( row, col )
