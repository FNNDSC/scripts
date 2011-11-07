#!/usr/bin/env python
import sys
import os
import time
import tempfile
import multiprocessing
from multiprocessing import Process, Queue
from Queue import Empty
from _common import FNNDSCUtil as u
from _common import FNNDSCParser
from _common import FNNDSCConsole as c
from _common import FNNDSCFileIO as io

import numpy

class TrackvisCalcLogic( object ):

  def __init__( self ):
    '''
    '''
    pass

  def run( self, input, output, mode, verbose, jobs ):

    if len( input ) < 2:
      c.error( 'Please specify at least two *.trk files as input!' )
      sys.exit( 2 )

    if os.path.exists( output ):
      # abort if file already exists
      c.error( 'File ' + str( output ) + ' already exists..' )
      c.error( 'Aborting..' )
      sys.exit( 2 )

    jobs = int( jobs )

    if jobs < 1 or  jobs > 32:
      jobs = 1

    # load 'master'
    mTracks = io.loadTrk( input[0] )

    # copy the tracks and the header from the 'master'
    c.info( 'Master is ' + input[0] )
    outputTracks = mTracks[0]
    c.info( 'Number of tracks: ' + str( len( outputTracks ) ) )
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
        c.debug( 'Adding ' + str( len( iTracks[0] ) ) + ' tracks from ' + i + ' to master..', verbose )
        outputTracks = TrackvisCalcLogic.add( outputTracks, iTracks[0] )

      c.debug( 'Number of output tracks after final addition: ' + str( len( outputTracks ) ), verbose )

    elif mode == 'sub':
      #
      # SUB
      #

      c.debug( 'Using ' + str( jobs ) + ' threads..', verbose )

      mergedOutputTracks = outputTracks[:]

      for i in input:
        iTracks = io.loadTrk( i )

        # subtract the tracks
        c.info( 'Subtracting ' + i + ' (' + str( len( iTracks[0] ) ) + ' tracks) from master..' )

        #
        # THREADED COMPONENT
        #
        numberOfThreads = jobs
        c.info( 'Splitting master into ' + str( jobs ) + ' pieces..' )
        splittedOutputTracks = u.split_list( mergedOutputTracks, numberOfThreads )

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
          tmpFile = tempfile.mkstemp( '.trk', 't_calc' )[1]
          f[n] = tmpFile
          t[n] = Process( target = TrackvisCalcLogic.sub, args = ( splittedOutputTracks[n][:], iTracks[0][:], tmpFile, verbose, 'Thread-' + str( n + 1 ) ) )
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
          mergedOutputTracks = TrackvisCalcLogic.add( tMasterTracks[0], tTracks[0] )

        c.info( "Merging done!" )


      # some stats
      c.info( 'Number of output tracks after final removal: ' + str( len( mergedOutputTracks ) ) )
      outputTracks = mergedOutputTracks

    # now save the outputTracks
    io.saveTrk( output, outputTracks, header )

    c.info( 'All done!' )


  @staticmethod
  def add( master, tracks ):
    '''
    Add tracks to master. Both parameters are nibabel.trackvis.streamlines objects.
    
    Returns the result as a nibabel.trackvis.streamlines object.
    '''
    # append the tracks to the master
    master.extend( tracks )
    return master

  @staticmethod
  def sub( master, tracks, outputFile = None, verbose = False, threadName = 'Global' ):
    '''
    Subtract tracks from master. Both parameters are nibabel.trackvis.streamlines objects.
    
    Calculation cost: O(M*N)
    
    Returns the result as a nibabel.trackvis.streamlines object or writes it to the file system if an outputFile is specified.
    '''
    masterSizeBefore = len( master )

    subtractedCount = 0

    # O(M*N)
    for t in xrange( masterSizeBefore ):

      if subtractedCount == len( tracks ):
        # no way we can subtract more.. stop the loop
        return master

      c.debug( threadName + ': Looking for more tracks to subtract.. [Check #' + str( t ) + '/' + str( masterSizeBefore ) + ']', verbose )

      if master[t] == -1:
        # this fiber was already removed, skip to next one
        continue

      for u in xrange( len( tracks ) ):

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

    master = filter ( lambda t: t != -1, master )

    if not outputFile:
      return master
    else:
      # write it out to disk
      io.saveTrk( outputFile, master, None, None, True )


#
# entry point
#
parser = FNNDSCParser( description = 'Add or subtract TrackVis (*.trk) files.' )


parser.add_argument( '-i', '--input', action = 'append', dest = 'input', required = True, help = 'input trackvis files, f.e. -i ~/files/f01.trk -i ~/files/f02.trk -i ~/files/f03.trk ..' )
parser.add_argument( '-o', '--output', action = 'store', dest = 'output', required = True, help = 'output trackvis file, f.e. -o /tmp/f_out.trk' )
parser.add_argument( '-j', '--jobs', action = 'store', dest = 'jobs', default = multiprocessing.cpu_count(), help = 'number of parallel computations, f.e. -j 10' )
parser.add_argument( '-v', '--verbose', action = 'store_true', dest = 'verbose', help = 'show verbose output' )
parser.add_argument( 'mode', choices = ['add', 'sub'], help = 'ADD all input tracks to one file or SUBTRACT all other input tracks from the first specified input' )

# always show the help if no arguments were specified
if len( sys.argv ) == 1:
  parser.print_help()
  sys.exit( 1 )

options = parser.parse_args()

logic = TrackvisCalcLogic()
logic.run( options.input, options.output, options.mode, options.verbose, options.jobs )
