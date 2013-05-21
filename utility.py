#
# FYBORG3000
#

# standard imports
import re, shutil, tempfile

# third-party imports
import numpy


class Utility():
  '''
  Utility functions.
  '''

  @staticmethod
  def chunks( l, n ):
    '''
    Yield successive n-sized chunks from l.
    
    From: http://stackoverflow.com/a/312464/1183453
    '''
    for i in xrange( 0, len( l ), n ):
        yield l[i:i + n]

  @staticmethod
  def natsort( l ):
    '''
    Sorts in a natural way.
    
    F.e. abc0 abc1 abc10 abc12 abc9 is sorted with python's sort() method
    This function would return abc0 abc1 abc9 abc10 abc12.
    
    From: http://stackoverflow.com/a/4836734/1183453
    '''
    convert = lambda text: int( text ) if text.isdigit() else text.lower()
    alphanum_key = lambda key: [ convert( c ) for c in re.split( '([0-9]+)', key ) ]
    return sorted( l, key=alphanum_key )

  @staticmethod
  def setupEnvironment():
    '''
    Setup a F3000 temporary environment.

    Returns
      The temporary folder.
    '''
    return tempfile.mkdtemp( 'F3000', '', '/tmp' )

  @staticmethod
  def teardownEnvironment( tempdir ):
    '''
    Remove a F3000 temporary environment.
    
    tempdir
      The temporary folder to remove.
    '''
    shutil.rmtree( tempdir )

  @staticmethod
  def readITKtransform( transform_file ):
    '''
    '''

    # read the transform
    transform = None
    with open( transform_file, 'r' ) as f:
      for line in f:

        # check for Parameters:
        if line.startswith( 'Parameters:' ):
          values = line.split( ': ' )[1].split( ' ' )

          # filter empty spaces and line breaks
          values = [float( e ) for e in values if ( e != '' and e != '\n' )]
          # create the upper left of the matrix
          transform_upper_left = numpy.reshape( values[0:9], ( 3, 3 ) )
          # grab the translation as well
          translation = values[9:]

        # check for FixedParameters:
        if line.startswith( 'FixedParameters:' ):
          values = line.split( ': ' )[1].split( ' ' )

          # filter empty spaces and line breaks
          values = [float( e ) for e in values if ( e != '' and e != '\n' )]
          # setup the center
          center = values

    # compute the offset
    offset = numpy.ones( 4 )
    for i in range( 0, 3 ):
      offset[i] = translation[i] + center[i];
      for j in range( 0, 3 ):
        offset[i] -= transform_upper_left[i][j] * center[i]


    # add the [0, 0, 0] line
    transform = numpy.vstack( ( transform_upper_left, [0, 0, 0] ) )
    # and the [offset, 1] column
    transform = numpy.hstack( ( transform, numpy.reshape( offset, ( 4, 1 ) ) ) )

    return transform
