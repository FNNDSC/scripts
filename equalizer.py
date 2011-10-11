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

  def aniso2iso( self, image, spacing, dimensions ):
    '''
    from dipy.align.aniso2iso
    '''
    header = image.header
    oldspacing = header.get_zooms()
    olddimensions = image.shape[:3]

    if spacing == 'no':
      newspacing = ( min( oldspacing ), min( oldspacing ), min( oldspacing ) )
    else:
      newspacing = ( int( spacing.split( ',' )[0] ), int( spacing.split( ',' )[1] ), int( spacing.split( ',' )[2] ) )

    if dimensions == 'no':
      newdimensions = olddimensions
    else:
      newdimensions = ( int( dimensions.split( ',' )[0] ), int( dimensions.split( ',' )[1] ), int( dimensions.split( ',' )[2] ) )

    c.info( 'Resampling the master image..' )
    c.info( '    old spacing ' + str( oldspacing ) )
    c.info( '    old dimensions ' + str( olddimensions ) )


    # work on a numpy array to resample to isotropic spacing
    R = numpy.diag( numpy.array( newspacing ) / numpy.array( oldspacing ) )
    new_shape = numpy.array( oldspacing ) / numpy.array( newspacing ) * numpy.array( newdimensions )
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

    c.info( '    new spacing ' + str( newspacing ) )
    c.info( '    new dimensions ' + str( nipyImage.shape[:3] ) )

    return nipyImage

  def run( self, masterFile, inputFiles, outputDirectory, spacing, dimensions, likefreesurfer, nii ):
    '''
    Performs the equalization
    '''

    # sanity checks
    outputDirectory = os.path.normpath( outputDirectory )
    # prepare the output directory
    if os.path.exists( outputDirectory ):
      c.error( 'The output directory already exists!' )
      c.error( 'Aborting..' )
      sys.exit( 2 )
    # create the output directory
    os.mkdir( outputDirectory )


    # MASTER
    masterFile = os.path.normpath( masterFile )
    # read the master
    master = io.readImage( masterFile )
    c.info( 'MASTER IMAGE: ' + str( masterFile ) )


    # INPUTS
    for i in range( len( inputFiles ) ):
      inputFiles[i] = os.path.normpath( inputFiles[i] )
      c.info( 'INPUT IMAGE ' + str( i + 1 ) + ': ' + str( inputFiles[i] ) )


    # print more info
    c.info( 'OUTPUT DIRECTORY: ' + str( outputDirectory ) )

    if likefreesurfer:
      spacing = '1,1,1'
      dimensions = '256,256,256'

    if spacing != 'no':
      c.info( 'SET SPACINGS: ' + str( spacing ) )

    if dimensions != 'no':
      c.info( 'SET DIMENSIONS: ' + str( dimensions ) )


    # re-sample master to obtain an isotropic dataset
    master = self.aniso2iso( master, spacing, dimensions )
    masterFileBasename = os.path.split( masterFile )[1]
    masterFileBasenameWithoutExt = os.path.splitext( masterFileBasename )[0]

    if not nii:
      masterOutputFileName = os.path.join( outputDirectory, masterFileBasename )
    else:
      masterOutputFileName = os.path.join( outputDirectory, masterFileBasenameWithoutExt ) + '.nii'
    io.saveImage( masterOutputFileName, master )

    # equalize all images to the master
    for i in range( len( inputFiles ) ):
      currentInputFile = inputFiles[i]

      c.info( 'Equalizing ' + str( currentInputFile ) + ' to ' + str( masterFile ) + "..." )

      # load the image
      currentImage = io.readImage( currentInputFile )
      currentImageHeader = currentImage.header
      c.info( '    old spacing: ' + str( currentImageHeader.get_zooms() ) )
      c.info( '    old dimensions: ' + str( currentImage.shape[:3] ) )

      # now resample 
      resampledImage = resampler.resample_img2img( currentImage, master )

      # .. and save it
      currentInputFileBasename = os.path.split( currentInputFile )[1]
      currentInputFileBasenameWithoutExt = os.path.splitext( currentInputFileBasename )[0]
      if not nii:
        outputFileName = os.path.join( outputDirectory, currentInputFileBasename )
      else:
        outputFileName = os.path.join( outputDirectory, currentInputFileBasenameWithoutExt )

      savedImage = io.saveImage( outputFileName, resampledImage )
      #c.info( '    new spacing: ' + str( savedImageHeader.get_zooms() ) )
      c.info( '    new dimensions: ' + str( savedImage.shape[:3] ) )

    c.info( 'All done!' )

#
# entry point
#
parser = FNNDSCParser( description = 'Convert dimension, spacing and origin of input images to match a master image which gets converted to isotropic spacing' )

parser.add_argument( '-m', '--master', action = 'store', dest = 'master', required = True, help = 'master image to use for all input images, f.e. -m image00.img' )
parser.add_argument( '-i', '--input', action = 'append', dest = 'input', required = True, help = 'input images, f.e. -i ~/files/im01.img -i ~/files/im02.img -i ~/files/im03.img ..' )
parser.add_argument( '-o', '--output', action = 'store', dest = 'outputdirectory', required = True, help = 'output directory, f.e. -o /tmp/eq' )
parser.add_argument( '-s', '--spacing', action = 'store', dest = 'spacing', required = False, default = 'no', help = 'normalize image spacings to certain values, f.e. -n 0.5,0.5,0.5' )
parser.add_argument( '-d', '--dimensions', action = 'store', dest = 'dimensions', required = False, default = 'no', help = 'reshape images to certain dimensions, f.e. -r 512,512,512' )
parser.add_argument( '-lf', '--likefreesurfer', action = 'store_true', dest = 'likefreesurfer', required = False, default = False, help = 'normalizes and reshapes images to match the freesurfer default: spacing 1,1,1 and dimensions 256,256,256' )
parser.add_argument( '-n', '--nii', action = 'store_true', dest = 'nii', required = False, default = False, help = 'output in .nii format' )

# always show the help if no arguments were specified
if len( sys.argv ) == 1:
  parser.print_help()
  sys.exit( 1 )

options = parser.parse_args()

logic = EqualizerLogic()
logic.run( options.master, options.input, options.outputdirectory, options.spacing, options.dimensions, options.likefreesurfer, options.nii )
