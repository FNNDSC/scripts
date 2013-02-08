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

class FNNDSC_ZRS5(base.FNNDSC):
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
            'exitCode'      : 14}
    }

                    
    def __init__(self, **kwargs):
        '''
        Basic constructor. Checks on named input args, checks that files
        exist and creates directories.

        '''
        base.FNNDSC.__init__(self, **kwargs)

        self._lw                        = 120
        self._rw                        = 20
        self._l_subject                 = []
        
        self._str_subjectDir            = ''
        self._stageslist                = '12'
        
        for key, value in kwargs.iteritems():
            if key == 'subjectList':    self._l_subject         = value
            if key == 'stages':         self._stageslist        = value


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
    scriptName = os.path.basename(sys.argv[0])
    shortSynopsis =  '''
    SYNOPSIS

            %s                                            \\
                            [--stages <stages>]             \\
                            [--query]                       \\
                            [-v|--verbosity <verboseLevel>] \\
                            <Subj1> <Subj2> ... <SubjN>
    ''' % scriptName
  
    description =  '''
    DESCRIPTION

        `%s' is a meta-controller for setting up and analyzing a set of 
        Dyslexia experiments.

    ARGS

       --stages <stages>
       The stages to execute. This is specified in a string, such as '1234'
       which would imply stages 1, 2, 3, and 4.

       The special keyword 'all' can be used to turn on all stages.


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
                        default='0',
                        help='analysis stages')

    args = parser.parse_args()

    zrs5 = FNNDSC_ZRS5( subjectList     = args.l_subj,
                        stages          = args.stages,
                        logTo           = 'zrs5.log',
#                        logTo           = sys.stdout,
                        syslog          = True,
                        logTee          = True)
    zrs5.verbosity(args.verbosity)
    pipeline    = zrs5.pipeline()
    pipeline.poststdout(True)
    pipeline.poststderr(True)

    stage0 = stage.Stage_crun(
                        name            = 'Lobes_annotate',
                        fatalConditions = True,
                        syslog          = True,
                        logTo           = 'zrs5-lobes_annotate.log',
                        logTee          = True,
                        cmd             = 'lobe_annot.sh -v 10 -S ' + ' '.join(args.l_subj)
                        )
    stage0.def_postconditions(f_stageShellExitCode, obj=stage0)

    stage1 = stage.Stage_crun(
                        name            = 'pial_curvatures',
                        fatalConditions = True,
                        syslog          = True,
                        logTo           = 'zrs5-pial_curvatures.log',
                        logTee          = True,
                        cmd             = 'mris_curvature_stats.bash -v 10 -f -t 12 -w 0 -s -S pial ' + ' '.join(args.l_subj)
                        )                        
    stage1.def_preconditions(stage0.def_postconditions()[0], **stage0.def_postconditions()[1])
    stage1.def_postconditions(f_stageShellExitCode, obj=stage1)
                        
    stageX = stage.Stage(
                        name            = 'Callback',
                        fatalConditions = True,
                        syslog          = True,
                        logTo           = 'zrs5-callback.log',
                        logTee          = True
                        )
    def f_stageXcallback(**kwargs):
        f_sum = 0
        for i in range(0, 10000):
            f_sum = f_sum+i
        stageX.stdout('f_sum = %d\n' % f_sum)
        return True

      
    stageX.def_stage(f_stageXcallback)

    zrs5log = zrs5.log()
    zrs5log('INIT: %s\n' % ' '.join(sys.argv))
    zrs5.stage_add(stage0)
    zrs5.stage_add(stage1)
    zrs5.stage_add(stageX)
    zrs5.initialize()

    zrs5.run()
  
