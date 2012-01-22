#!/usr/bin/env python

import systemMisc       as misc
import numpy            as np

col2sort = lambda A: np.sort(A.view('i8,i8'), order=['f0','f1'], axis=0).view(np.int)

misc.tic()
A1 = misc.neighbours_find(2,2, np.array((4,4)),
                              gridSize          = np.array((5,5)),
                              wrapGridEdges     = True,
                              returnUnion       = True)
misc.toc()
print col2sort(A1.astype(int))

misc.tic()
A2 = misc.neighbours_findFast(2,2, np.array((4,4)),
                              gridSize          = np.array((5,5)),
                              wrapGridEdges     = True,
                              returnUnion       = True,
                              includeOrigin     = True)
misc.toc()
print col2sort(A2)
