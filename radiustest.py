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

#img = image.fromarray( testArr, 'ijk', 'xyz' )

#save_image( img, volFile )
a = 5
b = 5
c = 5
r = 2
print testArr[a][b][c]
croppedImage = np.asarray( testArr[a - r:a + r + 1, b - r:b + r + 1, c - r:c + r + 1] )
print croppedImage
x, y, z = np.ogrid[0:2 * r + 1, 0:2 * r + 1, 0:2 * r + 1]
#print x, y, z
mask = ( x - r ) ** 2 + ( y - r ) ** 2 + ( z - r ) ** 2 <= r * r # 3d sphere mask
print mask
from collections import Counter
counter = Counter( croppedImage[mask] )
print counter
mostFrequentLabel = counter.most_common( 1 )[0][0]
print mostFrequentLabel
