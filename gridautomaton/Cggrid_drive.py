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
# 07 December 2011
# o Initial development implementation.
#

from    numpy           import *
from    C_ggrid         import *
from    C_spectrum      import *
import  copy

Csp     = C_spectrum(['R', 'G', 'B']);
Csp.component_add('R');
Csp.component_add('G');
Csp.component_add('B');

print Csp

Cg0     = C_ggrid(2, Csp, name='Cg0');
Cg1     = C_ggrid(np.array((2,2)), Csp, name='Cg1')
Cg00    = copy.deepcopy(Cg0) ; Cg00.mstr_name = 'Cg00'

print Cg0
print Cg00
Cg2 = Cg0 + Cg1
print Cg2

Cg0.spectralArray_set( np.array( [[0,0],[1,1]] ), np.array((10, 10, 10)))
print Cg0
print Cg00

a_sp = Cg0.spectralArray_get( np.array( [[1,0],[0,0]] ))
print a_sp


