#!/usr/bin/env python

Gstr_synopsis = """

NAME

    cmp_trk_reprocess.py

SYNPOSIS

    cmp_trk_reprocess.py --trk <a_trkFile>

ARGS

    a_trkFile           trk format file to reprocess in the
                        connectivity pipeline.

DESCRIPTION

    'cmp_trk_reprocess.py' re-runs an already completed
    connectivity analysis using the passed <a_trkFile> to
    process connectivity.

    It assumes by design that the FreeSurfer recon has been
    completed, and merely runs the final stages of the pipeline
    generating a new connectome pickle object.

    New cff files are created and renamed explicitly to match
    the <a_trkFile> name.

AUTHORS

   Rudolph Pienaar
   Children's Hospital Boston, 2011

HISTORY
03 November 2011
o Initial design and coding based off 'connectome_web.py'

"""

import cmp,cmp.connectome,cmp.gui,cmp.configuration,cmp.pipeline,cmp.logme
import sys
import os
import shutil, glob
from optparse import OptionParser
import systemMisc as sM

def parseCommandLine(conf):
    """Setup and parse command-line options"""
    
    parser = OptionParser(usage="%prog [options]")
    parser.add_option("-p", "--projectName",
                      dest="projectName",
                      help="Project name")
    parser.add_option("-v", "--verbose",
                      action="store_true", dest="verbose")
    parser.add_option("-t", "--trkFile",
                      dest="trkFile",
                      help="t file")
    parser.add_option("--skipCompletedStages",
                      dest="skipCompletedStages",
                      action="store_true",
                      help="Skip previously completed stages.")
    parser.add_option("--writePickle",
                      dest="writePickle",
                      help="Filename to write pickle for use with CMT GUI. Exit after writing pickle file.")
    (options, args) = parser.parse_args()
    if len(args) != 0:
        parser.error("Wrong number of arguments")
    
    # Parse command-line options        
    if options.trkFile == None:
        parser.error('You must specify a "--trkFile"')
                
    if options.projectName:
        conf.project_name = options.projectName
    else:
        conf.project_name = 'cmt_trk_reprocess'
        

    if options.skipCompletedStages:
        conf.skip_completed_stages = True

    # This must be the last step, write the configuration object
    # out to a pickle file for use in the CMT GUI
    if options.writePickle:
        conf.save_state(os.path.abspath(options.writePickle))

    return options
    
def prepForExecution(conf, options):
    """Prepare the files for execution of the cmp pipeline"""
    
        
    # First, setup the pipeline status so we can determine the inputs
    cmp.connectome.setup_pipeline_status(conf)
        
        
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

    # Only execute the final connectome stages
    conf.active_dicomconverter = False
    conf.active_registration = False
    conf.active_segmentation = False
    conf.active_parcellation = False
    conf.active_applyregistration = False
    conf.active_reconstruction = False
    conf.active_tractography = False
    conf.active_fiberfilter = False
    conf.active_connectome = True
    conf.active_statistics = True
    conf.active_cffconverter = True
    conf.skip_completed_stages = False
    
    # Setup and parse command-line options
    options = parseCommandLine(conf)

    # XXX: These are hardcoded for now until I figure out how they
    #      should be set
    conf.creator = 'Neuroimaging Web Pipeline'
    conf.publisher = 'CHB'
    conf.legalnotice = 'institution-specific'
    conf.email = 'default@default.edu'
    
    # If writing pickle, return
    if options.writePickle:
        return

    # Prepare the directory structure for execution
    prepForExecution(conf, options)
    
    # Before running, reset the pipeline status because it will 
    # get created in mapit()
    conf.pipeline_status = cmp.pipeline_status.PipelineStatus()

    # Execute the 'cmp' pipeline!
    print "About to execute!"
    cmp.connectome.mapit(conf)
        
if __name__ == '__main__':
    main()    





