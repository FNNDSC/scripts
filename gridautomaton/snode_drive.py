#!/usr/bin/env python
# 
# NAME
#
#        snode_drive.py
#
# DESCRIPTION
#
#         A simple 'driver' for C_snode and related classes
#
# HISTORY
#
# 26 March 2008
# o Initial development implementation.
#

from    C_snode         import  *

l_root          = ['produce', 'meats', 'cereal', 'dairy']
SNB_departments = C_snodeBranch(l_root)

b_branchBuildTest       = False
b_treeBuildFromNodes    = False
b_treeBuild             = True

#if b_treeBuildFromNodes:
        #STree           = C_stree()
        #node            = C_snode('/')
        #node1           = C_snode('produce')
        #node2           = C_snode('meats')
        #node3           = C_snode('cereal')
        #node4           = C_snode('dairy')
        
        #node11          = C_snode('fruit')
        #node12          = C_snode('vegetables')
        
        #node111         = C_snode('apples')
        #node112         = C_snode('pears')
        
        #STree.mknode(['produce', 'meats', 'cereal', 'dairy'])
        #STree.msnode_current = STree.msnode_root.mdict_contents['produce']
        #STree.mknode(['fruit', 'vegetables'])
        #STree.msnode_current = STree.msnode_root.mdict_contents['produce'].mdict_contents['fruit']
        #STree.mknode(['apples', 'pears'])
        
        #node.node_branch(['node1', 'node2'], [node1, node2])
        #node2.node_branch(['node3'], [node3])
        #STree.msnode_root.node_branch(['produce', 'meats', 'cereal', 'dairy'],
                                #[node1, node2, node3, node4])
        #STree.msnode_root.mdict_contents['produce'].node_branch(
                                #['fruit', 'vegetables'],
                                #[node11, node12])
        #STree.msnode_root.mdict_contents['produce'].mdict_contents['fruit'].node_branch(
                                 #['apples', 'pears'],
                                 #[node111, node112])                              
        #print node

#if b_branchBuildTest:
  #SNB_produce     = C_snodeBranch(['fruit', 'vegetables'])
  #SNB_fruit       = C_snodeBranch(['apples', 'oranges', 'pears'])
  #SNB_meats       = C_snodeBranch(['beef', 'pork', 'mutton'])

  #SNB_pearRecipes = C_snodeBranch(['LSP-003', 'AvR-091', 'LSP-200'])

  #SNB_produce.node_branch(      'fruit',        SNB_fruit)
  #SNB_fruit.node_branch(        'pears',        SNB_pearRecipes)
  #SNB_departments.node_branch(  'produce',      SNB_produce)

  #print SNB_departments.mdict_branch['produce']
  #print

if b_treeBuild:
  STree           = C_stree(['/'])
  STree.mknode(['produce', 'meat', 'cereal', 'dairy'])
  STree.cdnode('/produce')
  STree.mknode(['fruit', 'vegetables'])
  STree.cdnode('fruit')
  STree.mknode(['apple', 'pear'])
  STree.cdnode('/meat')
  STree.mknode(['beef', 'pork', 'chicken'])
  print STree
  S = STree

  
