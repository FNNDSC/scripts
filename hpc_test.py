#!/usr/bin/env python

'''

    This "pipeline" demonstrates how to string together several console-
    based "apps" in the pipeline/stage framework.
    
    Pre- and post-condition checking is based on the underlying stage exit
    code values, assuming a stage has exewcuted. If a pre-stage has not
    been run, the subsequent stage check will return True (otherwise
    the pipeline would require all stages be run for each analysis).
    
'''


import  os
import  sys
import  string
import  argparse
from    _common import systemMisc       as misc
from    _common import crun

import  error
import  message
import  stage

import  fnndsc  as base
import  socket

scriptName      = os.path.basename(sys.argv[0])

class launchpad(base.FNNDSC):
    '''
    This class is a specialization of the FNNDSC base that simply runs
    a few tests on launchpad using the 'crun' infrastructure.
    
    '''

    # 
    # Class member variables -- if declared here are shared
    # across all instances of this class
    #
    _dictErr = {
        'notClusterNode'    : {
            'action'        : 'examining host environment, ',
            'error'         : 'it seems that I\'m not on a cluster node.',
            'exitCode'      : 10},
        'noFreeSurferEnv'   : {
            'action'        : 'examining environment, ',
            'error'         : 'it seems that the FreeSurfer environment has not been sourced.',
            'exitCode'      : 11},
    }

    def startDir(self):
        return self._str_workingDir

    def __init__(self, **kwargs):
        '''
        Basic constructor. Checks on named input args, checks that files
        exist and creates directories.

        '''
        base.FNNDSC.__init__(self, **kwargs)

        self._lw                        = 60
        self._rw                        = 20

        self._str_workingDir            = os.getcwd()
        self._stageslist                = '0'

        self._str_dummy                 = ''

        for key, value in kwargs.iteritems():
            if key == 'someKey':        self._str_dummy         = value

    def initialize(self):
        '''
        This method provides some "post-constructor" initialization. It is
        typically called after the constructor and after other class flags
        have been set (or reset).
        
        '''

        # First, this script should only be run on cluster nodes.
        lst_clusterNodes = ['launchpad']
        str_hostname    = socket.gethostname()
        #if str_hostname not in lst_clusterNodes:
            #error.fatal(self, 'notClusterNode', 'Current hostname = %s' % str_hostname)

        # Set the stages
        self._pipeline.stages_canRun(False)
        lst_stages = list(self._stageslist)
        for index in lst_stages:
            stage = self._pipeline.stage_get(int(index))
            stage.canRun(True)
                
    def run(self):
        '''
        The main 'engine' of the class.

        '''
        base.FNNDSC.run(self)
            
            
def synopsis(ab_shortOnly = False):
    shortSynopsis =  '''
    SYNOPSIS

            %s                                            \\
                            [--cmd <command>]             \\
                            [-v|--verbosity <verboseLevel>] 
    ''' % scriptName
  
    description =  '''
    DESCRIPTION

        `%s' is an extremely simple testing shell used to drive 'crun' on the
        NMR 'launchpad' cluster.

    ARGS

        --cmd <command>
        The command to test. Use quotes "" to group arguments with command.

    EXAMPLES


    ''' % (scriptName)
    if ab_shortOnly:
        return shortSynopsis
    else:
        return shortSynopsis + description

def f_stageShellExitCode(**kwargs):
    '''
    A simple function that returns a conditional based on the
    exitCode of the passed stage object. It assumes global access
    to the <pipeline> object.

    **kwargs:

        obj=<stage>
        The stage to query for exitStatus.
    
    '''
    stage = None
    for key, val in kwargs.iteritems():
        if key == 'obj':                stage                   = val
    if not stage: error.fatal(pipeline, "noStagePostConditions")
    if not stage.callCount():   return True
    if stage.exitCode() == "0": return True
    else: return False


def f_blockOnScheduledJobs(**kwargs):
    '''
    A simple wrapper around a stage.kwBlockOnSchedule(...)
    call.
    '''
    str_blockUntil      = "0"
    str_blockProcess    = ""
    timepoll            = 10
    for key, val in kwargs.iteritems():
        if key == 'obj':                stage                   = val
        if key == 'blockCondition':     str_blockCondition      = val
        if key == 'blockProcess':       str_blockProcess        = val
        if key == 'blockUntil':         str_blockUntil          = val
        if key == 'timepoll':           timepoll                = val
    str_blockMsg    = '''\n
    Postconditions are still running: multiple '%s' instances
    detected in cluster scheduler. Blocking until all scheduled jobs are
    completed. Block interval = %s seconds.
    \n''' % (str_blockProcess, timepoll)
    str_loopMsg     = 'Waiting for scheduled jobs to complete... ' +\
                      '(hit <ctrl>-c to kill this script).    '

    stage.kwBlockOnScheduler(   loopMsg     = str_loopMsg,
                                blockMsg    = str_blockMsg,
                                blockUntil  = str_blockUntil,
                                timeout     = timepoll)
    return True
        
#
# entry point
#
if __name__ == "__main__":


    # always show the help if no arguments were specified
    if len( sys.argv ) == 1:
        print synopsis()
        sys.exit( 1 )

    verbosity   = 0

    parser = argparse.ArgumentParser(description = synopsis(True))
    
    parser.add_argument('--verbosity', '-v',
                        dest='verbosity',
                        action='store',
                        default=0,
                        help='verbosity level')
    parser.add_argument('--cmd', '-c',
                        dest='cmd',
                        action='store',
                        default='ls',
                        help='command to schedule')
    parser.add_argument('--jobs', '-j',
                        dest='jobs',
                        action='store',
                        default='10',
                        help='number of instances of <cmd> to schedule')
    args = parser.parse_args()

    OSshell = crun.crun()
    OSshell.echo(False)
    OSshell.echoStdOut(False)
    OSshell.detach(False)

    tp = launchpad(
                        jobs            = args.jobs,
                        logTo           = 'tptest.log',
                        syslog          = True,
                        logTee          = True
                        )

    tp.verbosity(args.verbosity)
    pipeline    = tp.pipeline()
    pipeline.poststdout(True)
    pipeline.poststderr(True)

    stage0 = stage.Stage(
                        name            = 'scheduler',
                        fatalConditions = True,
                        syslog          = True,
                        logTo           = 'tptest-schedule.log',
                        logTee          = True,
                        )
    def f_stage0callback(**kwargs):
        for key, val in kwargs.iteritems():
            if key == 'jobs':   jobs            = val
            if key == 'obj':    stage           = val
            if key == 'pipe':   pipeline        = val
            
        for job in range(0, int(args.jobs)):
            log = stage.log()
            log('Processing job: %d...\n' % job)
            str_cmd = args.cmd
            print str_cmd
            #stage.shell(crun.crun_launchpad(remoteUser="rudolph", remoteHost="launchpad"))
            stage.shell(crun.crun_lsf(remoteUser="rp937", remoteHost="erisone.partners.org"))
            shell = stage.shell()
            shell.emailWhenDone(True)
            shell.echo(False)
            shell.echoStdOut(False)
            shell.detach(False)
            shell(str_cmd, waitForChild=True, stdoutflush=True, stderrflush=True)
            if shell.exitCode():
                error.fatal(tp, 'stageExec', shell.stderr())
        os.chdir(pipeline.startDir())
        return True

    stage0.def_stage(f_stage0callback, jobs=args.jobs, obj=stage0, pipe=tp)
    stage0.def_postconditions(f_blockOnScheduledJobs, obj=stage0,
                              blockProcess    = '<scheduler>')

    tplog = tp.log()
    tplog('INIT: (%s) %s %s\n' % (os.getcwd(), scriptName, ' '.join(sys.argv[1:])))
    tp.stage_add(stage0)
    tp.initialize()

    tp.run()
  
