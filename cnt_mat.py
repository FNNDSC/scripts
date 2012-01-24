#!/usr/bin/env python

import sys
import networkx as nx
import numpy as np
import scipy.io as sio


pickleFileName = sys.argv[1];
outputBaseName = sys.argv[2];

print ("Loading %s...\n") % (pickleFileName)
g = nx.read_gpickle(pickleFileName)
    
# Write out three different matrices, each with different edge values
mlab_n = np.zeros([len(g.nodes())+1,len(g.nodes())+1])
mlab_lm = np.zeros([len(g.nodes())+1,len(g.nodes())+1])
mlab_ls = np.zeros([len(g.nodes())+1,len(g.nodes())+1])

for i in g.edge.keys():
    for j in g.edge[i].keys():
        mlab_n[i-1][j-1]=g.edge[i][j]['number_of_fibers']
        mlab_lm[i-1][j-1]=g.edge[i][j]['fiber_length_mean']
        mlab_ls[i-1][j-1]=g.edge[i][j]['fiber_length_std']

mlab_dict = {}
mlab_dict['cmatrix'] = mlab_n;
sio.savemat(outputBaseName + '_number_of_fibers.mat',mlab_dict)

mlab_dict['cmatrix'] = mlab_lm;
sio.savemat(outputBaseName + '_fiber_length_mean.mat',mlab_dict)

mlab_dict['cmatrix'] = mlab_ls;
sio.savemat(outputBaseName + '_fiber_length_std.mat',mlab_dict)

print 'Done'
     
    
    
#    connectome_to_matlab(outputBaseName + '_number_of_fibers.mat', g, 'number_of_fibers')
 #   connectome_to_matlab(outputBaseName + '_fiber_length_mean.mat', g, 'fiber_length_mean')
  #  connectome_to_matlab(outputBaseName + '_fiber_length_std.mat', g, 'fiber_length_std')
