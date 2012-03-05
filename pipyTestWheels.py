import pipy
import time
import numpy

class Connectivity( pipy.Wheel ):

  @staticmethod
  def inputs():
    return ['dtiVolume']

  @staticmethod
  def outputs():
    return ['trkFile']

  @staticmethod
  def spin( BUCKET ):

    print "  CONNECTIVITY1::START"

    print "reading dti Volume " + BUCKET.get( Connectivity.inputs()[0] )

    print ">>> performing connectivity *nom*nom*nom*"

    a = numpy.zeros( ( 1000, 1000 ) )

    BUCKET.put( Connectivity.outputs()[0], a )

    print "  CONNECTIVITY1::END"

class Connectivity2( pipy.Wheel ):

  @staticmethod
  def inputs():
    return ['dtiVolume', 'timeout=10']

  @staticmethod
  def outputs():
    return ['trkFile2']

  @staticmethod
  def spin( BUCKET ):

    print "  CONNECTIVITY2::START"

    print "reading dti Volume " + BUCKET.get( Connectivity2.inputs()[0] )

    print ">>> performing connectivity *nom*nom*nom*"
    time.sleep( int( BUCKET.get( Connectivity2.inputs()[1] ) ) )

    BUCKET.put( Connectivity2.outputs()[0], '/tmp/tracks.trk' )

    print "  CONNECTIVITY2::END"


class RegisterFibers( pipy.Wheel ):

  @staticmethod
  def inputs():
    return ['trkFile']

  @staticmethod
  def outputs():
    return ['trkFileRegistered']

  @staticmethod
  def spin( BUCKET ):

    print "  REGISTERFIBERS::START"

    print "reading trk File " + str( BUCKET.get( RegisterFibers.inputs()[0] ) )

    print ">>> performing trkFile registration"

    BUCKET.put( RegisterFibers.outputs()[0], '/tmp/tracksRegistered.trk' )

    print "  REGISTERFIBERS::END"


class FiberProcess( pipy.Wheel ):

  @staticmethod
  def inputs():
    return ['trkFile', 'trkFileRegistered', 'faVolume', 'adcVolume', 't1Volume', 'type=f1', 'lengthThresholdMin=20', 'lengthThresholdMax=200', 'neighborLevel=2']

  @staticmethod
  def outputs():
    return ['trkFileProcessed']

  @staticmethod
  def spin( BUCKET ):

    print "  FIBERPROCESS::START"

    print "reading trk File " + str( BUCKET.get( FiberProcess.inputs()[0] ) )
    print "reading registered trk File " + BUCKET.get( FiberProcess.inputs()[1] )
    print "reading fa Volume " + BUCKET.get( FiberProcess.inputs()[2] )
    print "reading adc Volume " + BUCKET.get( FiberProcess.inputs()[3] )
    print "reading t1 Volume " + BUCKET.get( FiberProcess.inputs()[4] )
    print "reading type " + BUCKET.get( FiberProcess.inputs()[5] )
    print "reading lengthThresholdMin " + BUCKET.get( FiberProcess.inputs()[6] )
    print "reading lengthThresholdMax " + BUCKET.get( FiberProcess.inputs()[7] )
    print "reading neighborLevel " + BUCKET.get( FiberProcess.inputs()[8] )

    print ">>> performing fiber processing"

    print "  FIBERPROCESS::END"

