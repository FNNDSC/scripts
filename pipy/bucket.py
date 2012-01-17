import copy

class Bucket:

  def __init__( self, bucket={} ):
    self.__bucket = bucket

  def put( self, key, value ):
    self.__bucket[key] = value

  def get( self, key ):
    # remove default values
    key = key.split( '=' )[0]

    if self.__bucket.has_key( key ):
      return self.__bucket[key]
    else:
      return None

  def content( self ):
    return copy.deepcopy( self.__bucket )

