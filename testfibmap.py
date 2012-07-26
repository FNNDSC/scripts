from _common import FNNDSCConsole as c
from _common import FNNDSCFileIO as io
from _common import FNNDSCUtil as u

import sys
import numpy



# ENTRYPOINT
if __name__ == "__main__":

  track = sys.argv[1]
  trackId = int( sys.argv[2] )
  volume = sys.argv[3]

  s = io.loadTrk( track )
  tracks = s[0]
  origHeader = s[1]


  image = io.readImage( volume )
  imageHeader = image.header
  imageDimensions = image.shape[:3]
  imageSpacing = imageHeader.get_zooms()

  singleTrack = tracks[trackId]

  coords = singleTrack[0]

  valueSum = 0

  length = 0
  _last = None
  for _current in coords:
    if _last != None:
      # we have the previous point
      length += numpy.sqrt( numpy.sum( ( _current - _last ) ** 2 ) )


    # convert to ijk
    ijkCoords = [x / y for x, y in zip( _current, imageSpacing )] # convert to ijk

    ijkCoords1 = [max( 1, x ) for x in ijkCoords] # make larger than 1
    ijkCoords2 = [max( 0, x ) for x in ijkCoords] # make positive



    # grab value
    value = image[int( ijkCoords[0] ), int( ijkCoords[1] ), int( ijkCoords[2] )]

    value1 = image[ijkCoords1[0], ijkCoords1[1], ijkCoords1[2]]
    value2 = image[int( ijkCoords2[0] ), int( ijkCoords2[1] ), int( ijkCoords2[2] )]

    print 'value (untouched)', value
    print 'value (>1)', value1
    print 'value (>0)', value2

    valueSum += value

    _last = _current

  print 'valueSum', valueSum
  print 'valueMean', valueSum / len( coords )

  print singleTrack
  print 'length', "%.100f" % length


  io.saveTrk( '/chb/tmp/nico.trk', [singleTrack], origHeader, None, True )
