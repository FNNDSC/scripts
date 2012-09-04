#!/usr/bin/env python
import sys
import os
import tempfile
import multiprocessing
import time
from multiprocessing import Process
from _common import FNNDSCParser
from _common import FNNDSCConsole as c
from _common import FNNDSCFileIO as io
from _common import FNNDSCUtil as u
from t_calc import TrackvisCalcLogic
import numpy

class TrackvisTransformLogic( object ):

  def __init__( self ):
    '''
    '''
    pass

  def run( self, input, output, matrix, jobs ):
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

    jobs = int( jobs )

    if jobs < 1 or  jobs > 32:
      jobs = 1

    # read
    c.info( 'Loading ' + input + '..' )

    t = io.loadTrk( input )
    tracks = t[0]
    header = t[1]
    #.. copy the current header
    newHeader = numpy.copy( header )

    # print old matrix in header
    # 
    # WARNING: this matrix is actually never used by TrackVis (see email from Ruopeng).
    # We still modify it to keep it in sync with the transformations which we apply point wise.
    #
    if hasattr( header, 'vox_to_ras' ):
      oldMatrix = header['vox_to_ras']
      c.info( 'Old transformation matrix:' )
      c.info( '    ' + str( oldMatrix[0] ) )
      c.info( '    ' + str( oldMatrix[1] ) )
      c.info( '    ' + str( oldMatrix[2] ) )
      c.info( '    ' + str( oldMatrix[3] ) )

    #
    # load our transformation Matrix
    #
    newMatrix = numpy.loadtxt( matrix, float, '#', ' ' )


    #
    # THREADED COMPONENT
    #
    numberOfThreads = jobs
    c.info( 'Splitting the input into ' + str( jobs ) + ' pieces..' )
    splittedOutputTracks = u.split_list( tracks, numberOfThreads )

    # list of threads
    t = [None] * numberOfThreads

    # list of alive flags
    a = [None] * numberOfThreads

    # list of tempFiles
    f = [None] * numberOfThreads

    for n in xrange( numberOfThreads ):
      # mark thread as alive
      a[n] = True
      # fire the thread and give it a filename based on the number
      tmpFile = tempfile.mkstemp( '.trk', 't_transform' )[1]
      f[n] = tmpFile
      t[n] = Process( target=TrackvisTransformLogic.transform, args=( splittedOutputTracks[n][:], newMatrix, tmpFile, False, 'Thread-' + str( n + 1 ) ) )
      c.info( "Starting Thread-" + str( n + 1 ) + "..." )
      t[n].start()

    allDone = False

    while not allDone:

      time.sleep( 1 )

      for n in xrange( numberOfThreads ):

        a[n] = t[n].is_alive()

      if not any( a ):
        # if no thread is alive
        allDone = True

    #
    # END OF THREADED COMPONENT
    #
    c.info( "All Threads done!" )

    c.info( "Merging output.." )
    # now read all the created tempFiles and merge'em to one
    # first thread output is the master here
    tmpMaster = f[0]
    tMasterTracks = io.loadTrk( tmpMaster )
    for tmpFileNo in xrange( 1, len( f ) ):
      tTracks = io.loadTrk( f[tmpFileNo] )

      # add them
      tracks = TrackvisCalcLogic.add( tMasterTracks[0], tTracks[0] )

    c.info( "Merging done!" )

    #
    # replace the matrix in the header with a transformed one even if it will never be used by TrackVis
    #
    if hasattr( header, 'vox_to_ras' ):
      result = numpy.dot( oldMatrix, newMatrix )
      c.info( 'New transformation matrix:' )
      c.info( '    ' + str( result[0] ) )
      c.info( '    ' + str( result[1] ) )
      c.info( '    ' + str( result[2] ) )
      c.info( '    ' + str( result[3] ) )
      newHeader['vox_to_ras'] = result

    # write
    c.info( 'Saving ' + output + '..' )
    io.saveTrk( output, tracks, newHeader )

    c.info( 'All done!' )


  @staticmethod
  def transform( tracks, matrix, outputFile=None, verbose=False, threadName='Global' ):
    '''
    '''
    # O(Tracks x Points)
    #
    # loop through all tracks and transform'em!!
    for t in xrange( len( tracks ) ):

      track = tracks[t]

      points = track[0]
      newPoints = numpy.copy( points )

      # loop through all points of the current track
      for p in xrange( len( points ) ):

        pointBefore = points[p]

        pointAfter = numpy.append( pointBefore, 1 )
        pointAfter = numpy.dot( matrix, pointAfter )
        pointAfter = numpy.delete( pointAfter, -1 )

        newPoints[p] = pointAfter

      # create a new track with the transformed points
      newTrack = ( newPoints, track[1], track[2] )

      # replace the old track with the newTrack
      tracks[t] = newTrack

    if not outputFile:
      return tracks
    else:
      # write it out to disk
      io.saveTrk( outputFile, tracks, None, None, True )

#
# entry point
#
if __name__ == "__main__":
  parser = FNNDSCParser( description='Transform TrackVis (*.trk) files.' )


  parser.add_argument( '-i', '--input', action='store', dest='input', required=True, help='input trackvis file, f.e. -i ~/files/f01.trk' )
  parser.add_argument( '-o', '--output', action='store', dest='output', required=True, help='output trackvis file, f.e. -o /tmp/f_out.trk' )
  parser.add_argument( '-m', '--matrix', action='store', dest='matrix', required=True, help='transformation matrix file, f.e. -m ~/files/f01.mat - a 4x4 matrix is required.' )
  parser.add_argument( '-j', '--jobs', action='store', dest='jobs', default=multiprocessing.cpu_count(), help='number of parallel computations, f.e. -j 10' )

  # always show the help if no arguments were specified
  if len( sys.argv ) == 1:
    parser.print_help()
    sys.exit( 1 )

  options = parser.parse_args()

  logic = TrackvisTransformLogic()
  logic.run( options.input, options.output, options.matrix, options.jobs )
