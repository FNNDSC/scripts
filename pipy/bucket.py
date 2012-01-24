import copy
import os
import cPickle as pickle
import tempfile
from lockfile import FileLock

class Bucket:

  def __init__( self ):
    self.__directory = tempfile.mkdtemp( suffix='BUCKET', prefix='pipy' )

  def put( self, key, value ):

    #print "PUT: " + str( key ) + ', ' + str( value )

    filename = os.path.join( self.__directory, key + '._pipy' )

    lock = FileLock( filename )
    with lock:
      # the file is locked
      # .. write the value
      with open( filename, 'wb' ) as f:
        pickle.dump( value, f )

  def get( self, key ):

    #print "GET: " + str( key )

    value = None

    # split on default values
    k = key.split( '=' )

    filename = os.path.join( self.__directory, k[0] + '._pipy' )

    if not os.path.isfile( filename ):
      # value is not in bucket
      # check if there is a default value
      if len( k ) > 1:
        return k[1]
      return None

    lock = FileLock( filename )
    with lock:
      # the file is locked
      # .. read the value
      with open( filename, 'rb' ) as f:
        value = pickle.load( f )

    return value

  def check( self, keys ):
    '''
    Check if a bunch of keys are in the bucket and accessible.
    '''
    for k in keys:

      # split on default values
      k = k.split( '=' )

      # check if we have a default value, then we can
      # skip the check because we will always be able to
      # get a value for this key from the bucket
      if len( k ) > 1:
        continue

      filename = os.path.join( self.__directory, k[0] + '._pipy' )
      if os.path.isfile( filename ):
        lock = FileLock( filename )
        if lock.is_locked():
          # at least one key is not accessible
          return False
      else:
        # at least one key is not in bucket
        return False

    return True
