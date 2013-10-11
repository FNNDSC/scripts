#!/usr/bin/env python

'''
    This simple QA (Quality Assurance) program captures image snapshots of 
    browser renderings of HBWM spheres.
    
    Its purpose is to provide a simple ability to check which HBWM
    analyses ran successfully to completion.
    
'''


import  sys
import  os
import  random
import  time
import  string
import  argparse

from    _common         import systemMisc       as misc
from    _common         import crun
from    _common._colors import Colors

from    selenium        import webdriver

import  error
import  message
import  stage

import  numpy                           as np

#from    _common import systemMisc       as misc

_str_curv       = 'H'
_str_scriptName = os.path.basename(sys.argv[0])
_str_outDir     = 'QAimages'

"""
"""

class hbwm_qa:
    """
    A Quality Assurance class that generates snapshots of HBWMs from across the
    total available space.
    """

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

    def __init__(self, **kwargs):

        # global settings
        self._log                       = message.Message()

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
        
        self._browser                   = webdriver.Chrome()
        self._str_outDir                = _str_outDir
        
        for key, value in kwargs.iteritems():
            if key == 'subjectList':    self._l_subject         = value
            if key == 'hemiList':       self._l_hemi            = value.split(',')
            if key == 'surfaceList':    self._l_surface         = value.split(',')
            if key == 'curvList':       self._l_curv            = value.split(',')
            if key == 'syslog':         self._log.syslog(value)
            if key == 'logTo':          self._log.to(value)
            if key == 'logTee':         self._log.tee(value)
            if key == 'outDir':         self._str_outDir        = value
            
        if not os.path.exists(self._str_outDir):
            self._log('Output image dir not found, creating...\n')
            misc.mkdir(self._str_outDir)

    def run(self):
        
        browser         = self._browser
        
        for self._str_subj in self._l_subject:
            for self._str_hemi in self._l_hemi:
                _lh_visible = 0
                _rh_visible = 0
                if self._str_hemi == 'lh':
                    _lh_visible = 1
                else:
                    _rh_visible = 1
                for self._str_surface in self._l_surface:
                    for self._str_curv in self._l_curv:
                        str_URL = 'http://natal.tch.harvard.edu/SurfView.php?SUBJECTS_DIR=numSubjects&rh_visible=%d&lh_visible=%d&%s_surfaceMesh=sphere&%s_functionCurvQualifier=ans-&%s_surfaceCurv=%s&%s_functionCurv=%s&%s_colorInterpolation=2&subject=%s' % \
                            (_rh_visible, _lh_visible, 
                             self._str_hemi,
                             self._str_hemi,
                             self._str_hemi,
                             self._str_surface, 
                             self._str_hemi,
                             self._str_curv,
                             self._str_hemi,
                             self._str_subj)
                        
                        self._log('Getting URL %s\n' % str_URL)
                        browser.maximize_window()
                        browser.get(str_URL)
                        
                        time.sleep(5)
                        str_fileName = '%s/%s-%s-%s-%s.png' % \
                             (self._str_outDir, self._str_subj, self._str_hemi, self._str_surface, self._str_curv)
                        browser.save_screenshot(str_fileName)
                        self._log('Saved Screenshot to "%s"\n' % str_fileName)
    

def synopsis(ab_shortOnly = False):
    shortSynopsis =  '''
    SYNOPSIS

            %s                                                  \\
                            [--verbosity|-v <verboseLevel>]     \\
                            [--hemi|-m <hemisphere>]            \\
                            [--surface|-f <surface>]            \\
                            [--curv|-c <curvType>]              \\
                            [--outDir|-o <outDir>]              \\
                            <Subj1> <Subj2> ... <SubjN>
    ''' % _str_scriptName
  
    description =  '''
    DESCRIPTION

        `%s' performs a quality assurance run across an HBWM solution space
        by opening world maps, one at a time, in a browser via selenium 
        and capturing the view to file.
        
        This allows for a quick mechanism to parse all the output space and
        determine which analysis combinations have failed.
        
    ARGS

        --hemi <hemisphere>
        The hemisphere to process. For both 'left' and 'right', pass
        'lh,rh'.

        --surface <surface>
        The surface to process. One of 'pial' or 'smoothwm'.

        --curv <curvType> (default: '%s')
        The curvature map function to use in constructing the worldmap.


        --outDir <outDir> (default: '%s')
        The output directory to contain the QA images.

        <Subj1> <Subj2> ... <SubjN>
        The subject list to process.

        
    PRECONDITIONS
    
        o Completed HBWM runs.
    
    POSTCONDITIONS
    
        o A set of files, named according to:
        
            <subj>-<hemi>-<surface>-<curv>.png
    
    EXAMPLES

        $>%s --curv H --hemi lh --surface smoothwm  \\
                subj1 subj2 subj3

        In this case subjects 'subj1', 'subj2', and 'subj3' will be processed 
        for an 'H' worldmap on the lh smoothwm base H surface. Each HBWM
        will be rendered, and the browser window contents saved.
        

    ''' % (_str_scriptName, _str_curv, _str_scriptName, _str_outDir)
    if ab_shortOnly:
        return shortSynopsis
    else:
        return shortSynopsis + description



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
    parser.add_argument('--debug', '-d',
                        dest='b_debug',
                        action="store_true",
                        default=False)
    parser.add_argument('--curv', '-c',
                        dest='curv',
                        action='store',
                        default='H',
                        help='curvature map to use for worldmap')
    parser.add_argument('--outDir', '-o',
                        dest='outDir',
                        action='store',
                        default='QAimages',
                        help='output directory for QA images')
    args = parser.parse_args()

    
    # A generic "shell"
    OSshell = crun.crun()
    OSshell.echo(False)
    OSshell.echoStdOut(False)
    OSshell.detach(False)

    QA = hbwm_qa(
        subjectList     = args.l_subj,
        hemiList        = args.hemi,
        surfaceList     = args.surface,
        curvList        = args.curv,
        outDir          = args.outDir,
        logTo           = 'HBWM_qa.log',
        syslog          = True,
        logTee          = True
        )

    QA.log()('INIT: (%s) %s %s\n' % (os.getcwd(), _str_scriptName, ' '.join(sys.argv[1:])))
    
    QA.run()

    sys.exit(0)

