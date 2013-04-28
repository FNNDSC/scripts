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

_str_curv       = 'H'
_partitions     = 100
_maxPartitions  = 1000

scriptName      = os.path.basename(sys.argv[0])

class FNNDSC_HBWMmeta(base.FNNDSC):
    '''
    This class is a specialization of the FNNDSC base and geared to dyslexia
    curvature analysis.
    
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
        'noStagePostConditions' : {
            'action'        : 'querying a stage for its exitCode, ',
            'error'         : 'it seems that the stage has not been specified.',
            'exitCode'      : 12},
        'subjectDirnotExist': {
            'action'        : 'examining the <subjectDirectories>, ',
            'error'         : 'the directory does not exist.',
            'exitCode'      : 13},
        'Load'              : {
            'action'        : 'attempting to pickle load object, ',
            'error'         : 'a PickleError occured.',
            'exitCode'      : 14},
        'Partition'         : {
            'action'        : 'setting up partitions, ',
            'error'         : 'the max partition number is %d. Too many partitions specified.' % _maxPartitions,
            'exitCode'      : 14},
        'stageExec'         : {
            'action'        : 'running a stage in the pipeline, ',
            'error'         : 'the stage reported an internal failure state.',
            'exitCode'      : 15},
    }


    def l_hemisphere(self):
        return self._l_hemi

    def l_surface(self):
        return self._l_surface

    def l_curv(self):
        return self._l_curv

    def d_vertices(self):
        return self._d_vertices

    def subj(self):
        return self._str_subj

    def surface(self):
        return self._str_surface

    def hemi(self):
        return self._str_hemi

    def curvList(self):
        return self._curvList

    def curv(self):
        return self._str_curv

    def subjDir(self):
        return "%s/%s" % (self._str_workingDir, self._str_subj)

    def analysisDir(self):
        return "%s/%s/%s/%s/%s" % \
            (self.subjDir(), _str_HBWMdir, self._str_hemi, self._str_surface, self._str_curv)

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

        self._str_subjectDir            = ''
        self._stageslist                = '0'
        self._hemiList                  = 'lh,rh'
        self._surfaceList               = 'smoothwm,pial'
        self._curvList                  = 'H,K'

        self._l_subject                 = []
        self._l_hemi                    = []
        self._l_surface                 = []
        self._l_curv                    = []

        # Internal tracking vars
        self._str_subj                  = ''
        self._str_hemi                  = ''
        self._str_surface               = ''
        self._str_curv                  = ''


        self._str_workingDir            = os.getcwd()

        for key, value in kwargs.iteritems():
            if key == 'subjectList':    self._l_subject         = value
            if key == 'stages':         self._stageslist        = value
            if key == 'hemiList':       self._l_hemi            = value.split(',')
            if key == 'surfaceList':    self._l_surface         = value.split(',')
            if key == 'curvList':
                self._l_curv            = value.split(',')
                self._curvList          = value


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
        
        for str_subj in self._l_subject:
            self._log('Checking on subjectDir <%s>' % str_subj,
                        debug=9, lw=self._lw)
            if os.path.isdir(str_subj):
                self._log('[ ok ]\n', debug=9, rw=self._rw, syslog=False)
            else:
                self._log('[ not found ]\n', debug=9, rw=self._rw,
                            syslog=False)
                error.fatal(self, 'subjectDirnotExist')
            

                
    def run(self):
        '''
        The main 'engine' of the class.

        '''
        base.FNNDSC.run(self)
            
            
def synopsis(ab_shortOnly = False):
    shortSynopsis =  '''
    SYNOPSIS

            %s                                            \\
                            [--stages <stages>]             \\
                            [-v|--verbosity <verboseLevel>] \\
                            [--host <remoteHost>]           \\
                            [--hemi|-h <hemisphere>]            \\
                            [--surface|-f <surface>]            \\
                            [--curv|-c <curvType>               \\
                            [--cluster|-l <cluster>]            \\
                            [--queue |-q <queue>]               \\
                            [--partitions|-p <numberOfSurfacePartitions>] \\
                            <Subj1> <Subj2> ... <SubjN>
    ''' % scriptName
  
    description =  '''
    DESCRIPTION

        `%s' is a meta-controller for setting up and analyzing a set of 
        HBWM experiments. Its main purpose is to stagger a set of cluster
        jobs so as to not overwhelm the scheduler. For a single subject, a
        full run of 100 partitions on all surfaces, hemispheres, and curvature
        values is:

            parts x hemi x surface x curv
              101 x   2  x    2    x  8     = 3232

        This script will loop over each subject, hemi, surface, and argument
        scheduling sub-batches of these at a time.

    ARGS

        --host <remoteHost>
        If specified, schedule jobs to only run on <remoteHost>. This has the
        result of "confining" all jobs to only one node.

        --reset
        If specified, remove the output directory tree.

        --hemi <hemisphere>
        The hemisphere to process. For both 'left' and 'right', pass
        'lh,rh'.

        --surface <surface>
        The surface to process. One of 'pial' or 'smoothwm'.

        --curv <curvType> (default: '%s')
        The curvature map function to use in constructing the worldmap.

        --partitions <numberOfSurfacePartitions> (default: '%d')
        The number of spawned parallel instances of 'mris_pmake' -- each
        will process a sub-set of the original dataset and recombine once
        complete.

        --cluster <cluster>
        The remote cluster to schedule jobs on. Currenly suported:

            * PICES
            * launchpad
            * erisone

        --queue <queue>
        Name of queue on cluster to use. Cluster-specific.

        --stages|-s <stages>
        The stages of 'hbwm.py' to execute. This is specified in a string, 
        such as '1234' which would imply stages 1, 2, 3, and 4.

        The special keyword 'all' can be used to turn on all stages.


    EXAMPLES


    ''' % (scriptName, _str_curv, _partitions)
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
                      '(hit <ctrl>-c to kill this script).    '

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
    
    parser.add_argument('l_subj',
                        metavar='SUBJECT', nargs='+',
                        help='SubjectIDs to process')
    parser.add_argument('--verbosity', '-v',
                        dest='verbosity',
                        action='store',
                        default=0,
                        help='verbosity level')
    parser.add_argument('--stages', '-s',
                        dest='stages',
                        action='store',
                        default='01',
                        help='analysis stages')
    parser.add_argument('--hemi', '-m',
                        dest='hemi',
                        action='store',
                        default='lh,rh',
                        help='hemisphere to process')
    parser.add_argument('--surface', '-f',
                        dest='surface',
                        action='store',
                        default='smoothwm,pial',
                        help='surface to process')
    parser.add_argument('--reset', '-r',
                        dest='b_reset',
                        action="store_true",
                        default=False)
    parser.add_argument('--host', 
                        dest='host',
                        action='store',
                        default='',
                        help='force jobs to be scheduled to only this host')
    parser.add_argument('--curv', '-c',
                        dest='curv',
                        action='store',
                        default='H',
                        help='curvature map to use for worldmap')
    parser.add_argument('--partitions', '-p',
                        dest='partitions',
                        action='store',
                        default='100',
                        help='number of partitions to split problem into')
    parser.add_argument('--debug', '-d',
                        dest='b_debug',
                        action="store_true",
                        default=False)
    parser.add_argument('--cluster', '-l',
                        dest='cluster',
                        action='store',
                        default='PICES',
                        help='destination cluster to schedule jobs on')
    parser.add_argument('--queue', '-q',
                        dest='queue',
                        action='store',
                        default='',
                        help='default queue to use')
    args = parser.parse_args()

    OSshell = crun.crun()
    OSshell.echo(False)
    OSshell.echoStdOut(False)
    OSshell.detach(False)

    hbwm = FNNDSC_HBWMmeta(
                        subjectList     = args.l_subj,
                        hemiList        = args.hemi,
                        surfaceList     = args.surface,
                        curvList        = args.curv,
                        logTo           = 'HBWMmeta.log',
                        syslog          = True,
                        logTee          = True
                        )

    hbwm.verbosity(args.verbosity)
    pipeline    = hbwm.pipeline()
    pipeline.poststdout(True)
    pipeline.poststderr(True)

    stage0 = stage.Stage(
                        name            = 'HBWMmeta',
                        fatalConditions = True,
                        syslog          = True,
                        logTo           = 'HBWMmeta-process.log',
                        logTee          = True,
                        )
    def f_stage0callback(**kwargs):
        lst_subj        = []
        for key, val in kwargs.iteritems():
            if key == 'subj':   lst_subj        = val
            if key == 'obj':    stage           = val
            if key == 'pipe':   pipeline        = val
        lst_hemi        = pipeline.l_hemisphere()
        lst_surface     = pipeline.l_surface()
        lst_curv        = pipeline.l_curv()

        if int(args.partitions) > _maxPartitions:
            error.fatal(hbwm, 'Partition')

        for pipeline._str_subj in lst_subj:
            for pipeline._str_hemi in lst_hemi:
                for pipeline._str_surface in lst_surface:
                    for pipeline._str_curv in lst_curv:
                        log = stage.log()
                        log('Processing %s: %s.%s, %s...\n' % \
                            (pipeline.subj(), pipeline.hemi(), pipeline.surface(), pipeline.curv()))
                        str_hostOnlySpec = ''
                        if len(args.host):
                            str_hostOnlySpec = "--host %s " % args.host
                            log('Locking jobs to only run on host -->%s<--\n' % args.host)
                        str_debug = ""
                        if args.b_debug: str_debug = " --debug "
                        str_queue = ""
                        if args.queue: str_queue = " --queue %s " % args.queue
                        str_cmd = "hbwm.py -v 10 -s %s %s -r -m %s -f %s -c %s -p %s --cluster %s %s %s %s" % \
                            (args.stages, str_hostOnlySpec,
                            pipeline.hemi(), pipeline.surface(), pipeline.curv(), args.partitions,
                            args.cluster, str_debug, str_queue, pipeline.subj())
                        print str_cmd
                        shell = crun.crun()
                        shell.echo(False)
                        shell.echoStdOut(False)
                        shell.detach(False)
                        shell(str_cmd, waitForChild=True, stdoutflush=True, stderrflush=True)
                        if shell.exitCode():
                            error.fatal(hbwm, 'stageExec', shell.stderr())
        os.chdir(pipeline.startDir())
        return True

    stage0.def_stage(f_stage0callback, subj=args.l_subj, obj=stage0, pipe=hbwm)
    stage0.def_postconditions(f_blockOnScheduledJobs, obj=stage0,
                              blockProcess    = 'hbwm.py')

    hbwmlog = hbwm.log()
    hbwmlog('INIT: (%s) %s %s\n' % (os.getcwd(), scriptName, ' '.join(sys.argv[1:])))
    hbwm.stage_add(stage0)
    hbwm.initialize()

    hbwm.run()
  
