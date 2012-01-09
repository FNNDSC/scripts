#!/usr/bin/env python
# 
# NAME
#
#        Cgenome_drive.py
#
# DESCRIPTION
#
#         A simple 'driver' for a C_genome class instance
#
# HISTORY
#
# 25 March 2011
# o Initial development implementation.
#

from    numpy           import *
from    C_spectrum      import *

C_t     = C_spectrum_color(['r', 'g', 'b', 'y'])
C_t.component_add('b')

a       = array( (1, 1, 1, 2, 5, 10, 5, 2, 1, 1, 1))
C_sa    = C_spectrum(a)

print C_sa.arr_get()

C_sp    = C_spectrum_color()
C_sp.component_add('red')
C_sp.component_add('red')
C_sp.component_add(2)
C_sp.component_add(0)

C_sp2a   = C_spectrum_color((4,))
C_sp2b  = C_spectrum_color((1,))
C_spA   = C_sp2a + C_sp2a + C_sp2a + C_sp2a + C_sp2a + C_sp2b + C_sp2b
#C_spA.printConcise_set(True)
C_spA.printAsRow_set(True)
print C_spA

C_xord = C_spectrum_permutation(4)
C_xord.component_add('4321')
C_xord.component_add('4321')
C_xord.component_add('4321')
C_xord.component_fadd('grids/grid1.xord')
C_xord.component_fadd('grids/grid1.xord')

C_xord.printConcise_set(True)
print C_xord
print
print "Yord"
C_yord = C_spectrum_permutation(3)
C_yord.component_add('123')
print C_yord

#print C_t
#print C_sp

#print C_sa
#print C_sa.arr_get() * 2

C_sas = C_sp + C_sp
C_sas.printAsHistogram_set(True)
C_sas.printColWidth_set(15)
print C_sas
C_sas.component_shift(['red', 'blue'])
print C_sas

