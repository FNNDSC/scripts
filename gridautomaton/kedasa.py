#!/usr/bin/env python
# 
# NAME
#
#        kedasa
#
# DESCRIPTION
#
#        This houses several classes based on the 'kedasa' concept, 
#        i.e. classes that contain 'ml_KEys', 'mdict_lDAta', and
#        'mdict_sgmlCore' - 'KEysDAtaSgmlAtom'.
#
#        Also defined is the C_kedasa class, which functions as the
#        "base" class for several derived classes built on the kedasa
#        concept.
#
# HISTORY
#
# 03 December 2006
# o Initial development implementation
#
# 11 April 2007
# o Added C_kedasa as "abstract"-ish base class
#

# System imports
import         os
import         sys
import        string
from    cStringIO       import  StringIO
from         cgi                 import         *

# 3rd party imports
from         configobj         import         ConfigObj

# Project imports
from        m4u_env                import         *
from         C_SGMLatom         import         *
from        systemMisc        import        *
                    
class C_kedasa :
        # 
        # Member variables
        #
        #         - Core variables - generic
        mstr_obj        = 'C_kedasa';                # name of object class
        mstr_name        = 'void';                # name of object variable
        m_id                = -1;                         # id of agent
        m_iter                = 0;                        # current iteration in an
                                                #         arbitrary processing 
                                                #        scheme
        m_verbosity        = 0;                        # debug related value for 
                                                #        object
        m_warnings        = 0;                      # show warnings 
                                                #        (and warnings level)
        
        #
        #        - Class variables
        #        Core variables - specific
        ml_keys                        = None
        mdict_sgmlCore                = None
        mdict_data                = None
        mC_env                        = None
        
        #
        #
        # Methods
        #
        # Core methods - construct, initialise, id
        def core_construct(        self,
                                astr_obj        = 'C_kedase',
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
        
        def __str__(self):
            valuePair_sprint('mstr_obj',           self.mstr_obj)
            valuePair_sprint('mstr_name',          self.mstr_name)
            valuePair_dprint('m_id',               self.m_id)
            valuePair_dprint('m_iter',             self.m_iter)
            valuePair_dprint('m_verbosity',        self.m_verbosity)
            valuePair_dprint('m_warnings',         self.m_warnings)
            return 'This class is the core recipe data record class.'
        
        def __init__(self, astr_configFileName = "m4u.ini"):
                self.core_construct()
                self.mC_env        = C_m4uEnv(astr_configFileName)

        def b_hasKey(self, astr_key):
            return self.mdict_sgmlCore.has_key(astr_key)

        def sgmlCore_print(self):
            """
            "Pretty" Prints each sgmlatom in order. This is a simple
            way to dump the internal contents to output device
            """
            for str_key in self.mdict_sgmlCore:
                data            = self.mdict_sgmlCore[str_key]
                str_data        = data.value_get()
                if len(str_data):
                   str_value    = str_data
                else:
                   str_value    = "-void-"
                valuePair_sprint(str_key, str_value,
                                 30, 40)

        def data_init(self, aS_init=None):
            """
            Initializes the self.mdict_data dictionary to aS_init
            with keys based on self.keys.
            """
            self.mdict_data = {}
            for key in self.ml_keys:
                self.mdict_data[key] = aS_init
                                 
        def sgmlCore_init(self, astr_initValue=""):
            """
            Initializes the self.mdict_sgmlCore dictionary to zero values
            with keys based on self.keys.
            """
            self.mdict_sgmlCore = {}
            for key in self.ml_keys:
                self.mdict_sgmlCore[key] = C_SGMLatom_std(key, astr_initValue)

        def sgmlCore_addKey(self, astr_key, astr_value = "",
                            **adict_attributes):
          """
          Adds a new key to self.ml_keys and a corresponding default
          mdict_sgmlCore entry
          """
          self.ml_keys.append(astr_key)
          self.mdict_sgmlCore[astr_key] = \
              C_SGMLatom_std(astr_key, astr_value, **adict_attributes)

        def sgmlCore_addSGML(self, astr_key, aSGML):
          """
          Adds a new key to self.ml_keys and a corresponding SGML component
          to the dictionary.
          """
          self.ml_keys.append(astr_key)
          self.mdict_sgmlCore[astr_key] = aSGML

        def sgmlCore_setSGML(self, astr_key, aSGML):
          """
          For the <astr_key>, set the SGML value to <aSGML>
          """
          if self.mdict_sgmlCore.has_key(astr_key):
              self.mdict_sgmlCore[astr_key] = aSGML

        def sgmlCore_setValue(self, astr_key, astr_value, ab_singleLine=1):
          """
          For the <astr_key>, set the value of SGML structure to astr_value
          """
          if self.mdict_sgmlCore.has_key(astr_key):
              self.mdict_sgmlCore[astr_key].value_set(astr_value)
              self.mdict_sgmlCore[astr_key].mb_singleLine_set(ab_singleLine)

        def sgmlCore_setAttribDict(self, astr_key, adict_attributes):
          """
          For the <astr_key>, reset the dictionary contents to the attribute
          dictionary.
          """
          b_ret = False
          if self.mdict_sgmlCore.has_key(astr_key):
            b_ret       = True
            self.mdict_sgmlCore[astr_key].attributes_setDict(adict_attributes)
          return b_ret

        def str_sgml(self, astr_key):
          """
          Return the self.mdict_sgmlCore[astr_key]
          """
          str_ret       = ""
          if self.mdict_sgmlCore.has_key(astr_key):
            str_ret = self.mdict_sgmlCore[astr_key]
          return str_ret

        def str_sgmlValue(self, astr_key):
          """
          Return the 'value' string of the corresponding <astr_key>.
          If not found, return empty string.
          """
          str_ret       = ""
          if self.mdict_sgmlCore.has_key(astr_key):
            str_ret = self.mdict_sgmlCore[astr_key].value_get().strip()
          return str_ret
                                
        def str_sgmlAttrib(self, astr_key, astr_attribKey=""):
          """
          Return the 'attribute' string of the corresponding <astr_key>.
          If not found, return empty string.

          If the <astr_attribKey> is also specified, return only the attribute
          value of the corresponding <astr_attribKey>.
          """
          str_ret       = ""
          if self.mdict_sgmlCore.has_key(astr_key):
            str_ret = self.mdict_sgmlCore[astr_key].str_attributes_get()
            if len(astr_attribKey):
              str_ret = \
              self.mdict_sgmlCore[astr_key].str_attribute_get(astr_attribKey)
          return str_ret
        
        def dict_sgmlAttrib(self, astr_key):
          """
          Return the 'attribute' dictionary of the corresponding <astr_key>.
          If not found, return empty dict.
          """
          dict_ret       = {}
          if self.mdict_sgmlCore.has_key(astr_key):
            dict_ret = self.mdict_sgmlCore[astr_key].dict_attributes_get()
          return dict_ret
        
        def fieldset(self, astr_key, astr_value):
            #
            # PRECONDITIONS
            # o Valid mdict_sgmlCore
            #
            # POSTCONDITIONS
            # o Sets the appropriate value in mdict_sgmlCore to astr_value
            #
            self.mdict_sgmlCore[astr_key].value_set(astr_value)
                
        def fieldget(self, astr_key):
            #
            # PRECONDITIONS
            # o Valid mdict_sgmlCore
            #
            # POSTCONDITIONS
            # o Gets the appropriate value in mdict_sgmlCore
            #
            return self.mdict_sgmlCore[astr_key].value_get()
        
        
        def fieldset_usingForm(self, astr_key, aform):
            if(aform.getvalue(astr_key) != None):
                self.mdict_sgmlCore[astr_key].value_set(aform.getvalue(astr_key))     
        
        def populate_usingForm(self, aform):
            for element in self.ml_keys:
                  self.fieldset_usingForm(element, aform)
                                
        #
        # get / set attributes

class C_kedasa_wrapSGML(C_kedasa):
        """
        This wrapper class specialization essentially "wraps" the SGML
        dictionary contents in a root SGML structure.

        Functionally, this sub-class adds a new element, mC_SGMLwrap. 
        This SGML wrapper has as its contents a string representation
        of all the SGML elements of the parent class.
        
        Basically, this sub-class is used for constructing the layout
        elements of an html page and as such has a stringIO mCore
        member allowing for output of its internals.
        """

        mCore                   = None
        m_tabIndent             = 0             # Default tab indenting for
        m_tabLength             = 4             #+section display
        mb_contentsIndent       = False         # If set, adds an extra
                                                #+ indentation to contents
                                                #+ field. Useful if housing
                                                #+ tags and initial data are
                                                #+ at same level.
        mC_SGMLwrap             = None
        mb_showOnlySGMLValue    = False         # If set, only use the SGML
                                                #+ value to construct the
                                                #+ section contents, and not
                                                #+ the SGML object itself. This
                                                #+ is useful if the section is
                                                #+ constructed from a ready-
                                                #+ parsed data SGML atom.

        def indent_incr(self):
          self.m_tabIndent      += 1

        def indent_decr(self):
          self.m_tabIndent      -= 1
          if self.m_tabIndent < 0: self.m_tabIndent = 0

        def __init__(self, al_keys, aSGML_wrap = None,
                                    astr_configFileName = "m4u.ini"):
          self.ml_keys          = al_keys
          self.sgmlCore_init()
          C_kedasa.__init__(self, astr_configFileName)
          C_kedasa.core_construct(self)
          if not aSGML_wrap:
            self.mC_SGMLwrap    = C_SGMLatom_std()
          else:
            self.mC_SGMLwrap    = aSGML_wrap
          self.mCore            = C_stringCore()

        def __str__(self):
                return self.strget()

        def update(self):
            """
            Printing the wrapper class triggers the construction
            of its internals. Calling this method has the same effect
            as calling a print, without a return value.
            """
            str_null    = self.strget()

        def strget(self):
            """
            The "output" of this class is a string text representation
            of its contents, wrapped within a housing SGML atom.
            """
            self.mCore.reset()
            self.mC_SGMLwrap.value_clear()
            if not self.mC_SGMLwrap:
              self.mC_SGMLwrap = C_SGMLatom_std()
            self.mC_SGMLwrap.mb_singleLine_set(False)
            for subSection in self.ml_keys:
              if(self.mb_showOnlySGMLValue):
                str_SGML  = self.mdict_sgmlCore[subSection].value_get()
              else:
                str_SGML  = self.mdict_sgmlCore[subSection].strget()
              self.mC_SGMLwrap.add(str_SGML)
              if subSection != self.ml_keys[-1]:
                self.mC_SGMLwrap.add('\n')
            if self.mb_contentsIndent:
                  self.mCore.write(str_blockIndent(self.mC_SGMLwrap.strget(),
                                   self.m_tabIndent+1,
                                   self.m_tabLength))
            else: self.mCore.write(self.mC_SGMLwrap.strget())
            str_ret     = self.mCore.strget()
            if self.m_tabIndent:
                str_ret = str_blockIndent(str_ret,
                                        self.m_tabIndent,
                                        self.m_tabLength)
            return str_ret

class C_configObj :
        #
        # configObj-specific data
        mStruct                                = None
        mstr_configFileName                = ''
        mconfigObj                        = ConfigObj()
                
        #
        # get / set attributes
                
        #
        # configObj-specific methods
        def __init__(self, aC_struct, astr_configFileName):
            self.mconfigObj                = ConfigObj(astr_configFileName)
            self.mstr_configFileName        = astr_configFileName
            self.mStruct                = aC_struct
                
        def __str__(self):
                return 'The "configObj" child manages config object file access.'
        
        def configObj_set(self, astr_configFileName):
            if systemMisc.file_exists(astr_configFileName):
                self.mconfigObj        = ConfigObj(astr_configFileName)
                        
        def fieldset_usingConfigObj(self, astr_key):
            try:
                str_val = self.mconfigObj[astr_key]
            except:
                str_val = '-not found-'
            self.mStruct.mdict_sgmlCore[astr_key].value_set(str_val)
        
        def populate_usingConfigObj(self):
            for str_element in self.mStruct.ml_keys:
                  self.fieldset_usingConfigObj(str_element)
                
        def save_toConfigFile(self):
            #
            # PRECONDITIONS
            # o Assumes that the current internal mdict_sgmlCore contains
            #        values to save.
            #
            # POSTCONDITIONS
            # o The mdict_sgmlCore will be written to mconfigObj 
            #
            for str_element in self.mStruct.ml_keys:
                self.mconfigObj[str_element] = \
                        self.mStruct.mdict_sgmlCore[str_element].value_get()
            self.mconfigObj.write()

class C_CSV :
        #
        # configObj-specific data
        mStruct                                = None
        mstr_DBFileName                        = ''
        mstr_fieldDelimiter                = ','
                
        #
        # get / set attributes
                
        #
        # configObj-specific methods
        def __init__(        self,         aC_struct, 
                        astr_DBFileName, astr_fieldDelimiter = ','):
            self.mStruct                = aC_struct
            self.mstr_DBFileName        = astr_DBFileName
            self.mstr_fieldDelimiter        = astr_fieldDelimiter
        
        def __str__(self):
                return 'The "CSV" child manages CSV-type databases.'
                
        def CSV_save(self):
            #
            # PRECONDITIONS
            # o Assumes that the current internal mdict_sgmlCore contains
            #        values to save.
            #
            # POSTCONDITIONS
            # o The mdict_sgmlCore will be written to the DBFileName
            #        using set delimiter
            # o Return: True = write successful, False = write unsuccessful 
            #
            if systemMisc.file_exists(self.mstr_DBFileName):
                fout        = open(self.mstr_DBFileName, "a")
                for str_element in self.mStruct.ml_keys:
                    str_val        = \
                        self.mStruct.mdict_sgmlCore[str_element].value_get()
                    if str_val == "None": str_val = ""
                    fout.write("%s%s" %(str_val, self.mstr_fieldDelimiter))
                fout.write("\n")
                fout.close()
                return True
            else:
                return False        

class C_xmlDB :
        #
        # fileDB-specific data
        m4uEnv                        = None
        m4uStruct                = None
        mstr_htdocDir                = 'htdocs'
        mstr_cgibinDir                = 'cgi-bin'
        mstr_localhostPath        = ''
        mstr_DBpreamble                =  "<?xml version='1.0' encoding='UTF-8'?>"
        mfileDB                        = None
        mstr_xlsCopy                = 'xlsCopy.sh'
        mstr_xlsCopyFP                = ''
        mstr_dist2mono                = 'dist2monoDB.bash'
        mstr_dist2monoFP        = ''
        mb_xlsRun                = True
        mb_fileDBOpen                = False
        mstr_DBaccessMode        = "a"
        mstr_DBtype                = 'distributed'
        mstr_DBname                = 'fileDB.xml'
        mstr_DBpath                = ''
        mstr_DBfullName                = ''
        mstr_monoPath                = "mono"
        mstr_distPath                = "dist"
        mstr_housingTag                = "recipe"
                
        #
        # get / set attributes
                
        #
        # fileDB-specific methods
        # NOTE: Need to add config type processing of m4u.ini!
        def __init__(self,         aC_struct, 
                                astr_classConf         = 'recipe-XMLDB',
                                astr_path         = '/var/www/localhost', 
                                astr_housingTag        = "recipe",
                                astr_fileDB         = 'fileDB.xml'):
            self.mstr_localhostPath        = astr_path
            self.mstr_xlsCopyFP                = "%s/%s/%s" % \
                            (self.mstr_localhostPath, 
                         self.mstr_htdocDir, 
                         self.mstr_xlsCopy)
            self.mstr_dist2monoFP        = "%s/%s/%s" % \
                            (self.mstr_localhostPath, 
                         self.mstr_htdocDir, 
                         self.mstr_dist2mono)
            self.m4uEnv                        = C_m4uEnv()
            self.m4uStruct                = aC_struct
            C_m4uEnv.mconfig                = ConfigObj('m4u.ini')
            self.mstr_htdocDir                = C_m4uEnv.mconfig['cgi']['htdocs']
            self.mstr_cgibinDir                = C_m4uEnv.mconfig['cgi']['cgi-bin']
            self.mstr_DBtype                = C_m4uEnv.mconfig[astr_classConf]['type']
            self.mstr_distPath                = C_m4uEnv.mconfig[astr_classConf]['distPath']
            self.mstr_monoPath                = C_m4uEnv.mconfig[astr_classConf]['monoPath']
            self.mstr_DBname                = astr_fileDB
            self.mstr_housingTag        = astr_housingTag
            self.internals_sync()
                                
        def internals_sync(self):
            #
            # PRECONDITIONS
            # o Assumes that the class constructor has been successful
            #
            # POSTCONDITIONS
            # o Sets some additional internal variables that depend on 
            #   initialisation conditions.
            # o Usually called when the DBtype and/or DBname have changed
            #
            if self.mstr_DBtype == 'distributed':
                str_DBpath                = self.mstr_distPath
            else:
                str_DBpath                = self.mstr_monoPath    
            self.mstr_DBpath                = "%s/%s/%s" % \
                            (self.mstr_localhostPath, 
                         self.mstr_htdocDir, 
                         str_DBpath)
            self.mstr_DBfullName        = "%s/%s" % \
                            (self.mstr_DBpath, 
                         self.mstr_DBname)
                                    
        def mFileDB_reset(self, astr_fileName, astr_accessMode = 'w'):
            #
            # PRECONDITIONS
            #         o Assumes that internal file handle has been set
            #
            # POSTCONDITIONS
            #        o Closes existing handle and opens a new one
            #        o Updates internal tracking variables to 
            #          new filename.
            #
            self.mstr_DBname                = astr_fileName
            self.mstr_DBaccessMode        = astr_accessMode
            self.internals_sync()
                        
        def __str__(self):
            C_m4uRecipe.__str__(self)
            return 'The "xmlDB" child manages flat XML file database access.'
        
        def XML_DBHeaderWrite(self):
            self.mfileDB.write('%s\n' % self.mstr_DBpreamble)
            self.mfileDB.write('<database>\n')        
                        
        def XML_DBFooterWrite(self):
            self.mfileDB.write('</database>\n\n')        
                
        def XML_preparse(self):
            str_cmd = 'cat %s | grep -v \/database > %s.tmp' % \
                    (self.mstr_DBfullName, 
                 self.mstr_DBfullName)
            systemMisc.system_eval(str_cmd)
            str_cmd = 'cp %s.tmp %s ; rm %s.tmp' % \
                            (self.mstr_DBfullName,
                         self.mstr_DBfullName,
                         self.mstr_DBfullName)
            systemMisc.system_eval(str_cmd)
            
        def XML_postparse(self, ab_forceXlsRun = False):
            if self.mstr_DBtype == 'distributed':
                str_monoFile        = '%s/%s/%s/fileDB.xml' % \
                                        (self.mstr_localhostPath,
                                        self.mstr_htdocDir,
                                        self.mstr_monoPath)
                str_distDir        = '%s/%s/%s' % \
                                        (self.mstr_localhostPath,
                                        self.mstr_htdocDir,
                                        self.mstr_distPath)
                os.system("rm -f %s" % str_monoFile)
                os.system("%s -m %s -d %s" % \
                        (self.mstr_dist2monoFP,
                        str_monoFile,
                        str_distDir))
            if self.mb_xlsRun or ab_forceXlsRun:
                os.system(self.mstr_xlsCopyFP)        
        
            
        def XML_save(self):
            #
            # PRECONDITIONS
            # o Assumes that the current internal mdict_sgmlCore contains
            #        values to save.
            #
            # POSTCONDITIONS
            # o The mdict_sgmlCore will be written to mfileDB 
            # o mono/distributed DB aware
            # o For 'mono' DB, will check for running 'xlsCopy'
            #
            
            if self.mb_fileDBOpen:
                    self.mfileDB.close()            
            
            if self.mstr_DBtype == "distributed":
                self.mFileDB_reset("%s.xml" % \
                        self.m4uStruct.mdict_sgmlCore['idCode'].value_get())
            
            self.mfileDB                = open(        self.mstr_DBfullName, 
                                                    self.mstr_DBaccessMode)
            
            if self.mstr_DBtype == "distributed":
                    self.XML_DBHeaderWrite()                # Create the header
            else:
                    self.XML_preparse()                        # Filter out the header
            
            # write the recipe
            self.mfileDB.write('<%s>\n\n' % self.mstr_housingTag)
            for str_element in self.m4uStruct.ml_keys:
                str_value = self.m4uStruct.mdict_sgmlCore[str_element].value_get()
                self.mfileDB.write('\t<%s>%s</%s>\n' % 
                        (str_element, str_value, str_element))
            self.mfileDB.write('</%s>\n\n' % self.mstr_housingTag)
            
            self.XML_DBFooterWrite()
            self.mfileDB.flush()
            self.mfileDB.close()
            self.mb_fileDBOpen         = False
            
            