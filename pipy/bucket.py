import copy
import os
import cPickle as pickle

class Bucket:

  def __init__( self, directory ):

    if not directory or not os.path.isdir( directory ):
      raise Exception( "Could not find bucket directory!" )

    self.__directory = directory

  def put( self, key, value ):

    filename = os.path.join( self.__directory, key, '._pipy' )

    lock = FileLock( filename )
    with lock:
      # the file is locked
      # .. write the value
      with open( filename, 'wb' ) as f:
        pickle.dump( value, f )

  def get( self, key ):

    value = None

    # remove default values
    key = key.split( '=' )[0]

    filename = os.path.join( self.__directory, key, '._pipy' )

    if not os.path.isfile( filename ):
      # value is not in bucket
      return None

    lock = FileLock( filename )
    with lock:
      # the file is locked
      # .. read the value
      with open( filename, 'rb' ) as f:
        value = pickle.load( filename )

    return value

  def check( self, keys ):
    '''
    Check if a bunch of keys are in the bucket and accessible.
    '''
    for k in keys:

      filename = os.path.join( self.__directory, k, '._pipy' )
      if os.path.isfile( filename ):
        lock = FileLock( filename )
        if lock.is_locked():
          # at least one key is not accessible
          return False
      else:
        # at least one key is not in bucket
        return False

    return True
