#!/usr/bin/env python
import os
import sys
import fyborg

def run(trkFile, outputDir):

  # create output directory
  os.mkdir( outputDir )

  fyborg.makeMatrix(trkFile, outputDir)


# ENTRYPOINT
if __name__ == "__main__":

  print 'Make Connectivity Matrix of FIBMAP output'

  if len(sys.argv) == 1:
    print 'fibmapCMatrix.py TRKFILE OUTPUTDIR'
    sys.exit()

  trkFile = sys.argv[1]
  outputDir = sys.argv[2]

  run(trkFile, outputDir)
  