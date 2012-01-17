from bucket import Bucket
from wheel import Wheel, WheelValidationException

class Pipeline:

  def __init__( self, bucket ):
    self.__wheels = ['__START__']
    self.__bucket = bucket
    self.__bucketSimulator = Bucket( self.__bucket.content() )

  def add( self, wheel ):
    # validate if the next wheel can spin correctly..
    self.__validate( wheel )

    # it can! add it!
    self.__wheels.append( wheel )

  def __validate( self, nextClassname ):

    try:
      next = nextClassname( self.__bucketSimulator )

      for i in next.inputs():

        if self.__bucketSimulator.get( i ):
          # the input is there
          continue
        else:
          raise Exception

      for o in next.outputs():
        # add the outputs to our bucket simulator
        self.__bucketSimulator.put( o, 'xyz' )

    except WheelValidationException as e:
      raise Exception( 'Broken pipe: Connection between ' + str( self.__wheels[-1] )
                       + ' and ' + str( nextClassname ) + ' not possible - "' + e.input
                       + '" is missing in the bucket..' )

  def run( self ):

    # loop through the wheels (except the __START__) and spin'em!!
    for w in self.__wheels[1:]:

      currentWheel = w( self.__bucket )
      currentWheel.spin()

