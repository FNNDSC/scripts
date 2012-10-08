#!/usr/bin/env python

import sys

from _common import crun

class Stage:
    '''
    A simple 'stage' class used for constructing serialized pipeline
    processing streams.
    
    '''
            
    def vprintf(self, alevel, format, *args):
        '''
        A verbosity-aware print.

        '''
        if self._verbosity and self._verbosity < alevel:
            sys.stdout.write(format % args)
        sys.stdout.write(format % args)
        

    def name(self, *args):
	'''
	get/set the descriptive name text of this stage object. 
	'''
        if len(args):
            self._str_name = args[0]
        else:
            return self._str_name

            
    def __init__(self, **kwargs):
        '''

        '''

        self._str_desc  	= ''
        self._order     	= 0
        self._verbosity 	= 1

        self._str_cmd   	= ''
        self._str_name	= ''

        self._f_precondition    = lambda x: x
        self._f_postcondition   = lambda x: x
        for key, value in kwargs.iteritems():
            if key == "preconditions":  self._f_precondition    = value
            if key == "postconditions": self._f_postcondition   = value
            
    def preconditions(self):
        '''
        Returns a True if preconditions satisfied.
        
        '''
        self.vprintf(1, 'Checking preconditions...\n')
        ret = self._f_precondition(True)
        return ret

    def __call__(self, **kwargs):
        '''
        The actual stage innards.

        '''

    def postconditions(self):
        '''
        Asserts a set of postconditions

        '''
        self.vprintf(1, 'Asserting preconditions...\n')
        ret = self._f_postcondition(True)
        return ret

class Stage_crun(Stage):
    '''
    A Stage class that uses crun as its execute engine.
    '''
    def __init__(self, **kwargs):
        '''
        '''
        self._shell     = crun.crun()
        Stage.__init__(self, **kwargs)
        
    def __call__(self, **kwargs):
        '''
        The actual stage innards.

        '''

        Stage.preconditions(self)
        str_cmd = 'ls'
        self.vprintf(1, 'executing stage...\n')
        for key, value in kwargs.iteritems():
            if key == 'cmd':    str_cmd                 = value
        self._shell(str_cmd)
        Stage.postconditions(self)
        
        
if __name__ == "__main__":
    
    stage = Stage_crun()
    stage.name('test')

    stage()
