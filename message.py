#!/usr/bin/env python

import sys
import os
import time
import inspect
import types
import dgmsocket as dgm

class Message:
    '''
    A simple messaging class.
    
    '''
            
    def syslog(self, *args):
	'''
	get/set the syslog flag. 
        '''
        if len(args):
            self._b_syslog = args[0]
        else:
            return self._b_syslog


    def tee(self, *args):
        '''
        get/set the tee flag. 
        '''
        if len(args):
            self._b_tee = args[0]
        else:
            return self._b_tee


    def socket_parse(self, astr_destination):
        '''
        Examines <astr_destination> 
        '''
        t_socketInfo = astr_destination.partition(':')
        if len(t_socketInfo[1]):
            self._b_isSocket    = True
            self._socketRemote  = t_socketInfo[0]
            self._socketPort    = t_socketInfo[2]
        else:
            self._b_isSocket    = False
        return self._b_isSocket
        

    def to(self, *args):
        '''
        get/set the 'device' that is logged to. 
        '''
        if len(args):
            self._logFile = args[0]
            if self._logHandle and self._logHandle != sys.stdout:
                self._logHandle.close()
            
            if type(self._logFile) is types.FileType:
                self._logHandle = self._logFile
            elif self._logFile == 'stdout':
                self._logHandle = sys.stdout
            elif self.socket_parse(self._logFile):
                self._logHandle = dgm.C_dgmsocket(
                                            self._socketRemote,
                                            int(self._socketPort))
            else:
                self._logHandle = open(self._logFile, "a")
            self._sys_stdout      = self._logHandle
        else:
            return self._logFile
            
            
    def vprintf(self, alevel, format, *args):
        '''
        A verbosity-aware printf.

        '''
        if self._verbosity and self._verbosity < alevel:
            sys.stdout.write(format % args)
        sys.stdout.write(format % args)
        

    @staticmethod
    def syslog_generate(str_processName, str_pid):
      '''
      '''
      localtime = time.asctime( time.localtime(time.time()) )      
      hostname = os.uname()[1]
      syslog = '%s %s %s[%s]' % (localtime, hostname, str_processName, str_pid)
      return syslog
      
        
    def __call__(self, *args, **kwargs):
        '''
        Output the payload.

        '''
        str_prepend     = ''
        str_msg         = ''
        if self._b_syslog:
            str_prepend = '%s: ' % self.syslog_generate(
                                        self._processName, self._pid)
        if len(args):
            str_msg = '%s%s' % (str_prepend, args[0])
	else:
            str_msg = '%s%s' % (str_prepend, self._str_payload)
            self._str_payload = ''
        self._sys_stdout.write(str_msg)
        if self._b_tee and self._logHandle != sys.stdout:
            sys.stdout.write(str_msg)

    def append(self, str_msg):
        '''
        Append str_msg to the internal payload
        '''
        self._str_payload += str_msg


    def clear(self):
        '''
        Clear the internal payload
        '''
        self._str_payload       = ''
            
                
    def __init__(self, **kwargs):
        '''

        '''

        # One construction, set the "internal" stdout and stderr to the 
        # (current) system stdout and stderr file handles
        self._sys_stdout        = sys.stdout
        self._sys_stderr        = sys.stderr
        
        self._verbosity         = 1
        self._b_syslog          = False
        self._b_tee             = False

        self._b_isSocket        = False
        self._socketPort        = 0
        self._socketRemote      = ''

        self._str_payload       = ''
        self._logFile           = 'stdout'
        self._logHandle         = None

        self._processName       = os.path.basename(
                                    inspect.stack()[-1][0].f_code.co_filename)
        self._pid               = os.getpid()

        self.to(self._logFile)
        for key, value in kwargs.iteritems():
            if key == "syslogPrepend":  self._b_syslog          = value
            if key == "logTo":          self.to(value)
            if key == 'tee':            self._b_tee             = value
            
        
if __name__ == "__main__":
    
    log1 = Message()
    log2 = Message()
    
    log1.syslog(True)
    log1.tee(True)

    log1('hello world!\n')
    log2.to('/tmp/log2.log')
    log2('hello, too!\n')

    log1.to('pretoria:1701')
    log1('this goes over a DGM socket...\n')

    log1.to('stdout')
    log1('back to stdout\n')

    log1.to('/tmp/test.log')
    log1('and now to /tmp/test.log\n')

    log1.to(open('/tmp/test2.log', 'a'))
    log1('and now to /tmp/test2.log\n')
    
    log1.clear()
    log1.append('this is message ')
    log1.append('that is constructed over several ')
    log1.append('function calls...\n')
    log1.to('stdout')
    log1()

    log2('goodbye!\n')
    
