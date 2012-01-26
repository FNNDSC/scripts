#!/usr/bin/env python
# 
# NAME
#
#        crun
#
# DESCRIPTION
#
#        'crun' is functor family of scripts for running command line
#        apps on a cluster.
#
# HISTORY
#
# 25 January 2012
# o Initial design and coding.
#

# System imports
import systemMisc as misc
import sys

class crun(object):
    """
        This family of functor classes provides a unified interface
        to running shell-commands remotely either via ssh or a
        scheduler on a cluster.
    """    
        
    def __init__(self, **kwargs):
        self._b_runCmd          = False         # Debugging flag
                                                #+ will only execute command
                                                #+ if flag is true
        self._b_sshDo           = False
        self._b_singleQuoteCmd  = False         # If True, force enclose of
                                                #+ strcmd with single quotes
        self._b_detach          = True          # If True, detach process from shell
        self._str_remoteHost    = ""
        self._str_remoteUser    = ""
        self._str_remotePasswd  = ""

        self._str_scheduleCmd   = ""
        self._str_scheduleArgs  = ""
        self._str_stdout        = ""
        for key, value in kwargs.iteritems():
            if key == "remoteHost":
                self._b_sshDo           = True     
                self._str_remoteHost    = value
            if key == "remoteUser":     self._str_remoteUser    = value
            if key == "remotePasswd":   self._str_remotePasswd  = value
        
    
    def __call__(self, str_cmd):
        str_prefix              = self._str_scheduleCmd + " " + \
                                  self._str_scheduleArgs
        if self._b_singleQuoteCmd:
            str_shellCmd        = str_prefix + (" '%s'" % str_cmd)
        else:
            str_shellCmd        = str_prefix + str_cmd
        if self._b_sshDo and len(self._str_remoteHost):
           str_suffix           = ">/dev/null 2>&1 &"
           str_shellCmd         = 'ssh %s@%s "nohup %s %s"' % (self._str_remoteUser,
                                                    self._str_remoteHost,
                                                    str_shellCmd,
                                                    str_suffix)
        
        ret                     = 0
        if self._b_detach: str_shellCmd += " &"

        if not self._b_runCmd:
            print str_shellCmd
        else:
#            ret, self._str_stdout = misc.system_procRet(str_shellCmd)
            self._str_stdout    = misc.shellne(str_shellCmd)
        return ret

    def scheduleCmd_set(self, str_cmd):
        self._str_scheduleCmd = str_cmd

    def scheduleArgs_set(self, str_args):
        self._str_scheduleArgs = str_args

    def detach(self, *args):
        self._b_detach          = True
        if len(args):
            self._b_detach      = args[0]
    
    def sshDo(self, *args):
        self._b_sshDo           = True
        if len(args):
            self._b_sshDo       = args[0]

    def remoteLogin_set(self, str_remoteUser, str_remoteHost, **kwargs):
        self.sshDo()
        self._str_remoteUser    = str_remoteUser
        self._str_remoteHost    = str_remoteHost
        for key, value in kwargs.iteritems():
            if key == "passwd": self._str_remotePasswd = value

class crun_mosix(crun):
    def __init__(self, **kwargs):
        crun.__init__(self, **kwargs)
        self._str_scheduleCmd   = 'mosrun'
        self._str_scheduleArgs  = '-e -E -q -b '
        
    def __call__(self, str_cmd):
        return crun.__call__(self, str_cmd)

class crun_mosixbash(crun):
    def __init__(self, **kwargs):
        crun.__init__(self, **kwargs)
        self._str_scheduleCmd   = 'mosix_run.bash'
        self._str_scheduleArgs  = '-c'
        self._b_singleQuoteCmd  = True
        
    def __call__(self, str_cmd):
        return crun.__call__(self, str_cmd)


if __name__ == '__main__':
    shell       = crun_mosix(remoteUser="rudolphpienaar", remoteHost="rc-drno")
    str_cmd     = ""
    for arg in sys.argv[1:len(sys.argv)]:
        str_cmd = str_cmd + " " + arg
#    shell.remoteLogin_set("rudolphpienaar", "rc-drno")
    shell._b_runCmd     = False
    
    shell.detach()
    shell(str_cmd)
    
    