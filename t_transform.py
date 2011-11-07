#!/usr/bin/env python
import sys
import os
from _common import FNNDSCParser
from _common import FNNDSCConsole as c
from _common import FNNDSCFileIO as io
import numpy

class TrackvisTransformLogic( object ):

  def __init__( self ):
    '''
    '''
    pass

  def run( self, input, output, matrix, replace ):
    '''
    '''

    if os.path.exists( output ):
      # abort if file already exists
      c.error( 'File ' + str( output ) + ' already exists..' )
      c.error( 'Aborting..' )
      sys.exit( 2 )

    if not os.path.isfile( matrix ):
      # abort if the matrix does not exist
      c.error( 'Matrix-File ' + str( matrix ) + ' does not exist..' )
      c.error( 'Aborting..' )
      sys.exit( 2 )

    # read
    c.info( 'Loading ' + input + '..' )

    t = io.loadTrk( input )
    tracks = t[0]
    header = t[1]
    #.. copy the current header
    newHeader = numpy.copy( header )

    oldMatrix = header['vox_to_ras']
    c.info( 'Old transformation matrix:' )
    c.info( '    ' + str( oldMatrix[0] ) )
    c.info( '    ' + str( oldMatrix[1] ) )
    c.info( '    ' + str( oldMatrix[2] ) )
    c.info( '    ' + str( oldMatrix[3] ) )

    # modify
    #newMatrix = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    newMatrix = numpy.loadtxt( matrix, float, '#', ' ' )

    if replace:
      c.info( 'Replacing old transformation matrix with:' )
      result = newMatrix
    else:
      c.info( 'Multiplying old transformation matrix with:' )
      c.info( '    ' + str( newMatrix[0] ) )
      c.info( '    ' + str( newMatrix[1] ) )
      c.info( '    ' + str( newMatrix[2] ) )
      c.info( '    ' + str( newMatrix[3] ) )
      result = numpy.dot( oldMatrix, newMatrix )
      c.info( 'Result:' )

    c.info( '    ' + str( result[0] ) )
    c.info( '    ' + str( result[1] ) )
    c.info( '    ' + str( result[2] ) )
    c.info( '    ' + str( result[3] ) )
    newHeader['vox_to_ras'] = result


    # write
    c.info( 'Saving ' + output + '..' )
    io.saveTrk( output, tracks, newHeader )

    c.info( 'All done!' )

#
# entry point
#
parser = FNNDSCParser( description = 'Transform TrackVis (*.trk) files.' )


parser.add_argument( '-i', '--input', action = 'store', dest = 'input', required = True, help = 'input trackvis file, f.e. -i ~/files/f01.trk' )
parser.add_argument( '-o', '--output', action = 'store', dest = 'output', required = True, help = 'output trackvis file, f.e. -o /tmp/f_out.trk' )
parser.add_argument( '-m', '--matrix', action = 'store', dest = 'matrix', required = True, help = 'transformation matrix file, f.e. -m ~/files/f01.mat - a 4x4 matrix is required.' )
parser.add_argument( '-r', '--replace', action = 'store_true', dest = 'replace', help = 'replace the old transformation matrix with the specified one instead of multiplying it.' )

# always show the help if no arguments were specified
if len( sys.argv ) == 1:
  parser.print_help()
  sys.exit( 1 )

options = parser.parse_args()

logic = TrackvisTransformLogic()
logic.run( options.input, options.output, options.matrix, options.replace )
