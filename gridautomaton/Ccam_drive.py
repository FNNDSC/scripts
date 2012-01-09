#!/usr/bin/env python
# 
# NAME
#
#	Ccam_drive
#
# DESCRIPTION
#
# 	A simple 'driver' for a cellular automaton machine
#
# HISTORY
#
# 16 December 2011
# o Initial development implementation.
#

from    numpy           import *
from    C_spectrum_CAM  import *
import  copy

def update_test():
    global dict_neighborTest
    updateSelf, updateNeighbor = Ccam.nextStateDelta_determine(dict_neighborTest)
    print updateNeighbor
    dict_neighborTest[updateNeighbor.keys()[0]].nextState_process(
                  updateNeighbor.values()[0])
    print dict_neighborTest[updateNeighbor.keys()[0]]


Ccam    = C_spectrum_CAM_RGB();
Ccam.component_add('R')
Ccam.component_add('B')
Ccam.component_add('G')

Ccam.arr_set(Ccam.arr_get() * 6)

print "Default background"
print Ccam

print "Dominance pattern = %s" % Ccam.max_harmonics()
#print len(Ccam.max_harmonics())

# Create a dictionary of neighbors similar to a CAE simulation

dict_neighborTest = {
    '(0, 0)'         : copy.deepcopy(Ccam),
    '(0, 1)'         : copy.deepcopy(Ccam),
    '(0, 2)'         : copy.deepcopy(Ccam),
    '(1, 0)'         : copy.deepcopy(Ccam),
    '(1, 1)'         : copy.deepcopy(Ccam),
    '(1, 2)'         : copy.deepcopy(Ccam)
                     }

Ccam.arr_set( [0, 18, 0] )
print Ccam

update_test()
update_test()
update_test()
update_test()
update_test()
update_test()
update_test()
update_test()
update_test()



