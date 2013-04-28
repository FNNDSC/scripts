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
            'exitCode'      : 20},
        'noClusterSpec'     : {
            'action'        : 'checking command line args, ',
            'error'         : 'it seems that an invalid cluster destination was specified.',
            'exitCode'      : 100},
        'remoteTimeOut'     : {
            'action'        : 'waiting on the results of a remote command, ',
            'error'         : 'it seems that the command is taking too long!',
            'exitCode'      : 110}
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
        '''
        This is typically the actual subject name that is processed
        in a loop.
        '''
        return self._str_subj

    def subjectsDir(self, *args):
        '''
        This is the FreeSurfer SUBJECTS_DIR, i.e. a directory
        containing many subjects.
        '''
        if len(args):
            self._str_subjectsDir = args[0]
        else:
            return self._str_subjectsDir

    def subjectDir(self):
        '''
        This is a specific subject directory, i.e. the subject
        within the larger SUBJECTS_DIR.
        '''
        return "%s/%s" % (self._str_subjectsDir, self._str_subj)        

    def surface(self):
        return self._str_surface

    def hemi(self):
        return self._str_hemi

    def curv(self):
        return self._str_curv
        
    def analysisDir(self):
        return "%s/%s/%s/%s/%s" % \
            (self.subjectDir(), 
            _str_HBWMdir, 
            self._str_hemi, self._str_surface, self._str_curv)

    def localDir_remap2projectDir(self, astr_localDirSpec):
        '''
        Remaps the <astr_localDirSpec> to a cleaner name based off the 
        internal self._str_baseProjectsDir. This self._str_baseProjectsDir
        is the common connection point between the local and remote (cluster)
        file systems.

        This method is necessary since the actual "real" dir spec can
        be quite convoluted, particularly if the "logical" dir spec has
        multiple symbolic links. In fact, the "real" dir spec itself
        can be missing the actual self._str_baseProjectsDir due to
        excessive symbolic linking.

        PRECONDITIONS:
        o <astr_localDirSpec> is a "real" dir spec on the local filesystem.

        POSTCONDITIONS
        o Returns the <astr_localDirSpec> explicitly remaped such that 
          it contains the self._str_baseProjectsDir, i.e. "real" path like

            /net/pretoria/local_mount/space/pretoria/2/chb/users/dicom/postproc/projects/rudolphpienaar/dyslexia-curv-analysis-2/results/1-exp-dyslexia-run

          is mapped to

            /chb/users/rudolphpienaar/chb-projects/rudolphpienaar/dyslexia-curv-analysis-2/results/1-exp-dyslexia-run
          
        '''
        l_local = astr_localDirSpec.split('/')
        str_2projectDir = astr_localDirSpec
        self._str_baseProjectsDir = os.path.expanduser(self._str_baseProjectsDir)
        for tetherPoint in range(1, len(l_local)):
            l_tree              = l_local[tetherPoint:]
            str_tree            = '/'.join(l_tree)
            str_cleanCandidate  = self._str_baseProjectsDir + '/' + str_tree
            if os.path.isdir(str_cleanCandidate):
                str_2projectDir = str_cleanCandidate
                break
        return str_2projectDir
        

    def local2remoteUserHomeDir(self, astr_localDirSpec):
        '''
        This method simply maps an <astr_localDirSpec> to the corresponding
        location on the remote filesystem.

        Since an operational assumption of this system is that working
        directories are identical between local and remote systems, differing
        only in the possible spec of the local and remote user home directory,
        this method maps a fully qualified local directory to the remote
        space.
        
        PRECONDITIONS
        o Valid self.remoteShell()
        o Calls self.localDir_remap2projectDir()

        POSTCONDITIONS
        o The "home" component of <astr_localDirSpec> is mapped to the
          corresponding "home" component of the remote directory space.
        '''

        astr_localDirSpec = self.localDir_remap2projectDir(astr_localDirSpec)
        self.remoteShell('cd ~/ ; pwd')
        str_remoteHome  = self.remoteShell.stdout().strip()
        # Another failsafe. If the <str_remoteHome> does not resolve, odds
        # are that the remoteShell is in fact a local shell. In that case
        # try the local OSshell...
        if not len(str_remoteHome):
            OSshell('cd ~/ ; pwd')
            str_remoteHome = OSshell.stdout().strip()
        OSshell('whoami')
        str_whoami = OSshell.stdout().strip()
        self._str_baseProjectsDir = os.path.expanduser(self._str_baseProjectsDir)
        l_dir = astr_localDirSpec.split(str_whoami)
        str_workingDir          = str_whoami.join(l_dir[1:])
        str_remoteDirSpec       = str_remoteHome + str_workingDir
        return str_remoteDirSpec

    def surfDir(self):
        return "%s/surf" % (self.subjectDir())
            
    def startDir(self):
        return self._str_workingDir

    def pid(self):
        return self._str_pid

    def hostname(self):
        return self._str_hostname
        
    def __init__(self, **kwargs):
        '''
        Basic constructor. Checks on named input args, checks that files
        exist and creates directories.

        '''
        base.FNNDSC.__init__(self, **kwargs)

        self._lw                        = 60
        self._rw                        = 20

        self._str_pid                   = os.getpid()
        self._str_hostname              = os.uname()[1]

        # This "remote" shell provides the access point from the pipelin
        # to running commands on the remote system.
        self.remoteShell                = None

        # This directory is the "nexus" point that is preserved between local
        # and remote filesystems.
        self._str_baseProjectsDir       = '~/chb-projects'
        
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

        OSshell('cd %s' % self._str_baseProjectsDir)
        self._str_workingDir            = os.getcwd()
        self._str_workingDir            = self.localDir_remap2projectDir(self._str_workingDir)
        
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

        # Set the stages
        self._pipeline.stages_canRun(False)
        lst_stages = list(self._stageslist)
        for index in lst_stages:
            stage = self._pipeline.stage_get(int(index))
            stage.canRun(True)
            
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


    def waitForRemoteFile(self, **kwargs):
        '''
        An alterative "blocking" function that does not consult
        the remote HPC cluster, but checks on the appearance of
        a file on the remote filesystem.

        This assumes, of course, that the operation we're waiting
        on creates the target output file as final result.
        '''
        intervalSecs        = 5
        timeOutTotal        = 60
        totalTime           = 0
        for key,val in kwargs.iteritems():
            if key == 'shell':          remoteShell             = val
            if key == 'fileToWatch':    str_fileToWatch         = val
            if key == 'intervalSec':    intervalSecs            = val
            if key == 'timeOutTotal':   timeOutTotal            = val

        while totalTime < timeOutTotal:
            remoteShell('if [[ -s %s ]] ; then echo "1" ; else echo "0"; fi' % str_fileToWatch)
            #print("Checking for %s... result: %s" % (str_fileToWatch, remoteShell.stdout().strip()))
            if remoteShell.stdout().strip() == "1": break
            time.sleep(intervalSecs)
            totalTime += intervalSecs
        if totalTime >= timeOutTotal:
            error.fatal(self, 'remoteTimeOut')

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
                b_jobDetach         = False
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
            if case() or case('local'):
                # In this case, a "local" shell will be created. Note that a
                # "local" shell might break other logic if the caller
                # is explicitly expecting a cluster and scheduler-
                # infrastructure.
                # 
                # This default case is a failsafe fallback.
                stage.shell(crun.crun())
                b_jobDetach         = False
                b_disassocaite      = False
                b_waitForChild      = True
        shell = stage.shell()
        shell.emailWhenDone(True)
        if args.b_debug:
            shell.echo(True)
            shell.echoStdOut(True)
        else:
            shell.echo(False)
            shell.echoStdOut(False)
        shell.detach(b_jobDetach)
        shell.disassociate(b_disassocaite)
        shell.waitForChild(b_waitForChild)
        # This "remoteShell" is used to access the cluster node directly
        # and without using the scheduler. It is used to run remote
        # shell commands and return stdout type outputs to this parent
        # controller embedded in a particular stage. In the case of
        # a "local" shell spec, this remoteShell will in fact be
        # a local shell running on the localhost.
        if(astr_remoteHPC == 'local'):
            self.remoteShell = crun.crun()
        else:
            self.remoteShell = crun.crun(remoteHost=shell._str_remoteHost,\
                                         remoteUser=shell._str_remoteUser,\
                                         remotePort=shell._str_remotePort)
        if args.b_debug:
            self.remoteShell.echo(True)
            self.remoteShell.echoStdOut(True)
        else:
            self.remoteShell.echo(False)
            self.remoteShell.echoStdOut(False)
        

### Non-class methods
            
def synopsis(ab_shortOnly = False):
    shortSynopsis =  '''
    SYNOPSIS

            %s                                      \\
                            [--stages|-s <stages>]                 \\
                            [--verbosity|-v <verboseLevel>]     \\
                            [--host <remoteHost>]               \\
                            [--reset|-r]                        \\
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

        `%s' performs an 'mris_pmake' autodijk-worldmap analysis on
        passed subjects. Due to the inherent parallelism of the worldmap
        creation, this script partitions an autodijk process into
        multiple sub-problems.
        
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
        The remote cluster to schedule jobs on. Currenly supported:

            * PICES
            * launchpad
            * erisone

        --queue <queue>
        Name of queue on cluster to use. Cluster-specific.
      
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
    parser.add_argument('--host',
                        dest='host',
                        action='store',
                        default='',
                        help='force jobs to be scheduled to only this host')
    parser.add_argument('--reset', '-r',
                        dest='b_reset',
                        action="store_true",
                        default=False)
    parser.add_argument('--debug', '-d',
                        dest='b_debug',
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
    pipe_HBWM.subjectsDir(pipe_HBWM._str_workingDir)
    pipeline    = pipe_HBWM.pipeline()
    pipeline.log()('INIT: (%s) %s %s\n' % (os.getcwd(), scriptName, ' '.join(sys.argv[1:])))
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
    # This stage is also a somewhat contrived example of remote HPC
    # processing -- the 'mris_info' call is actually scheduled and
    # executed on the remote HPC. This stage demonstrates how to
    # block-on-wait in a general way across three different clustering
    # schemes.
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
        log             = stage.log()

        # First, create stage shell for scheduling/executing on the remote HPC
        # This *must* be called here, since downstream processing in this stage
        # depends on a working remoteShell.
        # 
        # The 'PICES' backend cluster is fored here since scheduling delays
        # on the Partners clusters can result in timeouts.
        pipeline.stageShell_createRemoteInstance('PICES', stage=stage)

        # This assumes that the script is started from the toplevel
        # FreeSurfer SUBJECTS_DIR on the local filesystem, i.e. the 
        # self._str_workingDir is teh SUBJECTS_DIR
        pipeline.subjectsDir(pipeline._str_workingDir)

        # Get the "scheduler shell" embedded within this stage
        # This shell will schedule any commands passed to it on the specific
        # HPC scheduler that has been instantiated. 
        shell = stage.shell()
        if len(args.host):
            str_hostOnlySpec = "--host %s " % args.host
            log('Locking jobs to only run on host -->%s<--\n' % args.host)
            shell.scheduleHostOnly(args.host)
        shell.detach(False)                 # This shell should not detach
        shell.disassociate(False)           # nor disassociate, irrespective
                                            # of how it was constructed. 
                                            # Some HPC cruns, like MOSIX
                                            # force disassociate. For this
                                            # stage, we actually want to 
                                            # "block" on the remote 
                                            # schedule process.
                                            
        os.chdir(pipeline.subjectsDir())
        for pipeline._str_subj in lst_subj:
            os.chdir(pipeline.subjectDir())
            misc.mkdir(_str_HBWMdir)
            for pipeline._str_hemi in lst_hemi:
                for pipeline._str_surface in lst_surface:
                    str_surfaceFile = '%s.%s' % (pipeline.hemi(), pipeline.surface())
                    str_surfDir = 'surf'

                    # Get the remote user homedir
                    pipeline.remoteShell('pwd')
                    str_remoteHome = pipeline.remoteShell.stdout().strip()

                    # Set some FS components in the core HPC scheduler object
                    shell.FreeSurferUse(True)
                    shell.FSsubjDir(localSubjDir=pipeline.subjectsDir(),
                                    remoteHome=str_remoteHome)
                    str_jobID           = '%s-%s-%s-%s' % \
                            (pipeline.hemi(), pipeline.surface(),
                             pipeline.hostname(), pipeline.pid())
                    str_shellstderr     = '%s/%s.err' % (shell.jobInfoDir(), str_jobID)
                    str_shellstdout     = '%s/%s.out' % (shell.jobInfoDir(), str_jobID)
                                    
                    shell.jobID(str_jobID)
                    shell.schedulerStdOut(str_shellstdout)
                    shell.schedulerStdErr(str_shellstderr)

                    log('Processing %s: %s...\n' % (pipeline.subj(), str_surfaceFile))
                    log('Checking on number of vertices... ')

                    str_cmd = " mris_info %s/%s/%s/%s " % \
                        (shell.FSsubjDir(), pipeline.subj(), str_surfDir, str_surfaceFile)


                    # And execute the remote call. Depending on the remote HPC, the
                    # waitForChild may or may not be fully honored -- this depends
                    # on whether the scheduler blocks-or-not when called.
                    shell(str_cmd,
                            waitForChild=shell.waitForChild(),
                            stdoutflush=False, stderrflush=False)

                    # In many cluster schedulers, scheduled jobs do *not* write
                    # to stdout, which is why the above command was scheduled
                    # with output to an str_shellstdout file. In some cases 
                    # (such as the erisone LSF), output redirection is not 
                    # supported at the command line and all output stdout
                    # and stderr must be explicitly defined.
                    # 
                    # Irrespective of the mechanism, output needs to be
                    # captured in a file and we need to block on the creation 
                    # (and non-zero) size of this file and then parse it. The
                    # blocking is required since since some schedulers are fire
                    # and forget -- once sent to the scheduler, this controller
                    # loses in many cases the direct ability to know when the 
                    # job is complete, other than some side effect of its
                    # completion (such as creating some output file).
                    # 
                    # Note that the *correct* approach is to use the 
                    # f_blockOnScheduledJobs() function that will query the
                    # scheduler and block until jobs are complete. The
                    # following is per illustration only.
                    # 
                    # Here, we shell into the remote filesystem and check for the
                    # existence of the str_shellstdout file. The looping/blocking
                    # is done in this controller, not remotely. A remote block 
                    # such as
                    # 
                    #   remoteShell('while [ ! -f %s ] ; do : ; done' % str_shellstdout)
                    #   
                    # runs the risk of becoming orphaned on the remote processor
                    # and sucking up CPU cycles.
                    #
                    pipeline.waitForRemoteFile(
                                        shell           = pipeline.remoteShell,
                                        fileToWatch     = str_shellstdout,
                                        interval        = 5,
                                        timeOutTotal    = 70
                                        )
                                       
                    pipeline.remoteShell('cat %s | grep nvertices' % str_shellstdout)
                    l_nvertices = pipeline.remoteShell.stdout().strip().split()
                    pipeline.remoteShell('rm -f %s %s' % (str_shellstdout, str_shellstderr))
                    str_nvertices = l_nvertices[1]
                    # Subtrack 1 from the number of vertices since indices start from 0.
                    nvertices = int(str_nvertices) - 1

                    # This block removes and builds the directory tree that will contain
                    # intermediate outputs of the distributed processing.
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
        log             = stage.log()

        # First, create stage shell for scheduling/executing on the remote HPC
        # This *must* be called here, since downstream processing in this stage
        # depends on a working remoteShell.
        pipeline.stageShell_createRemoteInstance(args.cluster, stage=stage)

        # This assumes that the script is started from the toplevel
        # FreeSurfer SUBJECTS_DIR on the local filesystem, i.e. the
        # self._str_workingDir is teh SUBJECTS_DIR
        pipeline.subjectsDir(pipeline._str_workingDir)

        # Get the "scheduler shell" embedded within this stage
        # This shell will schedule any commands passed to it on the specific
        # HPC scheduler that has been instantiated.
        cluster = stage.shell()
        if len(args.host):
            str_hostOnlySpec = "--host %s " % args.host
            log('Locking jobs to only run on host -->%s<--\n' % args.host)
            cluster.scheduleHostOnly(args.host)
        cluster.priority(60)

        # Get the remote user homedir
        pipeline.remoteShell('pwd')
        str_remoteHome = pipeline.remoteShell.stdout().strip()

        # Set some FS components in the core HPC scheduler object
        cluster.FreeSurferUse(True)
        cluster.FSsubjDir(localSubjDir=pipeline.subjectsDir(),
                        remoteHome=str_remoteHome)

        os.chdir(pipeline.subjectsDir())
        for pipeline._str_subj in lst_subj:
            os.chdir(pipeline.subjectDir())
            for pipeline._str_hemi in lst_hemi:
                for pipeline._str_surface in lst_surface:
                    for pipeline._str_curv in lst_curv:
                        os.chdir(pipeline.analysisDir())
                        # Now, for each sub directory conforming to pattern:
                        #                   <hemi>-<surface>-*
                        # schedule analysis
                        l_dir = glob.glob('%s-%s-%s-*' % \
                            (pipeline.hemi(), pipeline.surface(), pipeline.curv()))
                        for subpart in l_dir:
                            os.chdir(subpart)
                            str_localAnalysisDir = "%s/%s" % (pipeline.analysisDir(), subpart)
                            # Note that the local2remote translations results in a 'pwd'
                            # call to the remote system.
                            str_remoteDirSpec = \
                                pipeline.local2remoteUserHomeDir(str_localAnalysisDir)
                            # Copy the relevant curvature file to this local directory
                            str_curvatureBaseFile   = '%s.%s.%s.crv' % \
                                (pipeline.hemi(), pipeline.surface(), pipeline.curv())
                            str_curvFilePath        = '%s/%s' % \
                                (pipeline.surfDir(), str_curvatureBaseFile)
                            if os.path.lexists(str_curvatureBaseFile):
                                os.remove(str_curvatureBaseFile)
                            shutil.copyfile(str_curvFilePath, str_curvatureBaseFile)

                            # Read the vertex start and end indices
                            file_vstart     = open('vstart', 'r')
                            str_vstart      = file_vstart.readline().strip()
                            file_vstart.close()
                            file_vend       = open('vend', 'r')
                            str_vend        = file_vend.readline().strip()
                            file_vend.close()

                            str_jobID           = '%s-%s-%s-%s-%s-%s' % \
                                (pipeline.subj(), pipeline.hemi(),
                                pipeline.surface(), pipeline.curv(),
                                str_vstart, str_vend)
                            str_shellstderr     = '%s/%s.err' % \
                                (cluster.jobInfoDir(), str_jobID)
                            str_shellstdout     = '%s/%s.out' % \
                                (cluster.jobInfoDir(), str_jobID)
                                            
                            cluster.jobID(str_jobID)
                            cluster.schedulerStdOut(str_shellstdout)
                            cluster.schedulerStdErr(str_shellstderr)
                            if len(args.queue):
                                cluster.queueName(args.queue)

                            log('Scheduling %s-%s-%s-%s-%s-%s...\n' % \
                                (pipeline.subj(), pipeline.hemi(), pipeline.surface(), pipeline.curv(),
                                str_vstart, str_vend))
                            cluster.workingDir(str_remoteDirSpec)
                            str_cmd = 'mris_pmake --port %d --subj %s --hemi %s \
                            --surface %s \
                            --mpmProg autodijk \
                            --mpmArgs vertexStart:%d,vertexEnd:%d,worldMapCreate:1,costCurvStem:%s \
                            --mpmOverlay curvature --mpmOverlayArgs primaryCurvature:./%s' % \
                                        (pmakePort,
                                        pipeline.subj(), pipeline.hemi(), pipeline.surface(),
                                        int(str_vstart), int(str_vend), pipeline.curv(),
                                        str_curvatureBaseFile)
                            cluster(
                                str_cmd, waitForChild=cluster.waitForChild(), 
                                stdoutflush=True, stderrflush=True
                            )
                            pmakePort += 1
                            os.chdir(pipeline.analysisDir())
        os.chdir(pipeline.startDir())
        return True
    stage1.def_stage(f_stage1callback, subj=args.l_subj, obj=stage1, pipe=pipe_HBWM)
    stage1.def_postconditions(f_blockOnScheduledJobs, obj=stage1,
                              blockProcess    = 'mris_pmake')
    
    #
    # Stage 2
    # 
    # Combine all the sub-partition solutions into one, using
    # 'mris_calc.py'. Since 'mris_calc.py' assumes a rather
    # complete Python installation, this stage is locked to
    # run off PICES irrespective of where the main clustering 
    # might have been specified.
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
        log             = stage.log()
        
        # First, create stage shell for scheduling/executing on the remote HPC
        # This *must* be called here, since downstream processing in this stage
        # depends on a working remoteShell.
        pipeline.stageShell_createRemoteInstance('PICES', stage=stage)
        cluster = stage.shell()

        # The "remoteShell" is also created by the above call, however this
        # shell does not schedule its commands in the scheduler. Rather it 
        # simply runs them directly on the remote host (typically the head
        # node of the cluster).
        remoteShell = pipeline.remoteShell
        remoteShell('cd ~/ ; pwd')
        str_remoteHome = remoteShell.stdout().strip()

        # Set some FS components in the core HPC scheduler object
        # Also, copy the "cluster" FS setup to the non-scheduler
        # remoteShell
        remoteShell.FreeSurferUse(True)
        remoteShell.FSinit(**cluster.FSinit())
        remoteShell.FSsubjDir(localSubjDir=pipeline.subjectsDir(),
                        remoteHome=str_remoteHome)
        remoteShell.sourceEnv(True)

        for pipeline._str_subj in lst_subj:
            os.chdir(pipeline.subjectsDir())
            for pipeline._str_hemi in lst_hemi:
                for pipeline._str_surface in lst_surface:
                    for pipeline._str_curv in lst_curv:
                        os.chdir(pipeline.analysisDir())
                        str_recomDir        = '%s-%s-%s' % \
                            (pipeline.hemi(), pipeline.surface(), pipeline.curv())
                        misc.mkdir(str_recomDir)
                        os.chdir(str_recomDir)
                        remoteShell.workingDir("%s/%s" % \
                            (pipeline.local2remoteUserHomeDir(pipeline.analysisDir()), str_recomDir))
                        str_autodijkFile = '%s.%s.autodijk-%s.crv' % \
                                    (pipeline.hemi(), pipeline.surface(), pipeline.curv())
                        str_cmd = "mris_calc.py -v 10 \
                                    --operation add $(find ../ -iname %s | grep [0-9] | tr '\n' ' ')" % \
                                    (str_autodijkFile)
                        remoteShell(str_cmd, waitForChild=True, stdoutflush=True, stderrflush=True)
                        if remoteShell.exitCode():
                            error.fatal(pipe_HBWM, 'stageExec', remoteShell.stderr())
                        remoteShell('cp %s %s/surf' % (str_autodijkFile, pipeline.subjectDir()))
                        if remoteShell.exitCode():
                            error.fatal(pipe_HBWM, 'stageExec', remoteShell.stderr())
        os.chdir(pipeline.startDir())
        return True
    stage2.def_stage(f_stage2callback, subj=args.l_subj, obj=stage2, pipe=pipe_HBWM)
    #stage2.def_postconditions(f_blockOnScheduledJobs, obj=stage2,
                              #blockProcess    = 'mris_calc.py')


    #
    # Stage 3
    # 
    # Runs mris_calc on final re-combined files to normalize and shift final 
    # values.
    #
    stage3 = stage.Stage(
                        name            = 'normalize-sign',
                        fatalConditions = True,
                        syslog          = True,
                        logTo           = 'HBWM-normalize-sign.log',
                        logTee          = True
                        )
    def f_stage3callback(**kwargs):
        lst_subj        = []
        for key, val in kwargs.iteritems():
            if key == 'subj':   lst_subj        = val
            if key == 'obj':    stage           = val
            if key == 'pipe':   pipeline        = val
        lst_hemi        = pipeline.l_hemisphere()
        lst_surface     = pipeline.l_surface()
        lst_curv        = pipeline.l_curv()
        log             = stage.log()

        # First, create stage shell for scheduling/executing on the remote HPC
        # This *must* be called here, since downstream processing in this stage
        # depends on a working remoteShell.
        pipeline.stageShell_createRemoteInstance(args.cluster, stage=stage)
        cluster = stage.shell()

        # The "remoteShell" is also created by the above call, however this
        # shell does not schedule its commands in the scheduler. Rather it
        # simply runs them directly on the remote host (typically the head
        # node of the cluster).
        remoteShell = pipeline.remoteShell
        remoteShell('pwd')
        str_remoteHome = remoteShell.stdout().strip()

        # Set some FS components in the core HPC scheduler object
        # Also, copy the "cluster" FS setup to the non-scheduler
        # remoteShell
        remoteShell.FreeSurferUse(True)
        remoteShell.FSinit(**cluster.FSinit())
        remoteShell.FSsubjDir(localSubjDir=pipeline.subjectsDir(),
                        remoteHome=str_remoteHome)
        remoteShell.sourceEnv(True)

        for pipeline._str_subj in lst_subj:
            os.chdir(pipeline.subjectsDir())
            for pipeline._str_hemi in lst_hemi:
                for pipeline._str_surface in lst_surface:
                    for pipeline._str_curv in lst_curv:
                        os.chdir(pipeline.analysisDir())
                        str_autodijkFile = '%s.%s.autodijk-%s.crv' % \
                                    (pipeline.hemi(), pipeline.surface(), pipeline.curv())
                        str_autonormFile = '%s.%s.an-%s.crv' % \
                                    (pipeline.hemi(), pipeline.surface(), pipeline.curv())
                        str_autonsFile   = '%s.%s.ans-%s.crv' % \
                                    (pipeline.hemi(), pipeline.surface(), pipeline.curv())
                        os.chdir(pipeline.surfDir())
                        remoteShell.workingDir(pipeline.local2remoteUserHomeDir(pipeline.surfDir()))
                        log('Normalizing and shifting %s\n' % str_autodijkFile)
                        str_cmd = "\
                            mris_calc -o %s %s norm     ;\
                            mris_calc -o %s %s sub 0.5  ;\
                            chmod o+r %s %s %s\
                        " % (str_autonormFile, str_autodijkFile,
                             str_autonsFile, str_autonormFile,
                             str_autodijkFile, str_autonsFile, str_autonormFile)
                        remoteShell(str_cmd, waitForChild=True, stdoutflush=True, stderrflush=True)
                        if remoteShell.exitCode():
                            error.fatal(pipe_HBWM, 'stageExec', remoteShell.stderr())
        os.chdir(pipeline.startDir())
        return True
    stage3.def_stage(f_stage3callback, subj=args.l_subj, obj=stage3, pipe=pipe_HBWM)
    #stage3.def_postconditions(f_blockOnScheduledJobs, obj=stage3,
                              #blockProcess    = 'mris_calc')

    
    # Add all the stages to the pipeline  
    pipe_HBWM.stage_add(stage0)
    pipe_HBWM.stage_add(stage1)
    pipe_HBWM.stage_add(stage2)
    pipe_HBWM.stage_add(stage3)
    #pipe_HBWM.stage_add(stage4)

    # Initialize the pipeline and ... run!
    pipe_HBWM.initialize()
    pipe_HBWM.run()
  
