#!/usr/bin/env python
import sys
import os
from _common import FNNDSCUtil as u
from _common import FNNDSCConsole as c
from _common import FNNDSCFileIO as io

class TrackInfoLogic():
  '''
  '''

  def __init__( self ):
    '''
    '''

  def run( self, files ):
    '''
    '''
    for f in files:

      header = io.loadTrkHeaderOnly( f )
      dimensions = header['dim']
      spacing = header['voxel_size']
      origin = header['origin']
      numberOfScalars = header['n_scalars']
      scalarNames = header['scalar_name']
      numberOfProperties = header['n_properties']
      propertyNames = header['property_name']
      vox2rasMatrix = header['vox_to_ras']
      voxelOrder = header['voxel_order']
      pad1 = header['pad1']
      pad2 = header['pad2']
      imageOrientation = header['image_orientation_patient']
      numberOfTracks = header['n_count']
      version = header['version']

      c.info( 'FILE: ' + f )

      c.info( '  TRACKVIS VERSION: ' + str( version ) )
      c.info( '  NUMBER OF TRACKS: ' + str( numberOfTracks ) )

      c.info( '  DIMENSIONS: ' + str( dimensions ) )
      c.info( '  SPACING: ' + str( spacing ) )
      c.info( '  ORIGIN: ' + str( origin ) )

      c.info( '  NUMBER OF SCALARS: ' + str( numberOfScalars ) )
      if numberOfScalars > 0:
        c.info( '    SCALARS: ' + str( scalarNames ) )

      c.info( '  NUMBER OF PROPERTIES: ' + str( numberOfProperties ) )
      if numberOfProperties > 0:
        c.info( '    PROPERTIES: ' + str( propertyNames ) )

      if version == 2:
        # only in trackvis v2
        c.info( '  VOX2RAS Matrix:' )
        c.info( '    ' + str( vox2rasMatrix[0] ) )
        c.info( '    ' + str( vox2rasMatrix[1] ) )
        c.info( '    ' + str( vox2rasMatrix[2] ) )
        c.info( '    ' + str( vox2rasMatrix[3] ) )

      c.info( '  VOXEL ORDER: ' + str( voxelOrder ) )
      #c.info( '  IMAGE ORIENTATION: ' )
      #c.info( '    ' + str( imageOrientation ) )
      #c.info( '  PADDING 1: ' + str( pad1 ) )
      #c.info( '  PADDING 2: ' + str( pad2 ) )

      print



def print_help( scriptName ):
  '''
  '''
  description = 'Print information on TrackVis (*.trk) files.'
  print description
  print
  print 'Usage: python ' + scriptName + ' FILE1.trk'
  print 'Usage: python ' + scriptName + ' FILE1.trk FILE2.trk ...'
  print


#
# entry point
#
if __name__ == "__main__":

  # always show the help if no arguments were specified
  if len( sys.argv ) < 2:
    print_help( sys.argv[0] )
    sys.exit( 1 )

  logic = TrackInfoLogic()
  logic.run( sys.argv[1:] )
