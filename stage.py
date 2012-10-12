#!/usr/bin/env python

import sys
import types

from    _common         import crun
from    _common._colors import Colors
from    _common         import systemMisc       as misc

import  message
import  inspect

import  error

class Pipeline:
    '''
    A thin wrapper that essentially strings several stages together
    in a pipeline, using the venerable python list as organizing container.
    The main advantage to using a pipeline as stage container is the
    simplification afforded to running stages selectively.
    '''

    _dictErr = {
        'preconditions'     : {
            'action'        : 'executing preconditions, ',
            'error'         : 'a failure state was detected.',
            'exitCode'      : 10},
        'postconditions'    : {
            'action'        : 'executing postconditions, ',
            'error'         : 'a failure state was detected.',
            'exitCode'      : 11},
        'stageNotFound'     : {
            'action'        : 'searching for a stage in the pipeline, ',
            'error'         : 'the stage was not found!',
            'exitCode'      : 12}
    }

    
    def pipeline(self):
        '''
        Get the pipeline.
        '''
        return self._pipeline

        
    def log(self):
        '''
        Returns the internal pipeline log message object. Caller can further 
        manipulate the log object with object-specific calls.
        '''
        return self._log


    def name(self, *args):
        '''
        get/set the descriptive name text of this stage object.
        '''
        if len(args):
            self.__name = args[0]
        else:
            return self.__name
        
        
    def __init__(self):
        '''
        Constructor
        '''
        self.__name             = 'unnamed'
        self._log               = message.Message()
        self._pipeline          = []


    def stage_add(self, element):
        '''
        Add a stage to the pipeline.
        '''
        self._pipeline.append(element)


    def stage_get(self, index):
        '''
        Return the stage referenced by <index>.

        The <index> can be specified in several ways:

        o an integer offset into the pipeline list.
        o a string "name" of a particular stage.
        
        '''
        if type(index) is types.IntType:
            return self._pipeline[index]
        if type(index) is types.StringType:
            for stage in self._pipeline:
                if stage.name() == index:
                    return stage
                

    def pop(self):
        '''
        Pop a stage from the pipeline stack.
        '''
        ret = self._pipeline.pop()
        return ret

        
    def execute(self):
        '''
        Run the pipeline, stage by stage.
        '''
        for stage in self._pipeline:
            stage()
        


class Stage:
    '''
    A simple 'stage' class used for constructing serialized pipeline
    processing streams.
    
    '''

    #
    # Class member variables -- if declared here are shared
    # across all instances of this class
    #
    _dictErr = {
        'preconditions'     : {
            'action'        : 'executing preconditions, ',
            'error'         : 'a failure state was detected.',
            'exitCode'      : 10},
        'postconditions'    : {
            'action'        : 'executing postconditions, ',
            'error'         : 'a failure state was detected.',
            'exitCode'      : 11},
        'NoCmd'             : {
            'action'        : 'executing a stage shell command, ',
            'error'         : 'no shell command has been specified.',
            'exitCode'      : 12}
    }

    
    def vprint(self, alevel, astr_msg):
        '''
        A verbosity-aware print.

        '''
        if self._verbosity and self._verbosity <= alevel:
            sys.stdout.write(astr_msg)
        

    def name(self, *args):
        '''
        get/set the descriptive name text of this stage object. 
        '''
        if len(args):
            self.__name = args[0]
        else:
            return self.__name

            
    def __init__(self, **kwargs):
        '''
        The base constructor for the 'Stage' class.

        By default, the internal callback functions,

            self._f_preconditions and self._f_postconditions

        are assigned to lambda functions always returning True. These callbacks
        can be typically re-assigned using the

            self.def_preconditions() and self.def_postconditions()

        class methods.

        '''

        self.__name             = 'Stage'
        self._log               = message.Message()

        self._b_fatalConditions = True

        self._verbosity         = 1

        self._str_cmd           = ''
        
        self._f_preconditions           = lambda x: True
        self._f_preconditionsArgs       = None
        self._f_postconditions          = lambda x: True
        self._f_postconditionsArgs      = None

        
    def def_preconditions(self, *args, **kwargs):
        '''
        get/set the 'preconditions' function

        This method assigns the internal 'preconditions' evaluator to
        args[0], and passes the optional named keyword arguments to
        this external function.

        If stage preconditions are to be set to a previous stage's
        postconditions, the assignment syntax would be:

            thisStage.def_preconditions(prevStage.def_postconditions()[0],
                                        **prevStage.def_postconditions()[1])

        '''
        if len(args):
            self._f_preconditions       = args[0]
            self._f_preconditionsArgs   = kwargs
        else:
            return self._f_preconditions, self._f_preconditionsArgs


    def def_postconditions(self, *args, **kwargs):
        '''
        set the 'postconditions' function

        This method assigns the internal 'postconditions' evaluator to
        args[0], and passes the optional named keyword arguments to
        this external function.

        If stage postconditions are to be set to a previous stage's
        preconditions, the assignment syntax would be:

            thisStage.def_postconditions(prevStage.def_preconditions()[0],
                                        **prevStage.def_preconditions()[1])

        '''
        if len(args):
            self._f_postconditions      = args[0]
            self._f_postconditionsArgs  = kwargs
        else:
            return self._f_postconditions, self._f_postconditionsArgs
        
        
    def preconditions(self):
        '''
        Evaluates the internal preconditions callback, and returns
        a boolean result.
        
        '''
        self._log('Checking preconditions...\n')
        ret = self._f_preconditions(**self._f_preconditionsArgs)
        return ret

        
    def __call__(self, **kwargs):
        '''
        The base class __call__ functor essentially only dispatches the
        pre- and/or post-conditions checking.

        '''
        for key, value in kwargs.iteritems():
            if key == 'checkpreconditions':
                if self.preconditions():
                    return True
                else:
                    if self._b_fatalConditions:
                        error.fatal(self, 'preconditions')
                    else:
                        error.warn(self, 'preconditions')
            if key == 'checkpostconditions':
                if self.postconditions():
                    return True
                else:
                    if self._b_fatalConditions:
                        error.fatal(self, 'postconditions')
                    else:
                        error.warn(self, 'postconditions')
                        

    def postconditions(self):
        '''
        Evaluates the internal postconditions callback, and returns
        a boolean result.

        '''
        self._log('Checking postconditions...\n')
        ret = self._f_postconditions(**self._f_postconditionsArgs)
        return ret

        
    def log(self):
        '''
        Returns the internal log message object. Caller can further manipulate
        the log object with object-specific calls.
        '''
        return self._log

        
    def fatalConditions(self, *args):
        '''
        get/set the fatalConditions flag.

        The fatalConditions flag toggles the handling of errors in stage
        pre- and post-conditions. If True, the Stage will exit to the
        system. If False, processing continues but with a warning.

        fatalConditions():              returns the current fatalConditions flag
        fatalConditions(True|False):    sets the flag to True|False

        '''
        if len(args):
            self._b_fatalConditions = args[0]
        else:
            return self._b_fatalConditions
        
        
class Stage_crun(Stage):
    '''
    A Stage class that uses crun as its execute engine.
    '''

    def cmd(self, *args):
        '''
        get/set the shell command to execute.

        Setting the command to execute is useful mainly when constructing
        a pipeline of stages.

        cmd():          returns the current fatalConditions flag
        cmd(<str_cmd>): sets the command to execute but does NOT actually
                        trigger the execution. 

        '''
        if len(args):
            self._str_cmd = args[0]
        else:
            return self._str_cmd
    
    def stdout(self):
        '''
        Returns the stdout data from the shell. This reflects the most
        recent stdout collected from executing a system process.
        '''
        return self._shell.stdout()

        
    def stderr(self):
        '''
        Returns the stderr data from the shell. This reflects the most
        recent stderr collected from executing a system process.
        '''
        return self._shell.stderr()

        
    def exitCode(self):
        '''
        Returns the shell exit code from the most command executed.
        '''
        return self._shell.exitCode()

        
    def __init__(self, **kwargs):
        '''
        Sub-class constuctor. Currently sets an internal sub-class
        _shell object, and then calls the super-class constructor.
        '''
        self._shell     = crun.crun()
        Stage.__init__(self, **kwargs)

        
    def __call__(self, **kwargs):
        '''
        The actual stage innards.

        Pre- and post-condition processing is dispatched to the base class
        which makes for cleaner logic in this sub-class.

        '''

        misc.tic() ; self._log('<%s> START...\n' % self.name())

        Stage.__call__(self, checkpreconditions=True)
        
        self._log('Executing stage...\n')
        for key, value in kwargs.iteritems():
            if key == 'cmd':    self._str_cmd   = value
        if len(self._str_cmd):
            str_stdout, str_stderr, exitCode = self._shell(self._str_cmd)
        else:
            self.fatal('NoCmd')

        Stage.__call__(self, checkpostconditions=True)

        self._log('<%s> END. Elapsed time = %f seconds\n' \
                    % (self.name(), misc.toc()))


def crun_factory(astr_name):
    stage = Stage_crun()
    stage.name(astr_name)
    stage.fatalConditions(True)
    stage.log().syslog(True)
    return stage
                    
if __name__ == "__main__":

    def stage_preconditions(**kwargs):
        '''
        Callback for a stage preconditions.

        This function must accept **kwargs and return a boolean.
        '''
        for key, value in kwargs.iteritems():
            if key == 'ret':    ret = value
        return ret
        
    def stage_postconditions(**kwargs):
        '''
        Callback for a stage preconditions.

        This function must accept **kwargs and return a boolean.
        '''
        for key, value in kwargs.iteritems():
            if key == 'ret':    ret = value
        return ret

    stage1 = crun_factory('Stage 1')
        
    # Set the stage pre- and post-conditions callbacks.
    stage1.def_preconditions(    stage_preconditions,    ret=True)
    stage1.def_postconditions(   stage_postconditions,   ret=True)
    stage1_postconditions, stage1_args = stage1.def_postconditions()
    #stage1.def_postconditions(   stage.def_preconditions()[0], **stage.def_preconditions()[1] )
    stage1(cmd='sleep 5')
    
    stage2 = crun_factory('Stage 2')
    stage2.def_preconditions(   stage1_postconditions,  **stage1_args)
    stage2.def_postconditions(  stage_postconditions,   ret=True)
    stage2(cmd='ls *py')

    pipeline    = Pipeline()
    pipeline.name('testPipeline')
    pipeline.stage_add(stage1)
    pipeline.stage_add(stage2)
    pipeline.execute()

    error.warn(pipeline, 'preconditions')
    print pipeline.stage_get(1).stdout()
    