'''
The equalizer converts/resamples a bunch of images to match a master image in terms of dimensions, origin and spacing.
'''

import sys
import os
from _common import FNNDSCParser
from _common import FNNDSCConsole as c
from _common import FNNDSCFileIO as io
import nipy.algorithms.resample as resampler
from nipy.core.api import fromarray
import numpy
from scipy.ndimage import affine_transform



class EqualizerLogic():
  '''
  '''

  def __init__( self ):
    '''
    '''

  def aniso2iso( self, image ):
    '''
    from dipy.align.aniso2iso
    '''
    header = image.header
    oldspacing = header.get_zooms()
    if oldspacing[0] == oldspacing[1] == oldspacing[2]:
      # no resampling necessary
      return

    newspacing = ( min( oldspacing ), min( oldspacing ), min( oldspacing ) )

    c.info( 'Resampling the master image to an isotropic dataset: old spacing ' + str( oldspacing ) + ' -> new spacing ' + str( newspacing ) )

    # work on a numpy array to resample to isotropic spacing
    R = numpy.diag( numpy.array( newspacing ) / numpy.array( oldspacing ) )
    new_shape = numpy.array( oldspacing ) / numpy.array( newspacing ) * numpy.array( image.shape[:3] )
    new_shape = numpy.round( new_shape ).astype( 'i8' )
    newImage = affine_transform( input = image, matrix = R, offset = numpy.zeros( 3, ), output_shape = tuple( new_shape ), order = 0 )
    Rx = numpy.eye( 4 )
    Rx[:3, :3] = R
    # get the mew world-image matrix
    affine = numpy.dot( image.coordmap.affine, Rx )

    # convert to NiPy image

    # copy the old coordmap and replace the affine matrix
    newCoordMap = image.coordmap
    newCoordMap.affine = affine

    # create a new NiPy image with the resampled data and the new coordmap (including the affine matrix)
    nipyImage = fromarray( newImage, '', '', newCoordMap )

    return nipyImage

  def run( self, masterFile, inputFiles, outputDirectory ):
    '''
    Performs the equalization
    '''

    # normalize all paths
    masterFile = os.path.normpath( masterFile )
    c.info( 'MASTER IMAGE: ' + str( masterFile ) )

    for i in range( len( inputFiles ) ):
      inputFiles[i] = os.path.normpath( inputFiles[i] )
      c.info( 'INPUT IMAGE ' + str( i + 1 ) + ': ' + str( inputFiles[i] ) )

    outputDirectory = os.path.normpath( outputDirectory )
    # prepare the output directory
    if os.path.exists( outputDirectory ):
      c.error( 'The output directory already exists!' )
      c.error( 'Aborting..' )
      sys.exit( 2 )
    # create the output directory
    os.mkdir( outputDirectory )
    c.info( 'OUTPUT DIRECTORY: ' + str( outputDirectory ) )


    # read the master
    master = io.readImage( masterFile )

    # re-sample master to obtain an isotropic dataset
    master = self.aniso2iso( master )
    masterOutputFileName = os.path.join( outputDirectory, os.path.split( masterFile )[1] )
    io.saveImage( masterOutputFileName, master )

    # equalize all images to the master
    for i in range( len( inputFiles ) ):
      currentInputFile = inputFiles[i]

      c.info( 'Equalizing ' + str( currentInputFile ) + ' to ' + str( masterFile ) + "..." )

      # load the image
      currentImage = io.readImage( currentInputFile )

      # now resample 
      resampledImage = resampler.resample_img2img( currentImage, master )

      # .. and save it
      outputFileName = os.path.join( outputDirectory, os.path.split( currentInputFile )[1] )
      io.saveImage( outputFileName, resampledImage )

    c.info( 'All done!' )

#
# entry point
#
parser = FNNDSCParser( description = 'Convert dimension, spacing and origin of input images to match a master image which gets converted to isotropic spacing' )

parser.add_argument( '-m', '--master', action = 'store', dest = 'master', required = True, help = 'master image to use for all input images, f.e. -m image00.img' )
parser.add_argument( '-i', '--input', action = 'append', dest = 'input', required = True, help = 'input images, f.e. -i ~/files/im01.img -i ~/files/im02.img -i ~/files/im03.img ..' )
parser.add_argument( '-o', '--output', action = 'store', dest = 'outputdirectory', required = True, help = 'output directory, f.e. -o /tmp/eq' )

# always show the help if no arguments were specified
if len( sys.argv ) == 1:
  parser.print_help()
  sys.exit( 1 )

options = parser.parse_args()

logic = EqualizerLogic()
logic.run( options.master, options.input, options.outputdirectory )
