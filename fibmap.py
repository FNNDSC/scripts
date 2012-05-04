#!/usr/bin/env python
import sys
import os
from _common import FNNDSCUtil as u
from _common import FNNDSCConsole as c
from _common import FNNDSCFileIO as io
from _common import FNNDSCParser
from wheels import *

class FibMapLogic():

  def __init__( self ):
    '''
    '''

  def run( self, directory, output ):
    '''
    '''

    cmtDirectory = directory + os.sep + '3-cmt' + os.sep
    output += os.sep

    if not os.path.isdir( directory ) or not os.path.isdir( cmtDirectory ):
      c.error( 'The given directory is not valid or does not include a 3-cmt/ sub-folder.' )
      sys.exit( 2 )

    # create output directory
    os.mkdir( output )

    # create the Pype
    Preprocessing._in_.cmtDirectory = cmtDirectory
    Preprocessing._in_.outputDirectory = output
    MapADCandFAvalues._in_.cmtDirectory = cmtDirectory
    MapADCandFAvalues._in_.outputDirectory = output
    CopyScalars._in_.cmtDirectory = cmtDirectory
    CopyScalars._in_.outputDirectory = output
    FilterLengthFilterCortexMapLabelsWithRadius._in_.cmtDirectory = cmtDirectory
    FilterLengthFilterCortexMapLabelsWithRadius._in_.outputDirectory = output

    p = Pype()
    p.add( Preprocessing )
    p.add( MapADCandFAvalues )
    p.add( CopyScalars )
    p.add( FilterLengthFilterCortexMapLabelsWithRadius )
    p.run( False )


    c.info( '' )
    c.info( 'ALL DONE! SAYONARA..' )


#
# SPIN THA WHEELZ!!!
#
class Preprocessing( Wheel ):
  _in_ = Enum( 'cmtDirectory', 'outputDirectory' )
  _out_ = Enum( 'inputTrkFile1' )

  def spin( cmtDirectory, outputDirectory ):

    import os

    freesurferFolder = str( cmtDirectory ) + os.sep + 'FREESURFER' + os.sep
    freesurferMRIfolder = freesurferFolder + 'mri' + os.sep
    freesurferSURFfolder = freesurferFolder + 'surf' + os.sep
    dtiB0file = str( cmtDirectory ) + os.sep + 'CMP/raw_diffusion/dti_0/dti_b0.nii'
    trkFile = str( cmtDirectory ) + os.sep + 'CMP/fibers/streamline.trk'
    trkFileToT1 = outputDirectory + os.path.splitext( os.path.split( trkFile )[1] )[0] + '-to-T1.trk'
    T1niiFile = outputDirectory + 'T1.nii'
    SegmentationNiiGzFile = freesurferMRIfolder + 'aparc+aseg.nii.gz'
    SegmentationNiiFile = outputDirectory + 'aparc+aseg.nii'
    T1toB0matFile = outputDirectory + 'T1-to-b0.mat'
    identityXFM = outputDirectory + 'identity.xfm'

    cmd = 'ss;'
    cmd += 'chb-fsdev;'
    cmd += 'mri_convert ' + freesurferMRIfolder + 'T1.mgz ' + T1niiFile + ';'
    cmd += 'gzip -cd ' + SegmentationNiiGzFile + ' > ' + SegmentationNiiFile + ';'
    cmd += 'flirt -in ' + T1niiFile + ' -ref ' + dtiB0file + ' -usesqform -nosearch -dof 6 -cost mutualinfo -omat ' + T1toB0matFile + ';'
    cmd += 'track_transform ' + trkFile + ' ' + trkFileToT1 + ' -src ' + dtiB0file + ' -ref ' + T1niiFile + ' -reg ' + T1toB0matFile + ' -invert_reg' + ';'

    # write the identity XFM matrix
    with open( identityXFM, 'w' ) as f:
      f.write( "MNI Transform File\n% tkregister2\n\nTransform_Type = Linear;\nLinear_Transform =\n 1.00000000   -0.00000000   -0.00000000    0.00000000\n  0.00000000    1.00000000    0.00000000    0.00000000 \n 0.00000000   -0.00000000    1.00000000    0.00000000 ;\n" )


    cmd += 'mris_transform ' + freesurferSURFfolder + 'lh.smoothwm ' + identityXFM + ' ' + outputDirectory + 'lh.smoothwm.nover2ras' + ';'
    cmd += 'mris_transform ' + freesurferSURFfolder + 'rh.smoothwm ' + identityXFM + ' ' + outputDirectory + 'rh.smoothwm.nover2ras' + ';'

    import subprocess
    sp = subprocess.Popen( ["/bin/bash", "-i", "-c", cmd] )
    sp.communicate()

    return trkFile

class MapADCandFAvalues( Wheel ):
  _in_ = Enum( 'cmtDirectory', 'outputDirectory', 'inputTrkFile1' )
  _out_ = Enum( 'inputTrkFile2' )

  def spin( cmtDirectory, outputDirectory, inputTrkFile1 ):

    import fyborg
    import os

    dtiFAfile = str( cmtDirectory ) + os.sep + 'CMP/raw_diffusion/dti_0/dti_fa.nii'
    dtiADCfile = str( cmtDirectory ) + os.sep + 'CMP/raw_diffusion/dti_0/dti_adc.nii'
    outputTrkFile = outputDirectory + 'streamline-mapped-adc-fa.trk'

    actions = []
    actions.append( fyborg.FyMapAction( 'adc', dtiADCfile ) )
    actions.append( fyborg.FyMapAction( 'fa', dtiFAfile ) )
    fyborg.fyborg( inputTrkFile1, outputTrkFile, actions )

    return outputTrkFile

class CopyScalars( Wheel ):
  _in_ = Enum( 'cmtDirectory', 'outputDirectory', 'inputTrkFile2' )
  _out_ = Enum( 'inputTrkFile3' )

  def spin( cmtDirectory, outputDirectory, inputTrkFile2 ):

    import fyborg
    import os

    trkFileToT1 = outputDirectory + 'streamline-to-T1.trk'
    finalFibmapTrk = outputDirectory + 'final-fibmap-streamline.trk'

    # copy scalars from input trk to trkFileToT1 and save as finalFibmapTrk
    fyborg.copyScalars( inputTrkFile2, trkFileToT1, finalFibmapTrk )

    return finalFibmapTrk

class FilterLengthFilterCortexMapLabelsWithRadius( Wheel ):
  _in_ = Enum( 'cmtDirectory', 'outputDirectory', 'inputTrkFile3' )
  _out_ = Enum( 'allDone' )

  def spin( cmtDirectory, outputDirectory, inputTrkFile3 ):

    import fyborg
    import os

    freesurferFolder = str( cmtDirectory ) + os.sep + 'FREESURFER' + os.sep
    freesurferMRIfolder = freesurferFolder + 'mri' + os.sep
    freesurferSegmentation = outputDirectory + 'aparc+aseg.nii'

    actions = []
    actions.append( fyborg.FyFilterLengthAction( 20, 200 ) )
    actions.append( fyborg.FyFilterCortexAction( freesurferSegmentation ) )
    actions.append( fyborg.FyLabelMappingWithRadiusAction( 'aparc_aseg_endlabel', freesurferSegmentation, 3 ) )
    fyborg.fyborg( inputTrkFile3, inputTrkFile3, actions )

    return True


#
# entry point
#
if __name__ == "__main__":
  parser = FNNDSCParser( description='Fancy Fiber Scalar Mapping using Kiho\'s method on top of the Connectome pipeline.\n\nA patient directory with a 3-cmt/ sub-folder is passed and analyzed.' )

  parser.add_argument( 'directory', type=str, help='The patient directory which contains the 3-cmt/ sub-folder.' )
  parser.add_argument( 'outputDirectory', type=str, help='The output directory.' )

#
#  parser.add_argument( '-i', '--input', action='append', dest='input', required=True, help='input trackvis files, f.e. -i ~/files/f01.trk -i ~/files/f02.trk -i ~/files/f03.trk ..' )
#  parser.add_argument( '-o', '--output', action='store', dest='output', required=True, help='output trackvis file, f.e. -o /tmp/f_out.trk' )
#  parser.add_argument( '-j', '--jobs', action='store', dest='jobs', default=multiprocessing.cpu_count(), help='number of parallel computations, f.e. -j 10' )
#  parser.add_argument( '-v', '--verbose', action='store_true', dest='verbose', help='show verbose output' )
#  parser.add_argument( 'mode', choices=['add', 'sub'], help='ADD all input tracks to one file or SUBTRACT all other input tracks from the first specified input' )

  # always show the help if no arguments were specified
  if len( sys.argv ) == 1:
    parser.print_help()
    sys.exit( 1 )

  options = parser.parse_args()

  logic = FibMapLogic()
  logic.run( options.directory, options.outputDirectory )
