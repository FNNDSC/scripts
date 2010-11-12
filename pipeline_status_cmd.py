#!/usr/bin/env python
#
#
# NAME
#
#    pipeline_status_cmd
#
# DESCRIPTION
#
#    This is a wrapper for the pipeline_status Python module to allow
#    querying/setting pipeline state from the command-line.  The '*_meta.bash'
#    framework uses this script to query for and set pipeline state.
#
# EXAMPLES
#
#    1. Create a new pipeline in file 
#
#        pipeline_status_cmd --createPipeline <pipelineName> pipeline.status
#
#    2. Add a stage to a pipeline
#
#        pipeline_status_cmd --addStage <stageName> -stageNumber <stageNumber> pipeline.status
#
#    3. Add an input to a stage
#
#        pipeline_status_cmd --addInput <stageNumber> --rootDir <rootDir> --filePath <filePath> --name <name> pipeline.status
#
#    4. Add an output to a stage
#
#        pipeline_status_cmd --addOutput <stageNumber> --rootDir <rootDir> --filePath <filePath> --name <name> pipeline.status
#
#    5. Query whether a stage can run?
#    
#        pipeline_status_cmd --queryCanRun <stageNum>
#
#    6. Query wherea stage ran?
#
#        pipeline_status_cmd --queryRanOK <stageNum>
#
# AUTHORS
#
#    Daniel Ginsburg
#    Rudolph Pienaar
#    Children's Hospital Boston, 2010
#

import sys
import os.path as op
from optparse import OptionParser
import pipeline.pipeline_status as pipeline_status


def main():
    parser = OptionParser(usage="%prog [options] statusFile")
    parser.add_option("--createPipeline",
                      dest="createPipeline",
                      help="Create a new pipeline with the given name")
    parser.add_option("--queryCanRun",
                      dest="queryCanRun",
                      type="int",
                      help="Query whether a stage's inputs have been created")    
    parser.add_option("--queryRanOK",
                      dest="queryRanOK",
                      type="int",                      
                      help="Query whether a stage ran OK")
    parser.add_option("--addStage",
                      dest="addStage",
                      help="Create a new stage with the given name")
    parser.add_option("--addInput",                      
                      dest="addInput",
                      type="int",                      
                      help="Add input to stage number")
    parser.add_option("--addOutput",
                      dest="addOutput",
                      default=False,
                      type="int",
                      help="Add output to stage number")    
    parser.add_option("--rootDir",
                      dest="rootDir",
                      help="Root directory of stage input/output")
    parser.add_option("--filePath",
                      dest="filePath",
                      help="File path of stage input/output")
    parser.add_option("--name",
                      dest="name",
                      help="Name of stage input/output")
    parser.add_option("--stageNumber",
                      dest="stageNumber",
                      type="int",
                      help="Operate on the provided stage number")
    parser.add_option("-v", "--verbose",
                      action="store_true", dest="verbose")
    (options, args) = parser.parse_args()
    if len(args) != 1:
        parser.error("Wrong number of arguments")
    
    # Create a new pipeline file
    if options.createPipeline:
        if options.verbose:
            print "Creating pipeline: " + options.createPipeline
        
        ps = pipeline_status.PipelineStatus()
        ps.Pipeline.name = options.createPipeline
        
    # Otherwise modify or read existing file
    else:    
        if options.verbose:
            print 'Loading options file: ' + args[0]
    
        # Create the pipeline status object from the file
        ps = pipeline_status.PipelineStatus(args[0])
        
        # Check if stage can run
        if options.queryCanRun:
            stage = ps.GetStage(options.queryCanRun)
            sys.exit(ps.CanRun(stage))
                            
        # Check if stage ran OK                            
        if options.queryRanOK:
            stage = ps.GetStage(options.QueryCanRun)
            sys.exit(ps.RanOK(stage))
            
        # Add a new stage            
        if options.addStage:
            ps.AddStage(options.stageNumber, options.addStage)

        # Add a new stage input
        if options.addInput:
            stage = ps.GetStage(options.addInput)
            ps.AddStageInput(stage, options.rootDir, options.filePath, options.name)

        # Add a new stage output            
        if options.addOutput:
            stage = ps.GetStage(options.addOutput)
            ps.AddStageOutput(stage, options.rootDir, options.filePath, options.name)
            
    if options.verbose:
        print "Saving pipeline file: " + args[0]
    ps.SaveToFile(args[0])        
    
if __name__ == '__main__':
    main()    





