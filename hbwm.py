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

_str_curv       = 'H'
_partitions     = 100

_str_HBWMdir    = 'HBWM'

scriptName      = os.path.basename(sys.argv[0])

class FNNDSC_HBWM(base.FNNDSC):
    '''
    This class is a specialization of the FNNDSC base and generates
    MOSIX cluster scheduled runs of a B0/ADC/ASL analysis.
    
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
        'subjectDirnotExist': {
            'action'        : 'examining the <subjectDirectories>, ',
            'error'         : 'the directory does not exist.',
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
        self._stageslist                = '12'
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
            if key == 'curvList':       self._l_curv            = value.split(',')

        self._d_partRootDir             = misc.dict_init(self._l_subject)
        self._d_vertices                = misc.dict_init(self._l_subject)
        for subj in self._l_subject:
            self._d_vertices[subj]      = misc.dict_init(self._l_hemi)
            self._d_partRootDir[subj]   = misc.dict_init(self._l_hemi)
            for hemi in self._l_hemi:
                self._d_partRootDir[subj][hemi] = misc.dict_init(self._l_surface)
                self._d_vertices[subj][hemi] = misc.dict_init(self._l_surface)
                for surf in self._l_surface:
                    self._d_partRootDir[subj][hemi][surf] = misc.dict_init(self._l_curv)
                    

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
            

### Non-class methods
            
def synopsis(ab_shortOnly = False):
    shortSynopsis =  '''
    SYNOPSIS

            %s                                      \\
                            [--stages|-s <stages>]                 \\
                            [--verbosity|-v <verboseLevel>]     \\
                            [--reset|-r]                        \\
                            [--hemi|-h <hemisphere>]            \\
                            [--surface|-f <surface>]            \\
                            [--curv|-c <curvType>               \\
                            [--partitions|-p <numberOfSurfacePartitions>] \\
                            <Subj1> <Subj2> ... <SubjN>
    ''' % scriptName
  
    description =  '''
    DESCRIPTION

        `%s' performs an 'mris_pmake' autodijk-worldmap analysis on
        passed subjects. Due to the inherent parallelism of the worldmap
        creation, this script partitions an autodijk process into
        multiple sub-problems.
        
    ARGS

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
      
        --stages|-s <stages>
        The stages to execute. This is specified in a string, such as '1234'
        which would imply stages 1, 2, 3, and 4.

        The special keyword 'all' can be used to turn on all stages.

        <Subj1> <Subj2> ... <SubjN>
        The subject list to process.

    STAGES

      foreach(subject):
        foreach(hemi):
           foreach(surface):
              foreach(curv):
                o 1 - split: break the problem into <numberOfSurfacePartitions>
                            subsets
                o 2 - process: for each partition, process a subset
                o 3 - recombine: recombine all the sub-solutions into one.
        
    PRECONDITIONS
    
    POSTCONDITIONS
    
    EXAMPLES

        $>hbwm.py --curv H --hemi lh --surface smoothwm --partitions 100 \
                subj1 subj2 subj3

        In this case subjects 'subj1', 'subj2', and 'subj3' will be processed 
        for an 'H' worldmap on the lh smoothwm base H surface. In each subject
        directory, a new sub-dir 'autodijk' will be created, containing a set of 
        sub-dirs for the passed hemisphere and partition.

        The final results will be contained in autodijk/final-<hemi>-<surface>
        

    ''' % (scriptName, _str_curv, _partitions)
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
                      '(hit <ctrl>-c to kill this script).    '
                        
    stage.blockOnShellCmd(  str_blockCondition, str_blockUntil,
                            str_blockMsg, str_loopMsg, timepoll)
    return True

def dirPart_create(str_dirPart):
    '''
    Create the partition sub-directory and store the <vstart> and <vend> vertex indices
    in two files in the <str_dirPart> directory
    '''
    misc.mkdir(str_dirPart)
    lst_specs   = str_dirPart.split('-')
    str_hemi    = lst_specs[0]
    str_surface = lst_specs[1]
    str_curv    = lst_specs[2]
    str_vstart  = lst_specs[3]
    str_vend    = lst_specs[4]
    file_vstart = open('%s/vstart' % str_dirPart, 'w')
    file_vstart.write('%s\n' %          str_vstart)
    file_vend   = open('%s/vend' % str_dirPart, 'w')
    file_vend.write('%s\n' %            str_vend)
    file_hemi   = open('%s/hemi' % str_dirPart, 'w')
    file_hemi.write('%s\n' %            str_hemi)
    file_surface= open('%s/surface' % str_dirPart, 'w')
    file_surface.write('%s\n' %         str_surface)
    file_hemi.close()
    file_surface.close()
    file_vstart.close()
    file_vend.close()

        
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
    args = parser.parse_args()

    
    # A generic "shell"
    OSshell = crun.crun()
    OSshell.echo(False)
    OSshell.echoStdOut(False)
    OSshell.detach(False)

    
    # First, define the container pipeline
    pipe_HBWM = FNNDSC_HBWM(
                        subjectList     = args.l_subj,
                        stages          = args.stages,
                        hemiList        = args.hemi,
                        surfaceList     = args.surface,
                        curvList        = args.curv,
                        logTo           = 'HBWM.log',
                        syslog          = True,
                        logTee          = True
                        )
    pipe_HBWM.verbosity(args.verbosity)
    pipeline    = pipe_HBWM.pipeline()
    pipeline.log()('INIT: %s %s\n' % (scriptName, ' '.join(sys.argv[1:])))
    pipeline.name('HBWM')
    pipeline.poststdout(True)
    pipeline.poststderr(True)
    str_cwd         =  os.getcwd()

    # Now define each stage...

    #
    # Stage 0
    # This is a callback stage, demonstrating how python logic is used
    # to create multiple cluster-based processing instances of the same
    # core FreeSurfer command, each with slightly different operating
    # flags.
    # 
    # In some ways, the stage0.def_stage(...) is vaguely reminiscent
    # of javascript, in as much as the f_stage0callback is a 
    # callback function.
    #
    # PRECONDITIONS:
    # o Check that script is running on a cluster node.
    # 
    stage0 = stage.Stage(
                        name            = 'mris_info',
                        fatalConditions = True,
                        syslog          = True,
                        logTo           = 'HBWM-mris_info.log',
                        logTee          = True
                        )
    def f_stage0callback(**kwargs):
        lst_subj        = []
        lst_hemi        = ['lh' , 'rh']
        lst_surface     = ['smoothwm', 'pial']
        for key, val in kwargs.iteritems():
            if key == 'subj':   lst_subj        = val
            if key == 'obj':    stage           = val
            if key == 'pipe':   pipeline        = val
        lst_hemi        = pipeline.l_hemisphere()
        lst_surface     = pipeline.l_surface()
        lst_curv        = pipeline.l_curv()
        
        for pipeline._str_subj in lst_subj:
            os.chdir(pipeline.subjDir())
            misc.mkdir(_str_HBWMdir)
            for pipeline._str_hemi in lst_hemi:
                for pipeline._str_surface in lst_surface:
                    # find the relevant input files in each <subj> dir
                    os.chdir(pipeline.subjDir())
#                        os.chdir(str_cwd); os.chdir(subj)
                    str_surfaceFile = '%s.%s' % (pipeline.hemi(), pipeline.surface())
                    str_surfDir = 'surf'
                    log = stage.log()
                    log('Processing %s: %s...\n' % (pipeline.subj(), str_surfaceFile))
                    log('Checking on number of vertices... ')
                    str_cmd = "mris_info %s/%s 2>/dev/null | grep nvertices | awk '{print $2}'" % \
                        (str_surfDir, str_surfaceFile)
                    shell = crun.crun()
                    shell.echo(False)
                    shell.echoStdOut(False)
                    shell.detach(False)
                    shell(str_cmd, waitForChild=True, stdoutflush=False, stderrflush=False)
                    if shell.exitCode():
                        error.fatal(pipe_HBWM, 'stageExec', shell.stderr())
                    str_nvertices = shell.stdout().strip()
                    # Subtrack 1 from the number of vertices since indices start from 0.
                    nvertices = int(str_nvertices) - 1
                    d_v = pipeline.d_vertices()
                    d_v[pipeline._str_subj][pipeline._str_hemi][pipeline._str_surface] = nvertices
                    log('[ %s ]\n' % str_nvertices, syslog=False)
                    # Now, setup the subdirs to house the sub-partitioning
                    nparts = int(args.partitions)
                    partitionSize = nvertices / nparts
                    rem = nvertices % nparts
                    for pipeline._str_curv in lst_curv:
                        if args.b_reset:
                            log('Removing analysis tree for %s-%s-%s\n' % \
                                (pipeline.hemi(), pipeline.surface(), pipeline.curv()))
                            OSshell('rm -fr %s' % pipeline.analysisDir())
                        log('Building analysis dir for %s-%s-%s\n' % \
                                (pipeline.hemi(), pipeline.surface(), pipeline.curv()))
                        misc.mkdir(pipeline.analysisDir())
                        os.chdir(pipeline.analysisDir())
                        for subpart in range(nparts):
                            vstart  = subpart * partitionSize
                            vend    = vstart + partitionSize - 1
                            str_dirPart = "%s-%s-%s-%06d-%06d" % \
                                (pipeline.hemi(), pipeline.surface(), pipeline.curv(), vstart, vend)
                            dirPart_create(str_dirPart)
                        if rem:
                            vstart  = vend + 1
                            vend    = vstart + rem
                            str_dirPart = "%s-%s-%s-%06d-%06d" % \
                                (pipeline.hemi(), pipeline.surface(), pipeline.curv(), vstart, vend)
                            dirPart_create(str_dirPart)
                        os.chdir(str_cwd)
        os.chdir(pipeline.startDir())
        return True
    stage0.def_stage(f_stage0callback, subj=args.l_subj, obj=stage0, pipe=pipe_HBWM)
    stage0.def_postconditions(f_blockOnScheduledJobs, obj=stage0,
                              blockProcess    = 'mris_info')

    #
    # Stage 1
    # This is a callback stage, demonstrating how python logic is used
    # to create multiple cluster-based processing instances of the same
    # core FreeSurfer command, each with slightly different operating
    # flags.
    #
    stage1 = stage.Stage(
                        name            = 'autodijk',
                        fatalConditions = True,
                        syslog          = True,
                        logTo           = 'HBWM-autodijk.log',
                        logTee          = True
                        )
    def f_stage1callback(**kwargs):
        str_cwd         =  os.getcwd()
        lst_subj        = []
        pmakePort       = 1701
        for key, val in kwargs.iteritems():
            if key == 'subj':   lst_subj        = val
            if key == 'obj':    stage           = val
            if key == 'pipe':   pipeline        = val
        lst_hemi        = pipeline.l_hemisphere()
        lst_surface     = pipeline.l_surface()
        lst_curv        = pipeline.l_curv()
        
        for pipeline._str_subj in lst_subj:
            os.chdir(pipeline.subjDir())
            for pipeline._str_hemi in lst_hemi:
                for pipeline._str_surface in lst_surface:
                    for pipeline._str_curv in lst_curv:
                        os.chdir(pipeline.analysisDir())
                        log = stage.log()
                        # Now, for each sub directory conforming to pattern:
                        #                   <hemi>-<surface>-*
                        # schedule analysis
                        l_dir = glob.glob('%s-%s-%s-*' % \
                            (pipeline.hemi(), pipeline.surface(), pipeline.curv()))
                        for subpart in l_dir:
                            os.chdir(subpart)
                            # Copy the relevant curvature file to this local directory
                            str_curvatureBaseFile   = '%s.%s.%s.crv' % \
                                (pipeline.hemi(), pipeline.surface(), pipeline.curv())
                            str_curvFilePath        = '%s/surf/%s' % (pipeline.subjDir(), str_curvatureBaseFile)
                            if os.path.lexists(str_curvatureBaseFile):
                                os.remove(str_curvatureBaseFile)
                            os.symlink(str_curvFilePath, str_curvatureBaseFile)
                            file_vstart     = open('vstart', 'r')
                            str_vstart      = file_vstart.readline().strip()
                            file_vstart.close()
                            file_vend       = open('vend', 'r')
                            str_vend        = file_vend.readline().strip()
                            file_vend.close()
                            log('Scheduling %s-%s-%s-%s-%s-%s...\n' % \
                                (pipeline.subj(), pipeline.hemi(), pipeline.surface(), pipeline.curv(),
                                str_vstart, str_vend))
                            str_cmd = 'mris_pmake --port %d --subj %s --hemi %s \
                                        --surface %s \
                                        --mpmProg autodijk \
                                        --mpmArgs vertexStart:%d,vertexEnd:%d,worldMapCreate:1,costCurvStem:%s \
                                        --mpmOverlay curvature --mpmOverlayArgs primaryCurvature:./%s' % \
                                        (pmakePort, pipeline.subj(), pipeline.hemi(), pipeline.surface(), 
                                        int(str_vstart), int(str_vend), pipeline.curv(),
                                        str_curvatureBaseFile)
                            cluster = crun.crun_mosix()
                            cluster.echo(False)
                            cluster.echoStdOut()
                            cluster.detach()
                            cluster(str_cmd, waitForChild=False)
                            pmakePort += 1
                            os.chdir(pipeline.analysisDir())
        os.chdir(pipeline.startDir())
        return True
    stage1.def_stage(f_stage1callback, subj=args.l_subj, obj=stage1, pipe=pipe_HBWM)
    stage1.def_postconditions(f_blockOnScheduledJobs, obj=stage1,
                              blockProcess    = 'mris_pmake')
    
    #
    # Stage 2
    # This is a callback stage, demonstrating how python logic is used
    # to create multiple cluster-based processing instances of the same
    # core FreeSurfer command, each with slightly different operating
    # flags.
    #
    stage2 = stage.Stage(
                        name            = 'recombine',
                        fatalConditions = True,
                        syslog          = True,
                        logTo           = 'HBWM-recombine.log',
                        logTee          = True
                        )
    def f_stage2callback(**kwargs):
        lst_subj        = []
        for key, val in kwargs.iteritems():
            if key == 'subj':   lst_subj        = val
            if key == 'obj':    stage           = val
            if key == 'pipe':   pipeline        = val
        lst_hemi        = pipeline.l_hemisphere()
        lst_surface     = pipeline.l_surface()
        lst_curv        = pipeline.l_curv()
        
        for pipeline._str_subj in lst_subj:
            os.chdir(pipeline.subjDir())
            for pipeline._str_hemi in lst_hemi:
                for pipeline._str_surface in lst_surface:
                    for pipeline._str_curv in lst_curv:
                        os.chdir(pipeline.analysisDir())
                        log = stage.log()
                        str_recomDir        = '%s-%s-%s' % \
                            (pipeline.hemi(), pipeline.surface(), pipeline.curv())
                        misc.mkdir(str_recomDir)
                        os.chdir(str_recomDir)
                        str_autodijkFile = '%s.%s.autodijk-%s.crv' % \
                                    (pipeline.hemi(), pipeline.surface(), pipeline.curv())
                        str_cmd = "mris_calc.py -v 10 \
                                    --operation add $(find ../ -iname %s | grep [0-9] | tr '\n' ' ')" % \
                                    (str_autodijkFile)
                        shell = crun.crun()
                        shell.echo(False)
                        shell.echoStdOut(False)
                        shell.detach(False)
                        shell(str_cmd, waitForChild=True, stdoutflush=True, stderrflush=True)
                        if shell.exitCode():
                            error.fatal(pipe_HBWM, 'stageExec', shell.stderr())
                        shell('cp %s %s/surf' % (str_autodijkFile, pipeline.subjDir()))
        os.chdir(pipeline.startDir())
        return True
    stage2.def_stage(f_stage2callback, subj=args.l_subj, obj=stage2, pipe=pipe_HBWM)
    stage2.def_postconditions(f_blockOnScheduledJobs, obj=stage2,
                              blockProcess    = 'mris_calc.py')

    
    # Add all the stages to the pipeline  
    pipe_HBWM.stage_add(stage0)
    pipe_HBWM.stage_add(stage1)
    pipe_HBWM.stage_add(stage2)
    #pipe_HBWM.stage_add(stage3)
    #pipe_HBWM.stage_add(stage4)

    # Initialize the pipeline and ... run!
    pipe_HBWM.initialize()
    pipe_HBWM.run()
  
