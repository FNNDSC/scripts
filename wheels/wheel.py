import nipype.pipeline.engine as pe
from nipype.interfaces.utility import Function

class Enum( dict ):

  def __init__( self, *sequential ):
    for s in sequential:
      self.__dict__[s] = s

  def keys( self ):
    return self.__dict__.keys()

  def __repr__( self ):
    return self.__dict__.keys()

  def __str__( self ):
    return str( self.__dict__.keys() )


class Singleton( type ):
    def __init__( cls, name, bases, dict ):
        super( Singleton, cls ).__init__( name, bases, dict )
        cls.instance = None

    def __call__( cls, *args, **kw ):
        if cls.instance is None:
            cls.instance = super( Singleton, cls ).__call__( *args, **kw )
        return cls.instance


class Wheel( pe.Node ):
  _in_ = Enum()
  _out_ = Enum()
  __metaclass__ = Singleton

  def __init__( self ):
    '''
    '''
    super( Wheel, self ).__init__( name=str( self.__class__.__name__.replace( '.', '_' ) ), interface=Function( function=self.spin, input_names=self._in_.keys(), output_names=self._out_.keys() ) )

  def spin():
    pass
