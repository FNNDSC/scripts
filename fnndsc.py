#!/usr/bin/env python
import  os
import  sys
import  string
import  getopt
import  argparse
import  csv
from    _common import systemMisc       as misc
from    _common import crun

import  error
import  message
import  stage


class FNNDSC():
    '''
    The 'FNNDSC' class provides the base infrastructure for batched pipelined
    processessing. It provides the basic level of services and abstractions
    needed to run staged (serial) pipelined analysis streams.

    Sub-classes of this base provide experiment-specific specializations.
    
    '''

    
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
        get/set the descriptive name text of this object.
        '''
        if len(args):
            self.__name = args[0]
        else:
            return self.__name

    
    def pipeline(self, *args):
        if len(args):
            self._pipeline              = args[0]
        else:
            return self._pipeline


    def verbosity(self, *args):
        if len(args):
            self._verbosity             = args[0]
            self._log.verbosity(args[0])
            self._pipeline._log.verbosity(args[0])
        else:
            return self._verbosity

            
    def vprintf(self, alevel, format, *args):
        '''
        A verbosity-aware print.
        
        '''
        if self._verbosity and self._verbosity <= alevel:
            sys.stdout.write(format % args)
            
        
    def __init__(self, **kwargs):
        '''
        Basic constructor. Checks on named input args, checks that files
        exist and creates directories.

        '''
        self.__name                     = 'FNNDSC-base'
        self._verbosity                 = 0
        self._log                       = message.Message()
        self._log.tee(True)
        self._log.syslog(True)

        self._pipeline                  = stage.Pipeline(name = self.__name)
        self._pipeline.log(self._log)

        self._str_subjectDir            = ''
        self._b_debugMode               = False
        
        for key, value in kwargs.iteritems():
            if key == 'syslog':         self._log.syslog(value)
            if key == 'logTo':          self._log.to(value)
            if key == 'logTee':         self._log.tee(value)



    def initialize(self):
        '''
        This method provides some "post-constructor" initialization. It is
        typically called after the constructor and after other class flags
        have been set (or reset).
        
        '''

                
    def run(self):
        '''
        The main 'engine' of the class.

        '''
        self._log('Starting %s...\n' % self.__name)
        self._pipeline.execute()
        self._log('Finished %s\n' % self.__name)
        

    def stage_add(self, stage):
        self._pipeline.stage_add(stage)

