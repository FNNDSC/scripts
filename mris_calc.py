#!/usr/bin/env python

'''

    This "pipeline" demonstrates a SIMD (single-instruction-multiple-data)
    architecture implementation within the context of the CHB PICES MOSIX
    cluster.

    Each stage of the pipeline essentially runs the same command (single
    instruction) on multiple subjects and hemispheres (multiple-data).

    Organizationally, each stage constructs for each of its data targets
    a single command string and then schedules this command on each data
    target on the PICES cluster.

    Stages are completely "fire-and-forget". Once scheduled, the stage has
    no direct mechanism of communicating with each job. Since each stage
    schedules multiple hundreds of jobs, it attempts in its postconditions
    check to query the MOSIX scheduler and count the instances of the
    job it has fired. When this count falls to zero, the jobs are all
    considered complete and the stage postconditions are satisfied.

    Stage postconditions are responsible for blocking processing. Only when
    these postconditions are satisfied does the main "thread" continue.
    Subsequent stages define their precondition check as a direct
    predecessor's postconditions.

'''

import  os
import  shutil
import  sys
import  string
import  argparse
import  time
import  glob

from    _common import systemMisc       as misc
from    _common import crun
from    _common._colors import Colors

import  error
import  message
import  stage


import  fnndsc  as base
import  socket

scriptName      = os.path.basename(sys.argv[0])

class FNNDSC_MRISCALC(base.FNNDSC):
    '''
    This class is a specialization of the FNNDSC base and performs an
    explicit mris_calc call on each pair of passed arguments.
    
    
    '''

    # 
    # Class member variables -- if declared here are shared
    # across all instances of this class
    #
    _dictErr = {
        'subjectSpecFail'   : {
            'action'        : 'examining command line arguments, ',
            'error'         : 'it seems that no subjects were specified.',
            'exitCode'      : 10},
        'noFreeSurferEnv'   : {
            'action'        : 'examining environment, ',
            'error'         : 'it seems that the FreeSurfer environment has not been sourced.',
            'exitCode'      : 11},
        'notClusterNode'    : {
            'action'        : 'checking the execution environemt, ',
            'error'         : 'script can only run on a cluster node.',
            'exitCode'      : 12},
        'operandFilenotExist': {
            'action'        : 'examining the <operandFiles>, ',
            'error'         : 'the file does not exist.',
            'exitCode'      : 13},
        'stageExec'         : {
            'action'        : 'executing stage, ',
            'error'         : 'an external error was detected.',
            'exitCode'      : 30},
        'Load'              : {
            'action'        : 'attempting to pickle load object, ',
            'error'         : 'a PickleError occured.',
            'exitCode'      : 20}
    }


    def hemisphere(self):
        return self._l_hemi


    def surface(self):
        return self._l_surface


    def vertices(self):
        return self._d_vertices

        
    def __init__(self, **kwargs):
        '''
        Basic constructor. Checks on named input args, checks that files
        exist and creates directories.

        '''
        base.FNNDSC.__init__(self, **kwargs)

        self._lw                        = 60
        self._rw                        = 20
        self._l_operands                = []
                
        for key, value in kwargs.iteritems():
            if key == 'operands':       self._l_operands        = value
            if key == 'stages':         self._stageslist        = value
            

    def initialize(self):
        '''
        This method provides some "post-constructor" initialization. It is
        typically called after the constructor and after other class flags
        have been set (or reset).
        
        '''

        # First, this script should only be run on cluster nodes.
        lst_clusterNodes = ['rc-drno', 'rc-russia', 'rc-thunderball',
                            'rc-goldfinger', 'rc-twice']
        str_hostname    = socket.gethostname()
        #if str_hostname not in lst_clusterNodes:
            #error.fatal(self, 'notClusterNode', 'Current hostname = %s' % str_hostname)

        # Set the stages
        self._pipeline.stages_canRun(False)
        lst_stages = list(self._stageslist)
        for index in lst_stages:
            stage = self._pipeline.stage_get(int(index))
            stage.canRun(True)

        # Check for FS env variable
        self._log('Checking on FREESURFER_HOME', debug=9, lw=self._lw)
        if not os.environ.get('FREESURFER_HOME'):
            error.fatal(self, 'noFreeSurferEnv')
        self._log('[ ok ]\n', debug=9, rw=self._rw, syslog=False)
            
        for str_operand in self._l_operands:
            self._log('Checking on operand <%s>' % str_operand,
                        debug=9, lw=self._lw)
            if os.path.isfile(str_operand):
                self._log('[ ok ]\n', debug=9, rw=self._rw, syslog=False)
            else:
                self._log('[ not found ]\n', debug=9, rw=self._rw,
                            syslog=False)
                error.fatal(self, 'operandFilenotExist')

                
    def run(self):
        '''
        The main 'engine' of the class.

        '''
        base.FNNDSC.run(self)
            

### Non-class methods
            
def synopsis(ab_shortOnly = False):
    shortSynopsis =  '''
    SYNOPSIS

            %s                                      \\
                            [--verbosity|-v <verboseLevel>]     \\
                            [--output | -o <outputFile>]        \\
                            [--stages|-s <stages>]                 \\
                            --operation |-p <operation>       \\
                            <operand1> <operand2> ... <operandN>
    ''' % scriptName
  
    description =  '''
    DESCRIPTION

        `%s' is a python wrapper around the FreeSurfer 'mris_pmake' that
        performs a single <operation> on cumulative pairs of <operand>s.
        
    ARGS

        --stages|-s <stages>
        The stages to execute. This is specified in a string, such as '1234'
        which would imply stages 1, 2, 3, and 4.

        The special keyword 'all' can be used to turn on all stages.

        <operand1> <operand2> ... <operandN>
        The 'mris_calc' compatible files to process.

    STAGES

            o 0 - mris_calc: build and drive the mris_calc engine on cumulative
                             results of sub-operations.
        
    PRECONDITIONS
    
    POSTCONDITIONS
    
    EXAMPLES

        $>mris_calc.py --output sum.crv --operation add k_1.crv k_2.crv k_3.crv k_4.crv

        The output file 'sum.crv' is the 'add' of all the passed crv files, i.e.

            sum.crv = k_1.crv + k_2.crv + k_3.crv + k_4.crv
        

    ''' % (scriptName)
    if ab_shortOnly:
        return shortSynopsis
    else:
        return shortSynopsis + description


def f_blockOnScheduledJobs(**kwargs):
    '''
    A simple wrapper around a stage.blockOnShellCmd(...)
    call.
    '''
    str_blockCondition  = 'mosq listall | wc -l'
    str_blockProcess    = 'undefined'
    str_blockUntil      = "0"
    timepoll            = 10
    for key, val in kwargs.iteritems():
        if key == 'obj':                stage                   = val
        if key == 'blockCondition':     str_blockCondition      = val
        if key == 'blockUntil':         str_blockUntil          = val
        if key == 'blockProcess':
            str_blockProcess            = val
            str_blockCondition          = 'mosq listall | grep %s | wc -l' % str_blockProcess
        if key == 'timepoll':           timepoll                = val
    str_blockMsg    = '''\n
    Postconditions are still running: multiple '%s' instances
    detected in MOSIX scheduler. Blocking until all scheduled jobs are
    completed. Block interval = %s seconds.
    \n''' % (str_blockProcess, timepoll)
    str_loopMsg     = 'Waiting for scheduled jobs to complete... ' +\
                      '(hit <ctrl>-c to kill this script).'
                        
    stage.blockOnShellCmd(  str_blockCondition, str_blockUntil,
                            str_blockMsg, str_loopMsg, timepoll)
    return True

        
#
# entry point
#
if __name__ == "__main__":


    # always show the help if no arguments were specified
    if len( sys.argv ) == 1:
        print synopsis()
        sys.exit( 1 )

    l_subj      = []
    b_query     = False
    verbosity   = 0

    parser = argparse.ArgumentParser(description = synopsis(True))
    
    parser.add_argument('l_operand',
                        metavar='OPERAND', nargs='+',
                        help='mris_calc file (operand) to process')
    parser.add_argument('--verbosity', '-v',
                        dest='verbosity', 
                        action='store',
                        default=0,
                        help='verbosity level')
    parser.add_argument('--stages', '-s',
                        dest='stages',
                        action='store',
                        default='0',
                        help='pipline stages')
    parser.add_argument('--output', '-o',
                        dest='output',
                        action='store',
                        default='out.crv',
                        help='name of final output result file')
    parser.add_argument('--operation', '-p',
                        dest='operation',
                        action='store',
                        default='add',
                        help='operation to perform over cumulative list of operands')
    args = parser.parse_args()
    
    # First, define the container pipeline
    pipe_mrisCalc = FNNDSC_MRISCALC(
                        operands        = args.l_operand,
                        stages          = args.stages,
                        logTo           = 'MC.log',
                        syslog          = True,
                        logTee          = True
                        )
    pipe_mrisCalc.verbosity(args.verbosity)
    pipeline    = pipe_mrisCalc.pipeline()
    pipeline.log()('INIT: %s %s\n' % (scriptName, ' '.join(sys.argv[1:])))
    pipeline.name('MC')
    pipeline.poststdout(True)
    pipeline.poststderr(True)

    # Now define each stage...

    #
    # Stage 0
    # This is a callback stage, demonstrating how python logic is used
    # to create multiple cluster-based processing instances of the same
    # core FreeSurfer command, each with slightly different operating
    # flags.
    # 
    #
    # PRECONDITIONS:
    # o Check that script is running on a cluster node.
    # 
    stage0 = stage.Stage(
                        name            = 'mris_calc',
                        fatalConditions = True,
                        syslog          = True,
                        logTo           = 'MC-mris_calc.log',
                        logTee          = True
                        )
    def f_stage0callback(**kwargs):
        str_cwd         =  os.getcwd()
        for key, val in kwargs.iteritems():
            if key == 'operand':        l_operand       = val
            if key == 'obj':            stage           = val
            if key == 'pipe':           pipeline        = val
        count = 0
        for i in range(1, len(l_operand)):
            if i == 1: str_previousOutput = l_operand[i-1]
            str_cumulativeOutput = "%d-%s" % (i, args.output)
            str_cmd = 'mris_calc -o %s %s %s %s ; cp %s %s' % \
                        (str_cumulativeOutput, str_previousOutput, args.operation, l_operand[i],
                         str_cumulativeOutput, os.path.basename(str_previousOutput))
            str_previousOutput = os.path.basename(str_previousOutput)
            print str_cmd
            cluster = crun.crun()
            cluster.echo(False)
            cluster.echoStdOut(False)
            cluster.detach(False)
            cluster(str_cmd, waitForChild=True, stdoutflush=True, stderrflush=True)
            if cluster.exitCode():
                error.fatal(pipe_mrisCalc, 'stageExec', cluster.stderr())
            count += 1
        if not count: error.fatal(pipe_mrisCalc, 'stageExec', "Insufficient operands found!")
        return True
    stage0.def_stage(f_stage0callback, operand=args.l_operand, obj=stage0, pipe=pipe_mrisCalc)
    stage0.def_postconditions(f_blockOnScheduledJobs, obj=stage0,
                              blockProcess    = 'mris_calc')

    
    # Add all the stages to the pipeline  
    pipe_mrisCalc.stage_add(stage0)

    # Initialize the pipeline and ... run!
    pipe_mrisCalc.initialize()
    pipe_mrisCalc.run()
  
