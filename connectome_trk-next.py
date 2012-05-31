#!/usr/bin/env python
#
#
# NAME
#
#    connectome_trk.py
#
# DESCRIPTION
#
#    This is a wrapper for the Connectome Mapping Toolkit such that
#    it can be executed from the CHB web front-end.
#    
#    Debug test version
#
# AUTHORS
#
#    Daniel Ginsburg
#    Rudolph Pienaar
#    Children's Hospital Boston, 2010
#
# HISTORY
# 17 August 2011
# o Added '--notalairach' flag and handling.
#

import cmp,cmp.connectome,cmp.gui,cmp.configuration,cmp.pipeline,cmp.logme
import sys
import os
import shutil, glob
from optparse import OptionParser

def parseCommandLine(conf):
    """Setup and parse command-line options"""
    
    parser = OptionParser(usage="%prog [options]")
    parser.add_option("-p", "--projectName",
                      dest="projectName",
                      help="Project name")
    parser.add_option("-v", "--verbose",
                      action="store_true", dest="verbose")
    parser.add_option("-d","--workingDir",
                      dest="workingDir",
                      help="Subject Working Directory")
    parser.add_option("--b0",
                      dest="b0",
                      type="string",
                      help="Number of B0 volumes")
    parser.add_option("--bValue",
                      dest="bValue",
                      type="string",
                      help="B Value")
    parser.add_option("--gm",
                      dest="gradientMatrix",                      
                      help="Gradient file")
    parser.add_option("--dtiDir",
                      dest="dtiDir",
                      help="DTI DICOM Input directory")
    parser.add_option("--t1Dir",
                      dest="t1Dir",
                      help="T1 DICOM Input directory")
    parser.add_option("--skipCompletedStages",
                      dest="skipCompletedStages",
                      action="store_true",
                      help="Skip previously completed stages.")
    parser.add_option("--notalairach",
                      dest="notalairach",
                      action="store_true",
                      help="Do not perform talairach registration.")
    parser.add_option("--writePickle",
                      dest="writePickle",
                      help="Filename to write pickle for use with CMT GUI. Exit after writing pickle file.")
    (options, args) = parser.parse_args()
    if len(args) != 0:
        parser.error("Wrong number of arguments")
    
    # Parse command-line options        
    if options.workingDir == None:
        parser.error('You must specify --workingDir')
    else:
        conf.project_dir = os.path.dirname(options.workingDir)
        conf.subject_workingdir = options.workingDir
        conf.subject_name = os.path.basename(options.workingDir) 
                
    if options.projectName:
        conf.project_name = options.projectName
    else:
        conf.project_name = 'connectome_web'
        
    if options.gradientMatrix:
        conf.gradient_table_file = options.gradientMatrix
        conf.gradient_table = 'custom'
        
    if options.b0:
        conf.nr_of_b0 = options.b0
        
    if options.bValue:
        conf.max_b0_val = options.bValue

    if options.skipCompletedStages:
        conf.skip_completed_stages = True

    # This must be the last step, write the configuration object
    # out to a pickle file for use in the CMT GUI
    if options.writePickle:
        conf.save_state(os.path.abspath(options.writePickle))

    return options
    
def prepForExecution(conf, options):
    """Prepare the files for execution of the cmp pipeline"""
    """We need to copy the MRIs at the good location"""
    
    # Must specify the T1 and DTI input directories
    if options.t1Dir == None:
        sys.exit('You must specify --t1Dir')

    if options.dtiDir == None:
        sys.exit('You must specify --dtiDir')        
   
    # might need subject working dir?
    # T2 and fMRI supported?
    
    # Create RAWDATA dirs and copy data inside!
    if not os.path.exists(conf.subject_workingdir + os.sep + 'RAWDATA'):
        os.makedirs(conf.subject_workingdir + os.sep + 'RAWDATA')

    # Create RAWDATA dirs and copy data inside!
    if not os.path.exists(conf.subject_workingdir + os.sep + 'RAWDATA' + os.sep + 'DTI'):
        os.makedirs(conf.subject_workingdir + os.sep + 'RAWDATA' + os.sep + 'DTI')
    
    # Create RAWDATA dirs and copy data inside!
    if not os.path.exists(conf.subject_workingdir + os.sep + 'RAWDATA' + os.sep + 'T1'):
        os.makedirs(conf.subject_workingdir + os.sep + 'RAWDATA' + os.sep + 'T1')
   
    # Copy the DICOM's
    for file in glob.glob(os.path.join(options.t1Dir + os.sep + "*.dcm")):
        print file
        shutil.copy(file, conf.subject_workingdir + os.sep + 'RAWDATA' + os.sep + 'T1')
                
    for file in glob.glob(os.path.join(options.dtiDir + os.sep + "*.dcm")):
       
        shutil.copy(file, conf.subject_workingdir + os.sep + 'RAWDATA' + os.sep + 'DTI')
        
def main():
    """Main entrypoint for program"""
    
    # Create configuration object (the GUI object
    # is subclassed from PipelineConfiguration and
    # we use this so we can serialize it as a pickle
    # if we want to)
    conf = cmp.gui.CMPGUI()
    
    # Default Options
    conf.freesurfer_home = os.environ['FREESURFER_HOME']
    conf.fsl_home = os.environ['FSLDIR']
    conf.dtk_matrices = os.environ['DSI_PATH']
    conf.dtk_home = os.path.dirname(conf.dtk_matrices) # DTK home is one up from the matrices 
    conf.subject_raw_glob_diffusion = '*.dcm'
    conf.subject_raw_glob_T1 = '*.dcm'
    conf.subject_raw_glob_T2 = '*.dcm'
    conf.do_convert_T2 = False
    
    conf.diffusion_imaging_model = "DTI"
    conf.streamline_param = ''

    # Enable all stages
    conf.active_dicomconverter = True
    conf.active_registration = True
    conf.active_segmentation = True
    conf.active_parcellation = True
    conf.active_applyregistration = True
    conf.active_reconstruction = True
    conf.active_tractography = True
    conf.active_fiberfilter = True
    conf.active_connectome = True
    conf.active_statistics = True
    conf.active_cffconverter = True
    conf.skip_completed_stages = True
    
    print 'Parse command line'    

    # Setup and parse command-line options
    options = parseCommandLine(conf)
    
    print 'Command line parsed'    

    # XXX: These are hardcoded for now until I figure out how they
    #      should be set
    conf.creator = 'Neuroimaging Web Pipeline'
    conf.publisher = 'CHB'
    conf.legalnotice = 'institution-specific'
    conf.email = 'default@default.edu'
    if options.notalairach:
        conf.recon_all_param = '-all -no-isrunning -notalairach'

    #print conf.recon_all_param
    
    # If writing pickle, return
    if options.writePickle:
        return

    # Prepare the directory structure for execution
    prepForExecution(conf, options)

    print 'Start the cmp pipeline'        
    # Execute the 'cmp' pipeline!
    cmp.connectome.mapit(conf)
        
if __name__ == '__main__':
    main()    


    



