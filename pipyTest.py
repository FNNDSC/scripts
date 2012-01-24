# pipelines in python ("pipy Wheels") - simple demo
import pipy

class Connectivity( pipy.Wheel ):

  def __init__( self, bucket ):
    # define inputs and outputs
    self.__bucket = bucket
    self.__inputs = ['dtiVolume']
    self.__outputs = ['trkFile']
    # .. call wheel constructor
    pipy.Wheel.__init__( self, bucket, self.__inputs, self.__outputs )

  def spin( self ):
    pipy.Wheel.spin( self )

    print "reading dti Volume " + self.__bucket.get( self.__inputs[0] )

    print ">>> performing connectivity *nom*nom*nom*"

    self.__bucket.put( self.__outputs[0], '/tmp/tracks.trk' )


class RegisterFibers( pipy.Wheel ):

  def __init__( self, bucket ):
    # define inputs and outputs
    self.__bucket = bucket
    self.__inputs = ['trkFile']
    self.__outputs = ['trkFileRegistered']
    # .. call wheel constructor
    pipy.Wheel.__init__( self, bucket, self.__inputs, self.__outputs )

  def spin( self ):
    pipy.Wheel.spin( self )

    print "reading trk File " + self.__bucket.get( self.__inputs[0] )

    print ">>> performing trkFile registration"

    self.__bucket.put( 'aaa', '/tmp/tracksRegistered.trk' )



class FiberProcess( pipy.Wheel ):

  def __init__( self, bucket ):
    # define inputs and outputs
    self.__bucket = bucket
    self.__inputs = ['trkFile', 'trkFileRegistered', 'faVolume', 'adcVolume', 't1Volume', 'type=f1', 'lengthThresholdMin=20', 'lengthThresholdMax=200', 'neighborLevel=2']
    self.__outputs = ['trkFileProcessed']
    # .. call wheel constructor
    pipy.Wheel.__init__( self, bucket, self.__inputs, self.__outputs )

  def spin( self ):
    pipy.Wheel.spin( self )

    print "reading trk File " + self.__bucket.get( self.__inputs[0] )
    print "reading registered trk File " + self.__bucket.get( self.__inputs[1] )
    print "reading fa Volume " + self.__bucket.get( self.__inputs[2] )
    print "reading adc Volume " + self.__bucket.get( self.__inputs[3] )
    print "reading t1 Volume " + self.__bucket.get( self.__inputs[4] )
    print "reading type " + self.__bucket.get( self.__inputs[5] )
    print "reading lengthThresholdMin " + self.__bucket.get( self.__inputs[6] )
    print "reading lengthThresholdMax " + self.__bucket.get( self.__inputs[7] )
    print "reading neighborLevel " + self.__bucket.get( self.__inputs[8] )

    print ">>> performing fiber processing"


def test():

  bucket = pipy.Bucket()
  bucket.put( 'dtiVolume', '/tmp/dtiVol.mgz' )
  bucket.put( 'faVolume', '/tmp/faVol.mgz' )
  bucket.put( 'adcVolume', '/tmp/adcVol.mgz' )
  bucket.put( 't1Volume', '/tmp/t1Vol.mgz' )
  bucket.put( 'type', '300' )

  pipeline = pipy.Pipeline( bucket )
  pipeline.add( Connectivity )
  pipeline.add( RegisterFibers )
  pipeline.add( FiberProcess )
  pipeline.run()


test()
