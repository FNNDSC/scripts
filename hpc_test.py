#!/usr/bin/env python

'''

    This "pipeline" is a simple demonstration/testing-platform for
    scheduling, running, and blocking-on jobs on any of the available
    three clusters: PICES (FNNDSC), launchpad (NMR), and erisone (Partners).

    Note, that password-less ssh MUST have been setup to each of the 
    the different clusters for the remote user for this to work.
    
    
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

class CLUSTER(base.FNNDSC):
    '''
    This class is a specialization of the FNNDSC base that 
    simply runs a passed shell command on a target cluster 
    using the 'crun' infrastructure.
    '''

    # 
    # Class member variables -- if declared here are shared
    # across all instances of this class
    #
    _dictErr = {
        'noClusterSpec'     : {
            'action'        : 'checking command line args, ',
            'error'         : 'it seems that an invalid cluster destination was specified.',
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
            
    def stageShell_createRemoteInstance(self, astr_remoteHPC, **kwargs):
        '''
        Returns a crun object in the passed stage object that
        functions as a shell on the remote HPC.
        '''
        for key, val in kwargs.iteritems():
            if key == 'stage':          stage   = val
        for case in misc.switch(astr_remoteHPC):
            if case('PICES'):
                stage.shell(crun.crun_hpc_mosix(
                        remoteUser="rudolphpienaar",
                        remoteHost="rc-drno.tch.harvard.edu")
                        )
                stage.shell().emailUser('rudolph.pienaar@childrens.harvard.edu')
                b_jobDetach         = True
                b_disassocaite      = True
                b_waitForChild      = False
                break
            if case('launchpad'):
                stage.shell(crun.crun_hpc_launchpad(
                        remoteUser="rudolph",
                        remoteHost="pretoria:7774")
                        )
                b_jobDetach         = False
                b_disassocaite      = False
                b_waitForChild      = True
                break
            if case('erisone'):
                stage.shell(crun.crun_hpc_lsf(
                        remoteUser="rp937",
                        remoteHost="pretoria:7773")
                        )
                stage.shell().scheduleHostOnly(
                "cmu058 cmu059 cmu061 cmu066 cmu067 cmu071 cmu073 cmu075 cmu077 cmu079 cmu081 cmu087 cmu090 cmu093 cmu094 cmu095 cmu096 cmu102 cmu106 cmu107 cmu108 cmu109 cmu111 cmu112 cmu114 cmu121 cmu123 cmu126 cmu149 cmu154 cmu156 cmu157 "
                )
                b_jobDetach         = False
                b_disassocaite      = False
                b_waitForChild      = True
                break
            if case():
                error.fatal(self, 'noClusterSpec')
        shell = stage.shell()
        shell.emailWhenDone(True)
        shell.echo(False)
        shell.echoStdOut(False)
        shell.detach(b_jobDetach)
        shell.disassociate(b_disassocaite)
        shell.waitForChild(b_waitForChild)


            
def synopsis(ab_shortOnly = False):
    shortSynopsis =  '''
    SYNOPSIS

            %s                                                  \\
                            [--cmd <command>]                   \\
                            [--jobs <numJobs>]                  \\
                            [--cluster <cluster>]               \\
                            [-v|--verbosity <verboseLevel>] 
    ''' % scriptName
  
    description =  '''
    DESCRIPTION

        `%s' is an extremely simple testing script that shows how to
        run passed command line processes on remote clusters.

        The script is able to remotely login and schedule jobs on several
        cluster types:

            1. The FNNDSC PICES (MOSIX) cluster.
            2. The MGH NMR launchpad (torque-based) cluster.
            3. The Partners erisone (LSF) cluster.

        The ability to remotely login assumes that the user running this
        script has setup password-less ssh access to each headnode of each
        of these accessible clusters.

    ARGS

        --cmd <command>
        The command to test. Use quotes "" to group arguments with command.

        --jobs <numJobs>
        The number of jobs to run on <cluster>.

        --cluster <cluster>
        The target cluster to schedule jobs on. Should be one of: 'PICES',
        'launchpad', or 'erisone'.

    EXAMPLES

        o hpc_test.py --cmd "sleep 50" --jobs 20 --cluster PICES

            Run the "sleep 50" command in 20 jobs on the PICES cluster.

        o hpc_test.py --cmd "sleep 50" --jobs 20 --cluster launchpad
        o hpc_test.py --cmd "sleep 50" --jobs 20 --cluster erisone

            Same as above, but target the 'launchpad' and 'erisone' cluster
            respectively.

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
    detected in cluster %s (%s). Blocking until all scheduled jobs are
    completed. Block interval = %s seconds.
    \n''' % (str_blockProcess,
             stage.shell().clusterName(),
             stage.shell().clusterType(),
             timepoll)
    str_loopMsg     = 'Waiting for scheduled jobs to complete... ' +\
                      '(hit <ctrl>-c to kill this script).    '
    stage.kwBlockOnScheduler(   loopMsg         = str_loopMsg,
                                blockMsg        = str_blockMsg,
                                blockUntil      = str_blockUntil,
                                blockProcess    = str_blockProcess,
                                timeout         = timepoll)
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
    parser.add_argument('--cluster', '-l',
                        dest='cluster',
                        action='store',
                        default='PICES',
                        help='destination cluster to schedule jobs on')
    args = parser.parse_args()

    
    # A "localhost" shell that this script can use to run shell commands on.
    OSshell = crun.crun()
    OSshell.echo(False)
    OSshell.echoStdOut(False)
    OSshell.detach(False)


    hpc = CLUSTER(
                        jobs            = args.jobs,
                        logTo           = 'hpctest.log',
                        syslog          = True,
                        logTee          = True
                        )

    hpc.verbosity(args.verbosity)
    pipeline    = hpc.pipeline()
    pipeline.poststdout(True)
    pipeline.poststderr(True)

    stage0 = stage.Stage(
                        name            = 'scheduler',
                        fatalConditions = True,
                        syslog          = True,
                        logTo           = 'hpctest-schedule.log',
                        logTee          = True,
                        )
    def f_stage0callback(**kwargs):
        for key, val in kwargs.iteritems():
            if key == 'jobs':   jobs            = val
            if key == 'obj':    stage           = val
            if key == 'pipe':   pipeline        = val

        # Create shell for scheduling/executing on the remote HPC
        pipeline.stageShell_createRemoteInstance(args.cluster, stage=stage)
            
        for job in range(0, int(args.jobs)):
            log = stage.log()
            log('Processing job: %d...\n' % job)
            str_cmd = args.cmd
            shell = stage.shell()
            shell(
                str_cmd, waitForChild=shell.waitForChild(), 
                stdoutflush=True, stderrflush=True
            )
            if shell.exitCode():
                error.fatal(hpc, 'stageExec', shell.stderr())
        os.chdir(pipeline.startDir())
        return True

    stage0.def_stage(f_stage0callback, jobs=args.jobs, obj=stage0, pipe=hpc)
    stage0.def_postconditions(f_blockOnScheduledJobs, obj=stage0,
                              blockProcess    = 'sleep')

    hpclog = hpc.log()
    hpclog('INIT: (%s) %s %s\n' % (os.getcwd(), scriptName, ' '.join(sys.argv[1:])))
    hpc.stage_add(stage0)
    hpc.initialize()

    hpc.run()
  
