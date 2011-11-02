import sys
import os
import threading
from _common import FNNDSCParser
from _common import FNNDSCConsole as c
from _common import FNNDSCFileIO as io

import numpy

class TrackvisCalcLogic():

  def __init__( self ):
    '''
    '''
    pass

  def run( self, input, output, mode, verbose ):

    if len( input ) < 2:
      c.error( 'Please specify at least two *.trk files as input!' )
      sys.exit( 2 )

    if os.path.exists( output ):
      # abort if file already exists
      c.error( 'File ' + str( output ) + ' already exists..' )
      c.error( 'Aborting..' )
      sys.exit( 2 )

    # load 'master'
    mTracks = io.loadTrk( input[0] )

    # copy the tracks and the header from the 'master'
    c.debug( 'Master is ' + input[0], verbose )
    outputTracks = mTracks[0]
    c.debug( 'Number of tracks: ' + str( len( outputTracks ) ), verbose )
    header = mTracks[1]

    # remove the first input
    input.pop( 0 )

    if mode == 'add':
      #
      # ADD
      #

      for i in input:
        iTracks = io.loadTrk( i )

        # add the tracks
        c.debug( 'Adding tracks from ' + i, verbose )
        outputTracks = TrackvisCalcLogic.add( outputTracks, iTracks[0] )

    elif mode == 'sub':
      #
      # SUB
      #

      for i in input:
        iTracks = io.loadTrk( i )

        # subtract the tracks
        c.debug( 'Subtracting ' + i + ' (' + str( len( iTracks[0] ) ) + ' tracks) from master..', verbose )
        t = subThread( outputTracks, iTracks[0], verbose )
        t.start()
        t.join()
        outputTracks = t.getOutput()

      # now we marked all relevant 'dirty'.. remove'em
      c.debug( 'Number of output tracks before final removal: ' + str( len( outputTracks ) ), verbose )
      outputTracks = filter ( lambda t: t != -1, outputTracks )
      c.debug( 'Number of output tracks after final removal: ' + str( len( outputTracks ) ), verbose )

    # now save the outputTracts
    io.saveTrk( output, outputTracks, header )

    c.info( 'All done!' )


  @staticmethod
  def add( self, master, tracks ):
    '''
    Add tracks to master. Both parameters are nibabel.trackvis.streamlines objects.
    
    Returns the result as a nibabel.trackvis.streamlines object.
    '''
    if not master:
      c.error( 'No Master!' )
      return ( -1 )

    if not tracks:
      c.error( 'No tracks!' )
      return ( -1 )

    # append the tracks to the master
    master.extend( tracks )
    return master

  @staticmethod
  def sub( master, tracks, verbose, threadName = 'Global' ):
    '''
    Subtract tracks from master. Both parameters are nibabel.trackvis.streamlines objects.
    
    Calculation cost: O(M*N)
    
    Returns the result as a nibabel.trackvis.streamlines object.
    '''
    masterSizeBefore = len( master )

    subtractedCount = 0

    # O(M*N)
    for t in range( masterSizeBefore ):

      if subtractedCount == len( tracks ):
        # no way we can subtract more.. stop the loop
        return master

      moreToGo = len( tracks ) - subtractedCount
      c.debug( threadName + ': Looking for ' + str( moreToGo ) + ' more tracks to subtract.. [Check #' + str( t ) + '/' + str( masterSizeBefore ) + ']', verbose )

      if master[t] == -1:
        # this fiber was already removed, skip to next one
        continue

      for u in range( len( tracks ) ):

        if tracks[u] == -1:
          # this fiber was already removed, skip to next one
          continue

        # compare fiber
        if [p for points in master[t][0] for p in points] == [p for points in tracks[u][0] for p in points]:
          # fibers are equal, set them as dirty
          master[t] = -1
          tracks[u] = -1
          subtractedCount += 1
          # ... and jump out
          break

    return master


# multithreading
class subThread( threading.Thread ):

  def __init__( self, master, tracks, verbose ):
    '''
    '''
    self.__master = master
    self.__tracks = tracks
    self.__verbose = verbose
    self.__output = None

  def run( self ):
    '''
    Runs the subtraction
    '''
    self.__output = list( TrackvisCalcLogic.sub( self.__master, self.__tracks, self.__verbose, self.getName() ) )

  def getOutput( self ):
    '''
    '''
    return self.__output


#
# entry point
#
parser = FNNDSCParser( description = 'Add or subtract TrackVis (*.trk) files.' )


parser.add_argument( '-i', '--input', action = 'append', dest = 'input', required = True, help = 'input trackvis files, f.e. -i ~/files/f01.trk -i ~/files/f02.trk -i ~/files/f03.trk ..' )
parser.add_argument( '-o', '--output', action = 'store', dest = 'output', required = True, help = 'output trackvis file, f.e. -o /tmp/f_out.trk' )
parser.add_argument( '-v', '--verbose', action = 'store_true', dest = 'verbose', help = 'show verbose output' )
parser.add_argument( 'mode', choices = ['add', 'sub'], help = 'ADD all input tracks to one file or SUBTRACT all other input tracks from the first specified input' )

# always show the help if no arguments were specified
if len( sys.argv ) == 1:
  parser.print_help()
  sys.exit( 1 )

options = parser.parse_args()

logic = TrackvisCalcLogic()
logic.run( options.input, options.output, options.mode, options.verbose )
