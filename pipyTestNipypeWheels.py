import time
import numpy
from wheels import *


class Connectivity( Wheel ):
  _in_ = Enum()
  _out_ = Enum( 'trkFile' )

  def spin():

    print "  CONNECTIVITY1::START"

    print "reading dti Volume "

    print ">>> performing connectivity *nom*nom*nom*"

    import numpy
    a = numpy.zeros( ( 10000, 10000 ) )

    print "  CONNECTIVITY1::END"

    return "thiscouldbeatrkfile"


class Connectivity2( Wheel ):
  _in_ = Enum( 'trkFile', 'timeout' )
  _out_ = Enum( 'trkFile2' )

  def spin( trkFile='aaa', timeout=10 ):

    print "  CONNECTIVITY2::START"

    print "reading dti Volume " + trkFile

    print ">>> performing connectivity *nom*nom*nom*"
    import time
    time.sleep( timeout )

    print "  CONNECTIVITY2::END"

    return 'thiscouldbeatrkfile'


class RegisterFibers( Wheel ):
  _in_ = Enum( 'trkFile' )
  _out_ = Enum( 'trkFileRegistered' )

  def spin( trkFile ):

    print "  REGISTERFIBERS::START"

    print "reading trk File " + trkFile

    print ">>> performing trkFile registration"

    trkFileRegistered = '/tmp/tracksRegistered.trk'

    print "  REGISTERFIBERS::END"

    return trkFileRegistered


class FiberProcess( Wheel ):
  _in_ = Enum( 'trkFile', 'trkFileRegistered', 'faVolume', 'adcVolume', 't1Volume', 'type', 'lengthThresholdMin', 'lengthThresholdMax', 'neighborLevel' )
  _out_ = Enum( 'trkFileProcessed' )

  def spin( trkFile, trkFileRegistered, faVolume='/tmp/faVol.mgz', adcVolume='/tmp/adcVol.mgz', t1Volume='/tmpt1Vol.mgz', type='f1', lengthThresholdMin=20, lengthThresholdMax=200, neighborLevel=2 ):

    print "  FIBERPROCESS::START"

    print "reading trk File " + trkFile
    print "reading registered trk File " + trkFileRegistered
    print "reading fa Volume " + faVolume
    print "reading adc Volume " + adcVolume
    print "reading t1 Volume " + t1Volume
    print "reading type " + type
    print "reading lengthThresholdMin " + str( lengthThresholdMin )
    print "reading lengthThresholdMax " + str( lengthThresholdMax )
    print "reading neighborLevel " + str( neighborLevel )

    print ">>> performing fiber processing"

    print "  FIBERPROCESS::END"

    return "bamm"
