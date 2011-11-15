import sys
import os
from _common import FNNDSCParser
from _common import FNNDSCConsole as c
from _common import FNNDSCFileIO as io
import nipy.algorithms.resample as resampler
from nipy.core.api import subsample, slice_maker
from nipy.core.api import fromarray
from nipy.algorithms.registration.histogram_registration import HistogramRegistration
from nipy.core.reference import coordinate_map
import numpy
from scipy.ndimage import affine_transform

class Slice2SliceLogic():


  def __init__( self ):
    '''
    '''

  def run( self, inputFile, outputFile ):
    '''
    Performs the registration
    '''

    image = io.readImage( inputFile )

    slices = []

    for z in range( 0, image.shape[2] ):

      slice = image[:, :, z:z + 1]
      print slice.shape
      slices.append( slice )


    slice = slices[0]
    #slice.coordmap = image.coordmap
    print slice.coordmap

    #slice.coordmap = coordinate_map.drop_io_dim( slice.coordmap, slice.coordmap.function_range.coord_names[-1] )

    print slice.coordmap

    R = HistogramRegistration( slices[0], slices[1] )
    R.subsample( [4, 4, 4] )
    affine = R.optimize( 'affine' )



    io.saveImage( '~/slice.nii', slice )

    sys.exit()


#
# entry point
#
parser = FNNDSCParser( description = 'Perform slice-by-slice registration' )

parser.add_argument( '-i', '--input', action = 'store', dest = 'input', required = True, help = 'input image, f.e. -i ~/files/im01.img' )
parser.add_argument( '-o', '--output', action = 'store', dest = 'output', required = True, help = 'output image, f.e. -o /tmp/im01.img' )


# always show the help if no arguments were specified
if len( sys.argv ) == 1:
  parser.print_help()
  sys.exit( 1 )

options = parser.parse_args()

logic = Slice2SliceLogic()
logic.run( options.input, options.output )
