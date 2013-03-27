#!/usr/bin/env python

import  sys
import  types
import  time

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
            'exitCode'      : 12},
        'stageError'        : {
            'action'        : 'executing a stage in the pipeline, ',
            'error'         : 'the stage reported an error condition.',
            'exitCode'      : 13}
    }


    def verbosity(self, *args):
        '''
        get/set the verbosity level.

        The verbosity level is passed down to the log object.

        verbosity():    returns the current level
        verbosity(<N>): sets the verbosity to <N>

        '''
        if len(args):
            self._verbosity             = args[0]
            self.log().verbosity(args[0])
        else:
            return self._verbosity
    
    
    def pipeline(self):
        '''
        Get the pipeline.
        '''
        return self._pipeline

        
    def poststdout(self, *args):
        '''
        get/set the poststdout flag. This flag toggles outputing the stdout
        buffer of a stage after the stage has completed processing.

        '''
        if len(args):
            self._b_poststdout = args[0]
        else:
            return self._b_poststdout


    def poststderr(self, *args):
        '''
        get/set the poststdout flag. This flag toggles outputing the stderr
        buffer of a stage after the stage has completed processing.

        '''
        if len(args):
            self._b_poststderr = args[0]
        else:
            return self._b_poststderr


    def log(self, *args):
        '''
        get/set the internal pipeline log message object.
        
        Caller can further manipulate the log object with object-specific 
        calls.
        '''
        if len(args):
            self._log = args[0]
        else:
            return self._log


    def name(self, *args):
        '''
        get/set the descriptive name text of this pipeline object.
        '''
        if len(args):
            self.__name = args[0]
        else:
            return self.__name
        
        
    def __init__(self, **kwargs):
        '''
        Constructor
        '''
        self.__name             = 'unnamed pipeline'
        self._log               = message.Message()
        self._pipeline          = []
        self._verbosity         = 0
        self._b_poststdout      = False
        self._b_poststderr      = False
        for key, value in kwargs.iteritems():
            if key == 'name':               self.name(value)
            if key == 'fatalConditions':    self.fatalConditions(value)
            if key == 'syslog':             self.log().syslog(value)
            if key == 'verbosity':          self.verbosity(value)
            if key == 'logTo':              self.log().to(value)
            if key == 'logTee':             self.log().tee(value)


    def stage_add(self, stage):
        '''
        Add a stage to the pipeline.
        '''
        self._pipeline.append(stage)


    def stage_get(self, index):
        '''
        Return the stage referenced by <index>.

        The <index> can be specified in several ways:

        o an integer offset into the pipeline list.
        o a string "name" of a particular stage.
        
        '''
        if type(index) is types.IntType:
            if index >= len(self._pipeline):
                error.fatal(self, 'stageNotFound')
            return self._pipeline[index]
        if type(index) is types.StringType:
            for stage in self._pipeline:
                if stage.name() == index:
                    return stage
            error.fatal(self, 'stageNotFound')    

            
    def pop(self):
        '''
        Pop a stage from the pipeline stack.
        '''
        ret = self._pipeline.pop()
        return ret


    def stages_canRun(self, value):
        '''
        Sets the 'canRun' flag of each stage in the pipeline to <value>
        '''
        for stage in self._pipeline:
            stage.canRun(value)
        
    def execute(self):
        '''
        Run the pipeline, stage by stage.
        '''
        self._log(  Colors.CYAN + 'Executing pipeline ' +
                    Colors.PURPLE +  '<'+self.name()+'>' + Colors.NO_COLOUR + '...\n')
        for stage in self._pipeline:
          if stage.canRun():
            self._log(Colors.YELLOW + 'Stage: ' + stage.name() + '\n' + Colors.NO_COLOUR)
            stage(checkpreconditions=True, runstage=True, checkpostconditions=True)
            log = stage.log()
            if self._b_poststdout:
                log(Colors.LIGHT_GREEN + 'stage stdout:\n' + Colors.NO_COLOUR)
                log('\n' + Colors.LIGHT_GREEN + stage.stdout() + Colors.NO_COLOUR)
            if self._b_poststderr:
                log(Colors.LIGHT_RED + 'stage stderr:\n' + Colors.NO_COLOUR)
                log('\n' + Colors.LIGHT_RED + stage.stderr() + Colors.NO_COLOUR)
            if stage.exitCode():
                error.fatal(self, 'stageError', '%s' % stage.name())
        self._log(  Colors.CYAN + 'Terminating pipeline ' +
                    Colors.PURPLE +  '<'+self.name()+'>' + Colors.NO_COLOUR + '\n')
        

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

            
class Stage:
    '''
    A simple 'stage' class used for constructing serialized pipeline
    processing streams.

    A stage represents a single processing operation comprising:

        - preconditions check
        - stage execution
        - postconditions check

    Each of these components are defined as callbacks that are
    assigned by the caller, and conform to the following:

        - each callback must return boolean
        - each callback arguments are **kwargs
    
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
    
    def shell(self, *args):
        '''
        get/set the shell object.

        shell():       returns the current shell object
        shell(<obj>):  sets the shell object to <obj>

        '''
        if len(args):
            self._shell = args[0]
        else:
            return self._shell
    
    def stdout(self, *args):
        '''
        get/set the stdout analog level.

        stdout():       returns the current stdout buffer
        stdout(<str>):  sets the stdout to <str>

        '''
        if len(args):
            self._str_stdout    = args[0]
        else:
            return self._str_stdout


    def stderr(self, *args):
        '''
        get/set the stderr analog level.

        stderr():       returns the current stderr buffer
        stderr(<str>):  sets the stderr to <str>

        '''
        if len(args):
            self._str_stderr    = args[0]
        else:
            return self._str_stderr

    def callCount(self, *args):
        '''
        get/set the callCount value.

        The callCount is usually incremented by 1 each time
        the __call__() method is executed. It also provides
        an external caller a simple mechanism for checking
        if a stage has been "executed".

        callCount():     returns the current callCount
        callCount(<i>):  sets the callCount to <i>

        '''
        if len(args):
            self._callCount  = args[0]
        else:
            return self._callCount

            
    def exitCode(self, *args):
        '''
        get/set the exitCode analog level.

        exitCode():     returns the current exitCode buffer
        exitCode(<i>):  sets the exitCode to <i>

        '''
        if len(args):
            self._str_exitCode  = args[0]
        else:
            return self._str_exitCode


    def verbosity(self, *args):
        '''
        get/set the verbosity level.

        verbosity():    returns the current level
        verbosity(<N>): sets the verbosity to <N>

        '''
        if len(args):
            self._verbosity             = args[0]
            self.log().verbosity(args[0])
        else:
            return self._verbosity
    
    
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

        # The fatalConditions flag controls behaviour while checking pre- and
        # post and shell return conditions. If True, failed pre-, post- or shell 
        # conditions will result in a fatal failure. Processing will otherwise
        # continue.
        self._b_fatalConditions = True

        # A stage also contains a "shell" object used for interacting with the
        # host OS environment. Specific sub-classes of 'crun' actually use this
        # shell to run the stage internals; however all stages can use the 
        # shell in any capacity.
        self._shell             = None

        # The canRun flag is a simple toggle that can be controlled by a caller
        # to either turn a stage off or on, but leave it otherwise intact.
        self._b_canRun          = True
        self._callCount         = 0

        self._verbosity         = 1

        self._str_cmd           = ''
        self._str_stdout        = ''
        self._str_stderr        = ''
        self._str_exitCode      = ''
        
        self._f_preconditions           = lambda **x: True
        self._f_preconditionsArgs       = {'val': True}
        self._f_stage                   = lambda **x: True
        self._f_stageArgs               = {'val': True}
        self._f_postconditions          = lambda **x: True
        self._f_postconditionsArgs      = {'val': True}
        for key, value in kwargs.iteritems():
            if key == 'name':               self.name(value)
            if key == 'fatalConditions':    self.fatalConditions(value)
            if key == 'syslog':             self.log().syslog(value)
            if key == 'verbosity':          self.verbosity(value)
            if key == 'cmd':                self.cmd(value)
            if key == 'logTo':              self.log().to(value)
            if key == 'logTee':             self.log().tee(value)
            if key == 'def_stage':          self._f_stage = value

        
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


    def def_stage(self, *args, **kwargs):
        '''
        get/set the 'stage' function

        This method assigns the internal 'stage' function to
        args[0], and passes the optional named keyword arguments to
        this external function.

        '''
        if len(args):
            self._f_stage               = args[0]
            self._f_stageArgs           = kwargs
        else:
            return self._f_stage, self._f_stageArgs

            
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


    def stage(self):
        '''
        Evaluates the internal stage callback, and returns
        a boolean result.

        '''
        self._log('Calling stage...\n')
        ret = self._f_stage(**self._f_stageArgs)
        return ret
        
       
    def callPreconditionsOnly(self):
        '''
        This is a convenience function that calls the main stage
        functor, but only executes the precondition check.
        '''
        Stage.__call__( self,
                        checkpreconditions=True, 
                        runstage=False, 
                        checkpostconditions=False,
                        preamble=True,
                        postamble=False)


    def callPostconditionsOnly(self):
        '''
        This is a convenience function that calls the main stage
        functor, but only executes the precondition check.
        '''
        Stage.__call__( self,
                        checkpreconditions=False, 
                        runstage=False, 
                        checkpostconditions=True,
                        preamble=False,
                        postamble=True)
        
        
    def __call__(self, **kwargs):
        '''
        The base class __call__ functor "runs" the stage. Each stage
        consists of three components:

            o preconditions
            o stage
            o postconditions

        By default, all three componets are executed in order    
        pre- and/or post-conditions checking.

        If called with (stage=True) will execute the externally defined
        stage callback.

        '''
        if self._b_canRun:
            b_preconditionsRun  = True
            b_stageRun          = True
            b_postconditionsRun = True
            b_preamble          = True
            b_postamble         = True

            for key, value in kwargs.iteritems():
                if key == 'checkpreconditions':   b_preconditionsRun    = value
                if key == 'runstage':             b_stageRun            = value
                if key == 'checkpostconditions':  b_postconditionsRun   = value
                if key == 'preamble':             b_preamble            = value
                if key == 'postamble':            b_postamble           = value
            
            if b_preamble:
                misc.tic() ; self._log(Colors.GREEN + \
                                       '<%s> START' % self.name() + \
                                       Colors.NO_COLOUR +'...\n' )

            if b_preconditionsRun:
                if not self.preconditions():
                    error.report(self, 'preconditions', self._b_fatalConditions)
            if b_stageRun:
                self._callCount += 1
                if not self.stage():
                    error.report(self, 'stage', self._b_fatalConditions)
            if b_postconditionsRun:
                if not self.postconditions():
                    error.report(self, 'postconditions', self._b_fatalConditions)

            if b_postamble:
                self._log(Colors.GREEN      + '<%s> END' % self.name()      + \
                        Colors.NO_COLOUR  + '. Elapsed time = '           + \
                        Colors.CYAN       + '%f' % misc.toc()             + \
                        Colors.NO_COLOUR  + ' seconds.\n') 
                    

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

        
    def canRun(self, *args):
        '''
        get/set the canRun flag.

        The canRun flag toggles an 'kill switch' condition on the stage.
        If an external caller sets the flag to False, the stage will run
        even if explicitly called. It allows streams of stages to be
        externally toggled on or off.

        canRun():               returns the current fatalConditions flag
        canRun(True|False):     sets the flag to True|False

        '''
        if len(args):
            self._b_canRun = args[0]
        else:
            return self._b_canRun



    def kwBlockOnScheduler(self, **kwargs):
        '''
        A 'kwargs' block-on-jobs-in-scheduler method. This method assumes 
        that the internal stage shell is a scheduler-based crun that
        can be queried for its queue method.

        Not all kwargs can be completely processed by all queue methods.

        kwargs:
            blockProcess                process in scheduler to block on
            blockMsg                    log message when block starts
            loopMsg                     log message while blocking
            timeout                     how long between checking astr_shellCmd
                                        while blocking
        '''
        for key, val in kwargs.iteritems():
            if key == 'blockProcess':   astr_blockProcess       = val
            if key == 'blockMsg':       astr_blockMsg           = val
            if key == 'loopMsg':        astr_loopMsg            = val
            if key == 'timeout':        atimeout                = val
            if key == 'blockUntil':     ablockUntil             = val
        (str_running, str_scheduled, str_completed) = self.shell().queueInfo(blockProcess=astr_blockMsg)    
        astr_allJobsDoneCount           = ablockUntil
        blockLoop       = 1
        if str_running != astr_allJobsDoneCount:
            self._log(Colors.CYAN + astr_blockMsg + Colors.NO_COLOUR)
            while 1:
                time.sleep(atimeout)
                str_running, str_scheduled, str_completed = self.shell().queueInfo(blockProcess=astr_blockMsg)    
                if str_running == astr_allJobsDoneCount:
                    self._log('\n', syslog=False)
                    break
                else:
                    str_loopMsg         = Colors.BROWN + \
                    '(block duration = %ds; running/completed/scheduled = %s/%s/%s) '% \
                    (blockLoop * atimeout, str_running, str_completed, str_scheduled) + \
                    Colors.YELLOW + astr_loopMsg + Colors.NO_COLOUR
                    self._log(str_loopMsg)
                    loopMsgLen          = len(str_loopMsg)
                    syslogLen           = len(self._log.str_syslog())
                    for i in range(0, loopMsgLen+syslogLen): self._log('\b', syslog=False)
                    blockLoop           += 1
        return True


    def kwBlockOnShellCmd_rs(self, **kwargs):
        '''
        A 'kwargs' version of the 'blockOnShellCmd' call. Useful for cases
        when more complex blocking conditions need to be evaluated.

        The _rs denotes that this method is specialized to flagging
        running *and* scheduled jobs.

        This particular method is MOSIX specific.

        kwargs:
            blockProcess                process in scheduler to block on
            blockMsg                    log message when block starts
            loopMsg                     log message while blocking
            timeout                     how long between checking astr_shellCmd
                                        while blocking
        '''
        for key, val in kwargs.iteritems():
            if key == 'blockProcess':   astr_blockProcess       = val
            if key == 'blockMsg':       astr_blockMsg           = val
            if key == 'loopMsg':        astr_loopMsg            = val
            if key == 'timeout':        atimeout                = val 
        shellScheduleCount              = crun.crun()
        shellRunCount                   = crun.crun()
        astr_processInSchedulerCount    = 'mosq listall | grep %s | wc -l' % astr_blockProcess
        astr_allJobsDoneCount           = '0'
        astr_processRunningCount        = 'mosq listall | grep %s | grep RUN | wc -l' % astr_blockProcess
        shellScheduleCount(astr_processInSchedulerCount)
        blockLoop       = 1
        if shellScheduleCount.stdout().strip() != astr_allJobsDoneCount:
            self._log(Colors.CYAN + astr_blockMsg + Colors.NO_COLOUR)
            while 1:
                time.sleep(atimeout)
                shellScheduleCount(astr_processInSchedulerCount)
                shellRunCount(astr_processRunningCount)
                str_scheduled   = shellScheduleCount.stdout().strip()
                str_running     = shellRunCount.stdout().strip()
                if str_scheduled == astr_allJobsDoneCount:
                    self._log('\n', syslog=False)
                    break
                else:
                    str_loopMsg         = Colors.BROWN + '(block duration = %ds; running/scheduled = %s/%s) '% \
                                          (blockLoop * atimeout, str_running, str_scheduled) + \
                                          Colors.YELLOW + astr_loopMsg + Colors.NO_COLOUR
                    self._log(str_loopMsg)
                    loopMsgLen          = len(str_loopMsg)
                    syslogLen           = len(self._log.str_syslog())
                    for i in range(0, loopMsgLen+syslogLen): self._log('\b', syslog=False)
                    blockLoop           += 1
        return True


    def blockOnShellCmd(self, astr_shellCmd, astr_shellReturn,
                        astr_blockMsg,
                        astr_loopMsg,
                        atimeout = 10):
        '''
        Block on a shell command.

        This method will repeatedly poll a given <str_shellCmd> every
        <atimeout> seconds until the command evaluates to <astr_shellReturn>.
        The <astr_shellCmd> itself should not block, but simply evaluate a
        condition and return a status.

        It is typically used as either a pre- or post-condition filter.

        ARGS
            astr_shellCmd               shell command to evaluate
            astr_shellReturn            the return from the shell command
                                        indicating success
            astr_blockMsg               log message when block starts
            astr_loopMsg                log message while blocking
            atimeout                    how long between checking astr_shellCmd
                                        while blocking
        RETURN
            o True
        
        '''
        shell           = crun.crun()
        shell(astr_shellCmd)
        blockLoop       = 1
        if shell.stdout().strip() != astr_shellReturn:
            self._log(Colors.CYAN + astr_blockMsg + Colors.NO_COLOUR)
            while 1:
                time.sleep(atimeout)
                shell(astr_shellCmd)
                if shell.stdout().strip() == astr_shellReturn:
                    self._log('\n', syslog=False)
                    break
                else:
                    str_loopMsg         = Colors.BROWN + '(block duration = %ds; block processCount = %s) '% \
                                          (blockLoop * atimeout, shell.stdout().strip()) + \
                                          Colors.YELLOW + astr_loopMsg + Colors.NO_COLOUR
                    self._log(str_loopMsg)
                    loopMsgLen          = len(str_loopMsg)
                    syslogLen           = len(self._log.str_syslog())
                    for i in range(0, loopMsgLen+syslogLen): self._log('\b', syslog=False)
                    blockLoop           += 1
        return True
        
            
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
        self._shell             = crun.crun()
        Stage.__init__(self, **kwargs)

        # The following flags force flushing of stdout/stderr streams
        # while executing shell command. These are useful for "slow"
        # shell operations that take a long time to return but still
        # generate output to stdout/stderr.
        self._b_stdoutflush     = True
        self._b_stderrflush     = True
        for key, value in kwargs.iteritems():
            if key == 'stdoutflush':    self._b_stdoutflush = value
            if key == 'stderrflush':    self._b_stderrflush = value
        
    def __call__(self, **kwargs):
        '''
        The actual stage innards.

        Pre- and post-condition processing is dispatched to the base class
        which makes for cleaner logic in this sub-class.

        '''

        #misc.tic() ; self._log('<%s> START...\n' % self.name())

        # Here we call the base-class stage handler and only execute the
        # precondition check.
        self.callPreconditionsOnly()

        # The Stage_crun has a specialized stage execution.
        self._log('Executing stage...\n')
        for key, value in kwargs.iteritems():
            if key == 'cmd':    self._str_cmd   = value
        if len(self._str_cmd):
            str_stdout, str_stderr, exitCode = self._shell(self._str_cmd,
                                    stdoutflush = self._b_stdoutflush,
                                    stderrflush = self._b_stderrflush)
            if exitCode: return
        else:
            self.fatal('NoCmd')

        # Now we again call the base-class stage handler and only execute 
        # the postconditions
        self.callPostconditionsOnly()

        
class Stage_crun_mosix(Stage_crun):
    '''
    A Stage class that uses crun_mosix as its execute engine.
    '''
    def __init__(self, **kwargs):
        '''
        Sub-class constuctor. Currently sets an internal sub-class
        _shell object, and then calls the super-class constructor.
        '''
        # First, filter out any args pertinent to the crun_mosix object
        crun_kwargs     = {}
        for key, value in kwargs.iteritems():
            if 'crun' in key: crun_kwargs[key[4:]] = value
        self._shell     = crun.crun_mosix(**crun_kwargs)
        Stage.__init__(self, **kwargs)


    def __call__(self, **kwargs):
        '''
        The actual stage innards.

        '''
        self._log('Scheduling to cluster...\n')
        Stage_crun.__call__(self, **kwargs)

                    

def crun_factory(**kwargs):
    stage = Stage_crun()
    for key, value in kwargs.iteritems():
        if key == 'name':               stage.name(value)
        if key == 'fatalConditions':    stage.fatalConditions(value)
        if key == 'syslog':             stage.log().syslog(value)
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

    stage1 = Stage_crun(name='Stage 1', fatalConditions=True, syslog=True)
        
    # Set the stage pre- and post-conditions callbacks.
    stage1.def_preconditions(    stage_preconditions,    ret=True)
    stage1.def_postconditions(   stage_postconditions,   ret=True)
    stage1_postconditions, stage1_args = stage1.def_postconditions()
    #stage1.def_postconditions(   stage.def_preconditions()[0], **stage.def_preconditions()[1] )
    stage1(cmd='sleep 1')
    
    stage2 = crun_factory(name='Stage 2', fatalConditions=True, syslog=True)
    stage2.def_preconditions(   stage1_postconditions,  **stage1_args)
    stage2.def_postconditions(  stage_postconditions,   ret=True)
    stage2(cmd='ls *py')

    pipeline    = Pipeline()
    pipeline.name('testPipeline')
    pipeline.stage_add(stage1)
    pipeline.stage_add(stage2)
    pipeline.execute()

    print pipeline.stage_get('Stage 2').stdout()
    print pipeline.stage_get(1).stdout()
    