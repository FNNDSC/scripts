import sys
import os
from _common import FNNDSCParser
from _common import FNNDSCConsole as c
from _common import FNNDSCFileIO as io

class TrackvisCalcLogic():

  def __init__( self ):
    '''
    '''
    pass

  def run( self, input, output, sub ):

    if len( input ) < 2:
      c.error( 'Please specify at least two *.trk files as input!' )
      sys.exit( 2 )



    print input
    print output
    print sub

#
# entry point
#
parser = FNNDSCParser( description = 'Add or subtract TrackVis (*.trk) files. The default action is: add.' )

parser.add_argument( '-i', '--input', action = 'append', dest = 'input', required = True, help = 'input trackvis files, f.e. -i ~/files/f01.trk -i ~/files/f02.trk -i ~/files/f03.trk ..' )
parser.add_argument( '-o', '--output', action = 'store', dest = 'output', required = True, help = 'output trackvis file, f.e. -o /tmp/f_out.trk' )
parser.add_argument( '-s', '--sub', action = 'store_true', dest = 'sub', required = False, default = False, help = 'subtract all other input tracks from the first specified input' )

# always show the help if no arguments were specified
if len( sys.argv ) == 1:
  parser.print_help()
  sys.exit( 1 )

options = parser.parse_args()

logic = TrackvisCalcLogic()
logic.run( options.input, options.output, options.sub )
