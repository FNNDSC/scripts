# -*- coding: utf-8 -*-
# NAME
#
#        C_search
#
# DESCRIPTION
#
#        'C_search' is a simple class that searches filesystem based
#        data.
#
#
# HISTORY
#
# 28 June 2007
# o Initial development implementation.
#

# System imports
import         os
import         os.path
import         sys
import        string
import        datetime

# 3rd party imports
from         configobj                 import         ConfigObj

# Project imports
import        systemMisc

class C_search :
        """
        This is the base class that houses a specialized search functionality.
        The heavy lifting is done by the shell "grep" utility - this class is
        really just a python wrapper / interface / state-machine about the
        shell "grep".
        """
        # 
        # Member variables
        #
        #         - Core variables - generic
        mstr_obj        = 'C_search';                # name of object class
        mstr_name        = 'void';                # name of object variable
        mstr_def        = 'void';                # name of function being processed
        m_id                = -1;                         # id of agent
        m_iter                = 0;                        # current iteration in an
                                                #         arbitrary processing 
                                                #        scheme
        m_verbosity        = 0;                        # debug related value for 
                                                #        object
        m_warnings        = 0;                      # show warnings 
                                                #        (and warnings level)
        m_LC                = 20;
        m_RC                = 20;
        #
        #        - Class variables
        #        Core variables - specific
        #
        mlstr_searchPath        = [];                # A list containing the paths
                                                # to search. 
        mlstr_searchExpr        = [];                # The search expression to 
                                                # evaluate in each path
        mdict_searchResults        = {};                # A dictionary that contains
                                                # results organized by path
        mlstr_filesHit                = [];                # List of actual files hit during
                                                # each search instance.
        mdict_filesHit                = {};                # A dictionary associating files
                                                # with meta data.
        
        mstr_searchShell        = "../search.sh -il"
        mstr_fieldgetShell        = "../field_get"
        
        def searchShell_set(self, astr_shell):
            self.mstr_searchShell = astr_shell
         
        def fieldgetShell_set(self, astr_shell):
            self.mstr_fieldgetShell = astr_shell
        
        def searchPath_append(self, astr_path):
            self.mlstr_searchPath.append(astr_path)
        
        def searchPath_extend(self, astr_path):
            self.mlstr_searchPath.extend(astr_path)
        
        def searchExpr_extend(self, astr):
            self.mlstr_searchExpr.extend(astr);
            
        def searchExpr_get(self):
            return self.mlstr_searchExpr;
        
        def searchPath_get(self):
            return self.mlstr_searchPath
                
        def filesHit_get(self):
            return self.ml_filesHit
        
        def searchResults_get(self):
            return self.mdict_searchResults
        
        def hits_count(self):
            hits        = 0;
            for str_dir in self.mdict_searchResults:
                hits += len(self.mdict_searchResults[str_dir].keys())
            return hits
                    
        
        #
        # Methods
        #
        # Core methods - construct, initialise, id
        
        def error_exit(                self,
                                astr_action,
                                astr_error,
                                aexitCode):
            print "%s:: FATAL ERROR" % self.mstr_obj
            print "\tSorry, some error seems to have occurred in <%s::%s>" \
                            % (self.mstr_obj, self.mstr_def)
            print "\tWhile %s"                                         % astr_action
            print "\t%s"                                        % astr_error
            print ""
            print "Returning to system with error code %d"        % aexitCode
            sys.exit(aexitCode)
            
        def core_construct(        self,
                                astr_obj        = 'C_search',
                                astr_name        = 'void',
                                a_id                = -1,
                                a_iter                = 0,
                                a_verbosity        = 0,
                                a_warnings        = 0) :
                self.mstr_obj                = astr_obj
                self.mstr_name                = astr_name
                self.m_id                = a_id
                self.m_iter                = a_iter
                self.m_verbosity        = a_verbosity
                self.m_warnings                = a_warnings
        
        
        def __init__(self,          **header):
            #
            # PRECONDITIONS
            # o None - all arguments are optional
            #
            # POSTCONDITIONS
            # o Any arguments specified in the **header are
            #        used to initialize internal variables.            
            #        
            self.core_construct()
            for field in header.keys():
                    if field == 'search':        self.mstr_searchExpr        = header[field]
                if field == 'path':        self.searchPath_append(header[field])
                    
        def __str__(self):
            print "%*s:%*s" % (self.m_LC, "mstr_obj",         self.m_RC, self.mstr_obj)
            print "%*s:%*s" % (self.m_LC, "mstr_name",         self.m_RC, self.mstr_name)
            print "%*s:%*s" % (self.m_LC, "m_id",        self.m_RC, self.m_id)
            print "%*s:%*s" % (self.m_LC, "m_iter",        self.m_RC, self.m_iter)
            print "%*s:%*s" % (self.m_LC, "m_verbosity",self.m_RC, self.m_verbosity)
            print "%*s:%*s" % (self.m_LC, "m_warnings",        self.m_RC, self.m_warnings)
            print ""
            print "%*s:%*s"        %         (self.m_LC, "mlstr_searchExpr", 
                                             self.m_RC, self.mlstr_searchExpr)
            print "%*s:%*s"        %         (self.m_LC, "mlstr_searchPath", 
                                             self.m_RC, self.mlstr_searchPath)
            print "%*s:%*s"        %         (self.m_LC, "mstr_searchShell", 
                                             self.m_RC, self.mstr_searchShell)
            print ""
            return 'This class implements simple search functionality.'
        
        def searchSimple(self, *l_args):
            if(len(l_args)):
                self.searchExpr_extend(l_args)
            
            for str_dir in self.mlstr_searchPath:
                os.chdir(str_dir)
                for str_searchExpr in self.mlstr_searchExpr:
                    str_command        = '%s %s' % (self.mstr_searchShell, str_searchExpr)
                     [retcode, str_stdout]        = systemMisc.subprocess_eval(str_command, 0)
                        if retcode == 0:
                        self.mlstr_filesHit        = str_stdout.split()        
                        self.mdict_filesHit        = dict.fromkeys(self.mlstr_filesHit)
                        self.mdict_searchResults[str_dir] = self.mdict_filesHit
            

class C_search_m4uXML(C_search):
        """
        This is a specialisation of the C_search class, specifically catered to the
        XML database structure of the 'm4u' system.
        """

        mlstr_resultComponents        = [
                                        'type',
                                        'title',
                                        'idCode',
                                        'introNotes'
                                ]
        mdict_XMLResults        = {}

        def XMLResults_get(self):
            return self.mdict_XMLResults
        
        def __init__(self,          **header):
            #
            # PRECONDITIONS
            # o None - all arguments are optional
            #
            # POSTCONDITIONS
            # o Any arguments specified in the **header are
            #        used to initialize internal variables.            
            #        
            C_search.__init__(self, **header)
        
        def dict_construct(self, akeys, avalues = None):
            dict        = {}
            length      = len(akeys)
            for key in range(length):
                dict[akeys[key]] = []
                if avalues != None:
                    dict[akeys[key]]    = avalues[key]
            return dict
        
        def resultComponents_htmlWrap(self, adict_results):
            #
            # PRECONDITIONS
            # o The <adict_results> have been created from a call to
            #         resultComponents_populate().
            # o Each key in <adict_results> is defined and has a value.
            #
            # POSTCONDITIONS
            # o The dictionary components are processed into an html
            #   string and returned.
            #        
            str_html = """
                    <p>
                <b>%s</b> (<i>%s</i> - %s)
                </p>
            """ %         (adict_results['title'], adict_results['type'], 
                            adict_results['idCode'])
            if(not len(adict_results['introNotes']) or 
                            adict_results['introNotes']=='-void-'):
                str_html += """
                <p><i>No introductory notes are available for this %s.</i></p>
                    """ % adict_results['str_type'].lower()
            else:
                str_html += "<p>%s</p>" % adict_results['introNotes']
            return str_html
                    
        def resultComponents_populate(self, astr_fileHit):
            #
            # PRECONDITIONS
            # o The <astr_fileHit> denotes a field/file in the mdict_searchResults
            #        that needs to be fully populated.
            #
            # POSTCONDITIONS
            # o A dictionary is returned that describes all the necessary result 
            #   components for the passed <astr_fileHit>.
            #        
            dict_results        = self.dict_construct(self.mlstr_resultComponents)
            for str_component in self.mlstr_resultComponents:
                str_type        = ''
                str_title        = ''
                str_idCode        = ''
                str_introNotes        = ''
                str_shCommand        = ''
                if(str_component == 'type'):
                    str_shCommand        = '%s -d %s -e recipe' % \
                                            (self.mstr_fieldgetShell, astr_fileHit)
                    [retcode, str_recipe] = \
                                    systemMisc.subprocess_eval(str_shCommand)
                    if(retcode):         str_type = 'RECIPE'
                    else:                str_type = 'MENU'
                    dict_results['type']        = str_type
                else:
                    str_shCommand        = '%s -d %s %s' % \
                                            (self.mstr_fieldgetShell, astr_fileHit, str_component)
                    [retcode, str_field] = \
                                    systemMisc.subprocess_eval(str_shCommand)
                    dict_results[str_component] = str_field
            return dict_results
        
        def hits_htmlGenerate(self):
            #
            # PRECONDITIONS
            #         A valid, i.e. populated, self.mdict_filesHit dictionary with the
            #        existant keys
            #
            # POSTCONDITIONS
            #        The value field of each key in the self.mdict_filesHit is filled
            #        with HTML code
            #
            
            for str_dir in self.mlstr_searchPath:
                if self.mdict_searchResults.has_key(str_dir):
                    dict_searchResults                = self.mdict_searchResults[str_dir]
                    self.mdict_XMLResults[str_dir]        = {}
                    os.chdir(str_dir)
                        for str_fileHit in dict_searchResults.keys():
                        dict_results = self.resultComponents_populate(str_fileHit)
                        str_html         = self.resultComponents_htmlWrap(dict_results)                        
                        self.mdict_searchResults[str_dir][str_fileHit] = str_html 
                        self.mdict_XMLResults[str_dir][str_fileHit] = dict_results
                    
                    
                    