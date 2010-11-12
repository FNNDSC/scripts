#
#
# NAME
#
#    pipeline_status
#
# DESCRIPTION
#
#    This module contain a class for interfacing with a Google Protocol
#    Buffer object that represents the state/status of a pipeline.
#
# AUTHORS
#
#    Daniel Ginsburg
#    Rudolph Pienaar
#    Children's Hospital Boston, 2010
#
import pipeline_pb2
import sys
import os.path as op
import glob

class PipelineStatus():
    """Interface to Pipeline protocol buffer"""
    
    def __init__(self, filename=None):
        """Constructor                
        """
        self.Pipeline = pipeline_pb2.Pipeline()
        if filename != None:
            self.LoadFromFile(filename)
                                        
    def LoadFromFile(self, filename):
        """Save the current state of the pipeline to a file"""
        try:
            f = open(filename, "rb")            
            self.Pipeline.ParseFromString(f.read())
            f.close()
        except:
            print "Could not open file: " + filename
        
    def SaveToFile(self, filename):
        """Load the pipeline state from a file"""
        try:
            f = open(filename, "wb")
            f.write(self.Pipeline.SerializeToString());
            f.close();
        except:
            print "Could not write file: " + filename
            
    def AddStage(self, num, name):
        """Add a new stage to the pipeline.  Returns the new stage"""
        newStage = self.Pipeline.stages.add()
        newStage.num = num;
        newStage.name = name;        
        return newStage;
    
    def GetStage(self, num):
        """Get a stage by number"""
        for stage in self.Pipeline.stages:
            if stage.num == num:
                return stage
    
    def CanRun(self, stage):
        """Checks a stage inputs to determine if the stage can run"""
        for curInput in stage.inputs:        
            filePath = op.join(curInput.rootDir, curInput.filePath)
            matchingFiles = glob.glob(filePath)
            if len(matchingFiles) >= 1:
                if len(matchingFiles) > 1:
                    print "WARNING: more than one file matching " + filePath 
                continue
            elif len(matchingFiles) == 0:
                print "Stage missing input, file not found: " + filePath
                return False
        
        # If we get here, then all files were found    
        return True
    
    def RanOK(self, stage):
        """Determines if all stage outputs were produced"""
        for curOutput in stage.outputs:
            filePath = op.join(curOutput.rootDir, curOutput.filePath)
            matchingFiles = glob.glob(filePath)
            if len(matchingFiles) >= 1:
                if len(matchingFiles) > 1:
                    print "WARNING: more than one file matching " + filePath 
                continue
            elif len(matchingFiles) == 0:
                print "Stage did not complete, file not found: " + filePath
                return False
        
        # If we get here, then all files were found    
        return True
    
    def AddStageInput(self, stage, rootDir, inputFilePath, inputName):
        """Add new input to stage"""
        newInput = stage.inputs.add()
        return self.__AddStageInputOutput(newInput, rootDir, inputFilePath, inputName)
            
    def AddStageOutput(self, stage, rootDir, outputFilePath, outputName):
        """Add new output to stage"""
        newOutput = stage.outputs.add()
        return self.__AddStageInputOutput(newOutput, rootDir, outputFilePath, outputName)                
    
    def AddStageInputFromObject(self, stage, inputOutputObject):
        """Copy input or output as an input to another stage"""
        newInput = stage.inputs.add()
        newInput.filePath = inputOutputObject.filePath;
        newInput.name = inputOutputObject.name;
        newInput.rootDir = inputOutputObject.rootDir
        return newInput
            
    def AddStageOutputFromObject(self, stage, inputOutputObject):
        """Copy input or output as an output from another stage"""
        newOutput = stage.outputs.add()
        newOutput.filePath = inputOutputObject.filePath;
        newOutput.name = inputOutputObject.name;
        newOutput.rootDir = inputOutputObject.rootDir
        return newOutput        
    
    def __AddStageInputOutput(self, inputOutput, rootDir, filePath, name):
        """Used internally for adding stage input/output """
        inputOutput.filePath = filePath
        inputOutput.name = name;
        inputOutput.rootDir = rootDir
        return inputOutput    