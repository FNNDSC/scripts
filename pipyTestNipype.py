import wheels
from pipyTestNipypeWheels import *

def test():

  p = Pype()
  p.add( Connectivity )
  p.add( RegisterFibers )
  p.add( FiberProcess )
  p.add( Connectivity2 )
  p.run()

test()
