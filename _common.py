'''
This class provides common functionality for python scripts such as parse commandline args, file I/O etc.
'''

# python base imports
import argparse
import os
import sys
import time
import socket

# Nibabel imports
from nibabel.trackvis import read as nibLoad
from nibabel.trackvis import write as nibSave
# Nipy imports
from nipy.io.files import load as nipLoad
from nipy.io.files import save as nipSave



class FNNDSCParser( argparse.ArgumentParser ):
  '''
  Use our own parser to always show help on errors.
  '''
  def error( self, message ):
      print
      sys.stderr.write( 'ERROR: %s\n' % message )
      print
      self.print_help()
      sys.exit( 2 )



class FNNDSCConsole():
  '''
  Provide Info, Error, Debug Print static convenience methods
  '''

  @staticmethod
  def __logStart():
    '''
    The first part of all output prints.
    '''
    return time.strftime( "%b %d %H:%M:%S" ) + " " + str( socket.gethostname() ) + " " + sys.argv[0] + "[" + str( os.getpid() ) + "]" + " "

  @staticmethod
  def debug( message, showDebugOutput = False ):
    '''
    Print a debug statement if showDebugOutput is True
    '''
    if showDebugOutput:
        message = FNNDSCConsole.__logStart() + "DEBUG: " + str( message )
        print message
        sys.stdout.flush()

  @staticmethod
  def error( message ):
    '''
    Print a serious error message.
    '''
    message = FNNDSCConsole.__logStart() + "ERROR: " + str( message ) + '\n'
    sys.stderr.write( message )
    sys.stderr.flush()


  @staticmethod
  def info( message ):
    '''
    Print an info message.
    '''
    message = FNNDSCConsole.__logStart() + str( message )
    print message
    sys.stdout.flush()



class FNNDSCFileIO():
  '''
  Provide File I/O static convenience methods
  '''

  @staticmethod
  def readImage( fileName ):
    '''
    '''
    if not os.path.isfile( fileName ):
      # we need the file
      FNNDSCConsole.error( 'Could not read ' + str( fileName ) )
      FNNDSCConsole.error( 'Aborting..' )
      sys.exit( 2 )

    fileType = os.path.splitext( fileName )[1]
    # we support the formats from NiPy
    validFileTypes = ['.nii', '.nii.gz', '.hdr', '.hdr.gz', '.img', '.img.gz']

    if not fileType in validFileTypes:
      FNNDSCConsole.error( fileType + ' is no valid file format..' )
      sys.exit( 2 )
    else:
      FNNDSCConsole.debug( 'Loading ' + str( fileType ).upper() + ' file..' )

      image = nipLoad( fileName )

      if not image:
        FNNDSCConsole.error( 'Could not read ' + str( fileName ) )
        FNNDSCConsole.error( 'Aborting..' )
        sys.exit( 2 )
      else:
        return image

  @staticmethod
  def saveImage( fileName, image ):
    '''
    '''
    if os.path.exists( fileName ):
      # abort if file already exists
      FNNDSCConsole.error( 'File ' + str( fileName ) + ' already exists..' )
      FNNDSCConsole.error( 'Aborting..' )
      sys.exit( 2 )

    if not image:
      FNNDSCConsole.error( 'Invalid image' )
      FNNDSCConsole.error( 'Aborting..' )
      sys.exit( 2 )

    return nipSave( image, fileName )

  @staticmethod
  def loadTrk( fileName ):
    '''
    '''
    if not os.path.isfile( fileName ):
      # we need the file
      FNNDSCConsole.error( 'Could not read ' + str( fileName ) )
      FNNDSCConsole.error( 'Aborting..' )
      sys.exit( 2 )

    fileType = os.path.splitext( fileName )[1]
    # we support the formats from NiPy
    validFileTypes = ['.trk']

    if not fileType in validFileTypes:
      FNNDSCConsole.error( fileType + ' is no valid file format..' )
      sys.exit( 2 )
    else:
      FNNDSCConsole.debug( 'Loading ' + str( fileType ).upper() + ' file..' )

      image = nibLoad( fileName )

      if not image:
        FNNDSCConsole.error( 'Could not read ' + str( fileName ) )
        FNNDSCConsole.error( 'Aborting..' )
        sys.exit( 2 )
      else:
        return image


  @staticmethod
  def saveTrk( fileName, tracks, header = None, endianness = None ):
    '''
    '''
    if os.path.exists( fileName ):
      # abort if file already exists
      FNNDSCConsole.error( 'File ' + str( fileName ) + ' already exists..' )
      FNNDSCConsole.error( 'Aborting..' )
      sys.exit( 2 )

    return nibSave( fileName, tracks, header, endianness )
