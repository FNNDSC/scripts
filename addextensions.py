#!/usr/bin/env python
import os
import sys

def print_help( scriptName ):
  '''
  '''
  description = 'Add an extension to all files in a directory tree which do not have an extension yet.'
  print description
  print
  print 'Usage: python ' + scriptName + ' DIRECTORY EXTENSION'
  print


#
# entry point
#
if __name__ == "__main__":

  # always show the help if no arguments were specified
  if len( sys.argv ) < 3:
    print_help( sys.argv[0] )
    sys.exit( 1 )

  directory = sys.argv[1]
  newExtension = sys.argv[2]
  if not newExtension[0] == '.':
    newExtension = '.' + newExtension

  for root, dirnames, filenames in os.walk( directory ):
    for filename in filenames:
      extension = os.path.splitext( filename )[1]

      # only use filenames without an extension
      if extension:
        continue

      newFilename = filename + newExtension

      fullpath = os.path.join( root, filename )
      newFullpath = os.path.join( root, newFilename )

      print fullpath + " -> " + newFullpath
      os.rename( fullpath, newFullpath )
