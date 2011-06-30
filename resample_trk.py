#!/usr/bin/env python
#
#
# NAME
#
#    resample_trk.py
#
# DESCRIPTION
#
#    Change the voxel size and dimensions of a 'trk' file.  This is needed so
#    that the 'trk' files generated with the cmt pipeline can be viewed with
#    the FA_COLOR map in TrackVis.  Unfortunately, TrackVis has a bug where
#    it can't resample the RGB images and I can't find a tool that will do it
#    either, so the easiest thing is just to adjust the voxel size and
#    dimensions of the 'trk' file.  
#
#    Viewing of the FA_COLOR map is needed by our segmenters.
#
# AUTHORS
#
#    Daniel Ginsburg
#    Children's Hospital Boston, 2011

import nibabel
import numpy as np
from optparse import OptionParser

def parseCommandLine():
    """Setup and parse command-line options"""
    
    parser = OptionParser(usage="%prog [options] inputfile.trk outputfile.trk")
    parser.add_option("-v", "--voxelSize",
                      type="float",
                      nargs=3,
                      dest="voxelSize",
                      help="Voxel Size")                  
    (options, args) = parser.parse_args()
    if len(args) != 2:
        parser.error("Wrong number of arguments")
    
    return options,args


def main():

    voxelSize = (2.0, 2.0, 2.0)       
    options,args = parseCommandLine()
    if options.voxelSize != None:
        voxelSize = options.voxelSize
    
    inFileName = args[0]
    outFileName = args[1]

    print ("Loading %s...\n") % (inFileName)
    trk,hdr = nibabel.trackvis.read(inFileName)

    hdr_copy = hdr.copy()
    
    scale = hdr_copy['voxel_size'] / voxelSize
    hdr_copy['voxel_size'] = voxelSize
    hdr_copy['dim'][0] = np.int16(round(np.float(hdr_copy['dim'][0]) * scale[0]))
    hdr_copy['dim'][1] = np.int16(round(np.float(hdr_copy['dim'][1]) * scale[1]))
    hdr_copy['dim'][2] = np.int16(round(np.float(hdr_copy['dim'][2]) * scale[2]))
    nibabel.trackvis.write(outFileName, trk, hdr_copy)
    print ("Wrote %s.\n") % (outFileName)
    
            
if __name__ == '__main__':
    main()    

