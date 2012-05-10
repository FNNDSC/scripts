#!/usr/bin/env python
import os
import sys
import fyborg

def run( trkFile, outputFile ):

  fyborg.clearScalars( trkFile, outputFile )


# ENTRYPOINT
if __name__ == "__main__":

  print 'Clear all existing scalars of a .trk file.'

  if len( sys.argv ) == 1:
    print 'fibmapClearScalars.py TRKFILE OUTPUTFILE'
    sys.exit()

  trkFile = sys.argv[1]
  outputFile = sys.argv[2]

  run( trkFile, outputFile )
