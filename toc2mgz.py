#!/usr/bin/env python
import os
import sys

class TocParserLogic():

  def __init__( self ):
    '''
    '''
    pass

  def run( self, fileName ):
    '''
    '''

    # create output folder
    os.mkdir( 'mgz_export' )

    with open( fileName, 'r' ) as f:

      data = f.readlines()


      for l in data:

        l_without_spaces = l.strip()
        l_array = l_without_spaces.split( '\t' )

        # l_array will have two elements, like this: 
        # ['Scan 777000-000007-000001.dcm', 'PCASL (DO NOT NEED XTRA SLICES/NO NEED TO SCAN BELOW EYELINE)']
        fileNameSplitted = l_array[0].split( ' ' )

        if fileNameSplitted[0] == "Scan":

          outputFile = l_array[1].split( ' ' )[0] + '-' + os.path.splitext( fileNameSplitted[1] )[0]

          print "Converting " + fileNameSplitted[1] + ' to ' + outputFile + '.mgz'
          print os.system( "mri_convert " + fileNameSplitted[1] + ' mgz_export/' + outputFile + '.mgz' )


    print "All done."




def print_help( scriptName ):
  '''
  '''
  description = 'Parse a toc.txt file and create .mgz files for each series in a sub-folder mgz_export/.'
  print description
  print
  print 'Usage: python ' + scriptName
  print


#
# entry point
#
if __name__ == "__main__":

  # always show the help if no arguments were specified
  if len( sys.argv ) != 1:
    print_help( sys.argv[0] )
    sys.exit( 1 )

  logic = TocParserLogic()
  logic.run( 'toc.txt' )

