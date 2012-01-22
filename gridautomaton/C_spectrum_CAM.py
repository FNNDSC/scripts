# NAME
#
#        C_spectrum_CAM
#
# DESCRIPTION
#
#        The 'C_spectrum_CAM' is the main definition class that
#        implements a cellular automaton machine. 
#
#        Internally, the data components of the CAM are described
#        by a C_spectrum object. In fact, the CAM is a sub-class
#        of the C_spectrum base class, with a few additional methods
#        governing how the internal spectrum changes based on an
#        analysis of "neighboring" CAMs.
#
# HISTORY
#
# 16 December 2011
# o Initial development implementation.
#

from C_spectrum import *
import random

class C_spectrum_CAM(C_spectrum):
    """
        The Cellular Automata Machine (CAM) class, subclassed
        from a C_spectrum object.
    """
    def __init__(self, *args):
        self.mstr_obj        = 'C_spectrum_CAM';
        if not len(args): args = self.ml_keys
        C_spectrum.__init__(self, *args)
        self.__name__        = 'C_spectrum_CAM';

    def spectrum_init(self, value):
        """
        DESC
        Given a single value, initialize the internal spectrum
        """
        
    def nextStateDelta_determine(self, adict_neighbors):
        """
        ARGS
            adict_neigbors              dictionary of neighboring
                                        CAMS

        RETURN
            adict_selfDeltaState        a dictionary defining the changes
                                        to apply to "self" in the next 
                                        state. If 'None', implies no
                                        change to self.
            adict_neighborsDeltaState   a dictionary of changes to the
                                        passed neighbors. Only neighbors
                                        whose state needs to be changed
                                        are returned, indexed with the
                                        same dictionary key as the input
                                        adict_neighbors.
                                        
        DESC
        The core processing component of the CAM. The CAM examines
        each neighbor, and based on neighbor state information, 
        returns to the caller the changes to apply to itself, or
        to the neighbors (or a subset of the neighbors).
        
        The method returns a dictionary of changes to implement, but
        does itself not perform the changes. This is to allow the
        caller to better/quicker perform multiple cumulative updates
        to the same target CAM.
        
        NOTE:
        The dual return might be considered cumbersome, particularly
        in cases where CAMs either do not modify their neighbors (only
        modifying their internal state), or do not modify themselves
        (only modifying neighbors). For completeness sake, however,
        the nextState_process has two return components and the
        caller must examine both.
        """

    def nextState_process(self, adict_rule):
        """
        ARGS
            adict_rules          dict        the "rule" to apply to 'self' for
                                             spectral update.

        RETURN
            ab_OK                bool        successful (or not) update.
            
        DESC
        This method applies the adict_rule to its internal state. Together
        with the nextStateDelta_determine() method, this provides a decoupled
        interface that a CAE can use to process/update a grid of CAMs.
        """


class C_spectrum_CAM_RGB(C_spectrum_CAM):
    """
        The Cellular Automata Machine (CAM) RGB class, subclassed
        from a C_spectrum(_CAM) object.
    """
    
    #
    # For the CAM_RGB, the following dictionary defines the update
    # rules. The dictionary key denotes the rule list to apply for
    # a corresponding dominant spectral component.
    #
    # For a given rule, the 'direction' key defines a list of energy
    # transfer: from the first component to the second, and the 
    # 'amount' denotes how many 'quanta' to transfer.
    #
    mdict_updateRule = {
        'R' : {'direction' : [ 'G', 'R' ], 'amount' : 9},
        'G' : {'direction' : [ 'B', 'G' ], 'amount' : 9},
        'B' : {'direction' : [ 'R', 'B' ], 'amount' : 9}
    }
    
    def __init__(self, *args, **kwargs):
        self.mstr_obj           = 'C_spectrum_CAM_RGB';
        self.ml_keys            = [ 'R', 'G', 'B']
        if not len(args): args = self.ml_keys
        C_spectrum_CAM.__init__(self, *args)
        self.__name__           = 'C_spectrum_CAM_RGB';
        self.m_maxQuanta        = 99
        for key in kwargs:
            if key == "maxQuanta":
                self.m_maxQuanta        = kwargs[key]

    def updateRule_changeAmount(self, af_amount, *args):
        """
        Change the 'amount' in the updateRule. The optional *args
        defines the keys to change; default is all
        """
        keysToUpdate = self.ml_keys
        if len(args): keysToUpdate = args[0]
        for key in keysToUpdate:
            C_spectrum_CAM_RGB.mdict_updateRule[key]['amount'] = af_amount
     
    def spectrum_init(self, value, *args):
        """
        ARGS
            value        scalar        value to base initialization upon
            
        *args
            l_v          list          if passed, the domain partitioning
            
        DESC
            Given a single value, initialize the internal spectrum
        """
        # Initialize to a neutral default
        a_init = np.ones( len(self.ml_keys) ) * self.m_maxQuanta/3
        if len(args):
            v_l    = args[0]
            pcount = 0
            for partition in v_l:
                b_hits = partition[0] == value
                b_hit  = b_hits.sum()
                if b_hit:
                    a_init = np.zeros( len(self.ml_keys) )
                    a_init[pcount] = self.m_maxQuanta
                pcount += 1
        else:
            if value > 0 and value <= self.m_maxQuanta/3:
                a_init = np.array( (1, 0, 0) ) * self.m_maxQuanta
            if value > self.m_maxQuanta/3 and value <= 2*self.m_maxQuanta/3:
                a_init = np.array( (0, 1, 0) ) * self.m_maxQuanta
            if value > 2*self.m_maxQuanta/3:
                a_init = np.array( (0, 0, 1) ) * self.m_maxQuanta
        self.arr_set(a_init)
            
    def nextStateDelta_determine(self, adict_neighbors):
        """
        ARGS
            adict_neighbors             dictionary of neighboring
                                        CAMS

        RETURN
            adict_selfDeltaState        a dictionary defining the changes
                                        to apply to "self" in the next 
                                        state. If 'None', implies no
                                        change to self.
            adict_neighborsDeltaState   a dictionary of changes to the
                                        passed neighbors. Only neighbors
                                        whose state needs to be changed
                                        are returned, indexed with the
                                        same dictionary key as the input
                                        adict_neighbors.
                                        
        """
        if not adict_neighbors:  return None, None
                
        # In the RGB CAM, we first determine if 'self' can
        # process its neighbors. In order to process a neighbor,
        # the 'self' must be dominant along one of its core
        # spectral harmonics.
        l_dominant = self.max_harmonics()
        if len(l_dominant) > 1:
            # No dominant harmonic found, CAM does not influence
            # neighbors
            return None, None            

        # Now, choose a single neighbor randomly, and return the
        # delta state dictionary.        
        dominant                = l_dominant[0]
        neighbor                = random.choice(list(adict_neighbors.keys()))
        dict_target             = { neighbor :
                                    C_spectrum_CAM_RGB.mdict_updateRule[dominant] 
                                  }
        return None, dict_target

    def nextState_process(self, adict_rule):
        """
        ARGS
            adict_rules          dict        the "rule" to apply to 'self' for
                                             spectral update.

        RETURN
            ab_OK                bool        successful (or not) update.
        """
        l_direction     = adict_rule['direction']
        amount          = adict_rule['amount']
        return self.component_shift(l_direction, amount)



    