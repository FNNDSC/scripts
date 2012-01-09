#!/usr/bin/env python
# 
# NAME
#
#        Ccae_drive
#
# DESCRIPTION
#
#         A simple 'driver' for a cellular automaton environment
#
# HISTORY
#
# 04 January 2012
# o Initial development implementation.
#

import  numpy           as np

from    C_spectrum_CAM  import *
from    C_CAE           import *

import  systemMisc      as misc

b_overwriteSpectralValue        = True
maxEnergy                       = 249
automaton                       = C_spectrum_CAM_RGB(maxQuanta = maxEnergy)
automaton.component_add('R', maxEnergy/3, b_overwriteSpectralValue)
automaton.component_add('G', maxEnergy/3, b_overwriteSpectralValue)
automaton.component_add('B', maxEnergy/3, b_overwriteSpectralValue)

world           = C_CAE( np.array( (101,101)), automaton )
world.verbosity_set(1)
arr_world               = np.zeros( (101, 101) )
arr_world[0,0]          = 1
arr_world[50,50]        = maxEnergy/3 + 1
arr_world[100, 100]     = maxEnergy/3*2 + 1

world.initialize(arr_world)

for iter in np.arange(0, 100):
    world.state_transition()
    