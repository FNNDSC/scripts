#!/usr/bin/env python

import sys
import networkx as nx
import numpy as np
import scipy.io as sio

import argparse

#----------------
# Parse arguments

parser = argparse.ArgumentParser( description='The connectome matrix tool: Generating matrices from pickles')

parser.add_argument( '-p', '--pickle',
                    action='store',
                    dest='pickle',
                    required=True,
                    help='Target pickle file.' )

parser.add_argument( '-b', '--base',
                    action='store',
                    dest='base',
                    default='',
                    help='Output basename for the files to be generated. A "test" base would generate test_***.extension files.' )

parser.add_argument( '-e', '--extension',
                    action='store',
                    dest='extension',
                    default='txt',
                    choices=['txt', 'mat'],
                    help='Output extension for the files to be generated. A "txt" extension would generate base_***.txt files.' )

options = parser.parse_args()

#----------------
# setup parameters

print ('Setup parameters...')

listkeys = ['number_of_fibers', 'fiber_length_mean', 'fiber_length_std']
listformat  = ['%d', '%f', '%f']
    
#----------------
# Load pickle and generate matrices

print ('Load %s and generate matrices...') % (options.pickle)

g = nx.read_gpickle(options.pickle)

# Write out different matrices, each with different edge values
for mat in listkeys:
  exec(mat +' = np.zeros([len(g.nodes())+1,len(g.nodes())+1])')

for i in g.edge.keys():
    for j in g.edge[i].keys():
        for mat in listkeys:
          exec(mat +'[i-1][j-1]=g.edge[i][j][\'' + mat  + '\']')

#----------------
# save matrices in the requested file format

print 'Saving matrices as: *.' + options.extension + ' files'

if options.extension == 'txt':
  for mat in listkeys:
    np.savetxt( options.base + '_' + mat + '.' + options.extension ,eval(mat),fmt=listformat[listkeys.index(mat)], delimiter='\t', newline='\n')
elif options.extension == 'mat':
  mlab_dict = {}
  for mat in listkeys:
    mlab_dict['cmatrix'] = eval(mat);
    sio.savemat(options.base + '_' + mat + '.' + options.extension,mlab_dict)
else:
  print 'Invalid file extension: ' + options.extension

print 'Done'

#    connectome_to_matlab(options.base + '_number_of_fibers.mat', g, 'number_of_fibers')
 #   connectome_to_matlab(options.base + '_fiber_length_mean.mat', g, 'fiber_length_mean')
  #  connectome_to_matlab(options.base + '_fiber_length_std.mat', g, 'fiber_length_std')
