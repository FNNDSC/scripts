from bucket import Bucket
from wheel import Wheel, WheelValidationException
import time
import multiprocessing as m

class Pipeline:

  def __init__( self, bucket ):
    self.__wheels = ['__START__']
    self.__bucket = bucket
    #self.__bucketSimulator = Bucket( self.__bucket.content() )
    self.__threads = 0

  def add( self, wheel ):
    # validate if the next wheel can spin correctly..
    #self.__validate( wheel )

    # it can! add it!
    self.__wheels.append( wheel )

  def __validate( self, nextClassname ):
    pass
#
#    try:
#      next = nextClassname( self.__bucketSimulator )
#
#      for i in next.inputs():
#
#        if self.__bucketSimulator.get( i ):
#          # the input is there
#          continue
#        else:
#          raise Exception
#
#      for o in next.outputs():
#        # add the outputs to our bucket simulator
#        self.__bucketSimulator.put( o, 'xyz' )
#
#    except WheelValidationException as e:
#      raise Exception( 'Broken pipe: Connection between ' + str( self.__wheels[-1] )
#                       + ' and ' + str( nextClassname ) + ' not possible - "' + e.input
#                       + '" is missing in the bucket..' )

  def run( self ):

    numberOfThreads = 3

    # loop through the wheels (except the __START__) and add them to the threads list
    for w in self.__wheels[1:]:

      threads.append( Process( target=w.spin, args=() ) )


    # the main loop
    while 1:

      # take a deep breath
      time.sleep( 1 )

      # check how many threads are running
      runningThreads = [t for t in threads if t.is_alive()]
      finishedThreads = [t for t in threads if t.exitcode != None]

      # check if we are all done
      if len( finishedThreads ) == len( threads ):
        # we are all done since all threads finished
        # this should be the only valid exit..
        break

      if len( runningThreads ) < numberOfThreads:
        # we can start another thread, if possible
        for t in threads:
          if t.


        # check if inputs are there for any new thread
        # if YES, start it

        # if NO, continue
        pass

    print "All done! Sayonara.."
