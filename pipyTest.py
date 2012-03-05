# pipelines in python ("pipy Wheels") - simple demo
import pipy
from pipyTestWheels import *

def test():

  bucket = pipy.Bucket()
  bucket.put( 'dtiVolume', '/tmp/dtiVol.mgz' )
  bucket.put( 'faVolume', '/tmp/faVol.mgz' )
  bucket.put( 'adcVolume', '/tmp/adcVol.mgz' )
  bucket.put( 't1Volume', '/tmp/t1Vol.mgz' )
  #bucket.put( 'timeout', 1 )
  #bucket.put( 'type', '300' )

  pipeline = pipy.Pipeline( bucket )
  pipeline.add( Connectivity )
  pipeline.add( RegisterFibers )
  pipeline.add( FiberProcess )
  pipeline.add( Connectivity2 )
  pipeline.run()

test()
