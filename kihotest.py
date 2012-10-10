#test
from nipy.core.image import image
from nipy.io.api import load_image, save_image
import numpy as np

from _common import FNNDSCFileIO as io
import fyborg

volFile = '/chb/tmp/kihotest.nii'
trkFile = '/chb/tmp/kihotest.trk'
mappedTrkFile = '/chb/tmp/kihotest_mapped.trk'


# volume
testArr = np.zeros( ( 10, 10, 10 ) )

r = 0
for i in range( testArr.shape[0] ):
  for j in range( testArr.shape[1] ):
    for k in range( testArr.shape[2] ):
      r += 1
      testArr[i, j, k] = r

img = image.fromarray( testArr, 'ijk', 'xyz' )

save_image( img, volFile )


# trk file
fibers = []

# 2,5,6
# 3,5,7
# 2,6,7
# 8,7,3
# 9,5,4
points = np.array( [[2, 5, 6], [3, 5, 7], [2, 6, 7], [8, 7, 3], [9, 5, 4]], dtype=np.float32 )

fibers.append( ( points, None, None ) )

io.saveTrk( trkFile, fibers, None, None, True )

# with fyborg
fyborg.fyborg( trkFile, mappedTrkFile, [fyborg.FyMapAction( 'test', volFile )] )


# now validate
s = io.loadTrk( mappedTrkFile )
tracks = s[0]
origHeader = s[1]
scalars = tracks[0][1]
print scalars[0], '==', testArr[2][5][6]
print scalars[1], '==', testArr[3][5][7]
print scalars[2], '==', testArr[2][6][7]
print scalars[3], '==', testArr[8][7][3]
print scalars[4], '==', testArr[9][5][4]
