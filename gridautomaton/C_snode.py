#!/usr/bin/env python

"""
    NAME
    
    	C_snode, C_snodeBranch, C_stree
        
    DESCRIPTION
    
	These three classes are used to construct tree-structures
        composed of 'C_snode' instances. Branches contain dictionaries
        of C_snodes, while leaves contain dictionaries of a specific
        external data class.
        
    HISTORY
    26 March 2008
"""

# System modules
import 	os
import 	sys
import	re
from 	string 		import 	*

from    systemMisc      import  *
from    C_stringCore    import  *


def attributes_toStr(**adict_attrib):
	strIO_attribute	= StringIO()
	for attribute in adict_attrib.keys():
	    str_text = ' %s="%s"' % (attribute, adict_attrib[attribute])
	    strIO_attribute.write(str_text)
	str_attributes = strIO_attribute.getvalue()
	return str_attributes
		
def printf(format, *args):
        sys.stdout.write(format % args)
		
def valuePair_fprint(astr_name, avalue):
	print '%40s: %f' % (astr_name, avalue)
def valuePair_sprint(astr_name, avalue):
	print '%40s: %s' % (astr_name, avalue)
def valuePair_dprint(astr_name, avalue):
	print '%40s: %d' % (astr_name, avalue)

class C_snode:
        """
        A "container" node class. This container is the
        basic building block for larger tree-like database
        structures.
  
        The C_snode defines a single 'node' in this tree. It contains
        two lists, 'ml_mustInclude' and 'ml_mustNotInclude' that define
        the features described in the 'mdict_contents' dictionary. This
        dictionary can in turn contain other C_snodes.
        """
  
        # 
        # Member variables
        #
        #       - Core variables
        mstr_obj        = 'C_snode';            # name of object class
        mstr_name       = 'void';               # name of object variable
        m_id            = -1;                   # id of agent
        m_iter          = 0;                    # current iteration in an
                                                #       arbitrary processing 
                                                #       scheme
        m_verbosity     = 0;                    # debug related value for 
                                                #       object
        m_warnings      = 0;                    # show warnings 
        
        m_str           = None
        
        # The mdict_DB is the basic building block of the C_scontainer 
        #+ class. It is simply a dictionary that contains 'contents' that
        #+ satisfy a given feature set described by 'mustInclude' and
        #+ 'mustNotInclude'. The C_scontainer is geared specifically towards
        #+ the shopping list tree structure
        #+ 
        #+ In general: 
        #+  'ml_path'           :       the node tracks its current path 
        #+                              'position' in a tree of C_snodes
        #+  'msnode_parent'     :       the parent node of this node -- useful
        #+                              for tree structuring.
        #+  'm_hitCount'        :       count of hits for all items branching
        #+                              at this level. At the leaf level, this
        #+                              contains the length of 'contents'.
        #+  'ml_mustInclude'    :       descriptive trait for specific feature
        #+                              level
        #+  'ml_mustNotInclude' :       exclusion trait for specific feature
        #+                              level
        #+  'mdict_contents'    :       depending on position in the tree, 
        #+                              this is either a list of leaves (i.e.
        #+                              terminal points) or a list of
        #+                              additional nodes.
        #+                              
        #+ The pattern of 'mustInclude' and 'mustNotInclude' uniquely 
        #+ characterizes a particular level. "Deeper" features (i.e. features 
        #+ further along the dictionary tree) must satisfy the combined set
        #+ described by all the 'mustInclude' and 'mustNotInclude' traits of
        #+ each higher level.
        
        mstr_nodeName           = ""
        m_hitCount              = 0;
        ml_mustInclude          = [],
        ml_canInclude           = [],
        ml_mustNotInclude       = [],
        ml_path                 = []
        msnode_parent           = None
        mdict_contents          = {}
        mb_printMetaData        = True
        mb_printContents        = True
        
        #
        # Methods
        #
        # Core methods - construct, initialise, id
        def core_construct(     self,
                                astr_obj        = 'C_scontainer',
                                astr_name       = 'void',
                                a_id            = -1,
                                a_iter          = 0,
                                a_verbosity     = 0,
                                a_warnings      = 0) :
            self.mstr_obj       = astr_obj
            self.mstr_name      = astr_name
            self.m_id           = a_id
            self.m_iter         = a_iter
            self.m_verbosity    = a_verbosity
            self.m_warnings     = a_warnings
        
        def __str__(self):
            self.m_str.reset()
            self.m_str.write(' +---%s\n'                  % self.mstr_nodeName)
            if self.mb_printMetaData:
              self.m_str.write(' |    +--hitCount......... %d\n' % self.m_hitCount)
              self.m_str.write(' |    +--mustInclude...... %s\n' % self.ml_mustInclude)
              self.m_str.write(' |    +--mustNotInclude... %s\n' % self.ml_mustNotInclude)
            contents    = len(self.mdict_contents)
            if contents and self.mb_printContents:
              self.m_str.write(' |    +--contents:\n')
              elCount     = 0
              for element in self.mdict_contents.keys():
                str_contents = str_blockIndent('%s' % 
                        self.mdict_contents[element])
                if elCount <= contents - 1:
                  str_contents = re.sub(r'        ', ' |      ', str_contents)
                self.m_str.write(str_contents)
                elCount   = elCount + 1
              
            return self.m_str.strget()
            
        def __init__(self,      astr_nodeName           = "",
                                al_mustInclude          = [], 
                                al_mustNotInclude       = [],
                                ):
            self.core_construct()
            self.m_str                                  = C_stringCore()
            self.mstr_nodeName                          = astr_nodeName
            self.ml_mustInclude                         = al_mustInclude
            self.ml_mustNotInclude                      = al_mustNotInclude
            self.mdict_contents                         = {}
  
        #
        # Simple error handling
        def error_exit(self, astr_action, astr_error, astr_code):
            print "%s: FATAL error occurred" % self.mstr_obj
            print "While %s," % astr_action
            print "%s" % astr_error
            print "\nReturning to system with code %s\n" % astr_code
            sys.exit(astr_code)
                                      
        def node_branch(self, al_keys, al_values):
          """
          For each node in <al_values>, add to internal contents
          dictionary using key from <al_keys>.
          """
          if len(al_keys) != len(al_values):
            self.error_exit("adding branch nodes", "#keys != #values", 1)
          ldict = dict(zip(al_keys, al_values))
          self.node_dictBranch(ldict)
              
        def node_dictBranch(self, adict):
          """
          Expands the internal mdict_contents with <adict>
          """
          self.mdict_contents.update(adict)
                              
class C_snodeBranch:
        """
        The C_snodeBranch class is basically a dictionary collection
        of C_snodes. Conceptually, a C_snodeBranch is a single "layer"
        of C_snodes all branching from a common ancestor node.
        """            
        # 
        # Member variables
        #
        #       - Core variables
        mstr_obj        = 'C_snodeBranch';      # name of object class
        mstr_name       = 'void';               # name of object variable
        m_id            = -1;                   # id of agent
        m_iter          = 0;                    # current iteration in an
                                                #       arbitrary processing 
                                                #       scheme
        m_verbosity     = 0;                    # debug related value for 
                                                #       object
        m_warnings      = 0;                    # show warnings 
                
        mdict_branch    = {}
        m_str           = None
        
        #
        # Methods
        #
        # Core methods - construct, initialise, id
        def core_construct(     self,
                                astr_obj        = 'C_snodeBranch',
                                astr_name       = 'void',
                                a_id            = -1,
                                a_iter          = 0,
                                a_verbosity     = 0,
                                a_warnings      = 0) :
            self.mstr_obj       = astr_obj
            self.mstr_name      = astr_name
            self.m_id           = a_id
            self.m_iter         = a_iter
            self.m_verbosity    = a_verbosity
            self.m_warnings     = a_warnings
        
        def __str__(self):
            self.m_str.reset()
            for node in self.mdict_branch.keys():
              self.m_str.write('%s' % self.mdict_branch[node])
            return self.m_str.strget()
                    
        def __init__(self, al_branchNodes):
            self.core_construct()
            self.m_str          = C_stringCore()
            self.mdict_branch   = {}
            element     = al_branchNodes[0]
            if isinstance(element, C_snode):
              for node in al_branchNodes:
                self.mdict_branch[node] = node
            else:
              for node in al_branchNodes:
                self.mdict_branch[node] = C_snode(node)
        #
        # Simple error handling
        def error_exit(self, astr_action, astr_error, astr_code):
            print "%s: FATAL error occurred" % self.mstr_obj
            print "While %s," % astr_action
            print "%s" % astr_error
            print "\nReturning to system with code %s\n" % astr_code
            sys.exit(astr_code)
            
        def node_branch(self, astr_node, abranch):
          """
          Adds a branch to a node, i.e. depth addition. The given
          node's mdict_contents is set to the abranch's mdict_branch.
          """
          self.mdict_branch[astr_node].node_dictBranch(abranch.mdict_branch)

class C_stree:
        """
        The C_stree class provides methods for creating / navigating
        a tree composed of C_snodes. 
        
        A C_stree is an ordered (and nested) collection of C_snodeBranch 
        instances, with additional logic to match nodes with their parent
        node.
        
        The metaphor designed into the tree structure is that of a UNIX
        directory tree, with equivalent functions for 'cdnode', 'mknode'
        'lsnode'.
        """            
        # 
        # Member variables
        #
        #       - Core variables
        mstr_obj        = 'C_stree';            # name of object class
        mstr_name       = 'void';               # name of object variable
        m_id            = -1;                   # id of agent
        m_iter          = 0;                    # current iteration in an
                                                #       arbitrary processing 
                                                #       scheme
        m_verbosity     = 0;                    # debug related value for 
                                                #       object
        m_warnings      = 0;                    # show warnings 
        
        m_str           = None
        ml_cwd          = []
        msbranch_current= None
        msnode_current  = None
        msnode_root     = C_snode('/')
        msbranch_root   = None
        ml_allPaths     = []                    # Each time a new C_snode is
                                                #+ added to the tree, its path
                                                #+ list is appended to this
                                                #+ list variable.
                
        #
        # Methods
        #
        # Core methods - construct, initialise, id
        def core_construct(     self,
                                astr_obj        = 'C_stree',
                                astr_name       = 'void',
                                a_id            = -1,
                                a_iter          = 0,
                                a_verbosity     = 0,
                                a_warnings      = 0) :
            self.mstr_obj       = astr_obj
            self.mstr_name      = astr_name
            self.m_id           = a_id
            self.m_iter         = a_iter
            self.m_verbosity    = a_verbosity
            self.m_warnings     = a_warnings
        
        def __str__(self):
            self.m_str.reset()
            self.m_str.write('%s' % self.msnode_root)
            return self.m_str.strget()
        
        def root(self):
          """
          Reset all nodes and branches to 'root'
          """
          str_treeRoot                  = '/'
          self.ml_cwd                   = [str_treeRoot]
          self.msnode_current           = self.msnode_root
          self.msbranch_current         = self.msbranch_root
        
        def __init__(self, al_rootBranch=[]):
            """
            Creates a tree structure and populates the "root" 
            branch.
            """
            if not len(al_rootBranch):
              al_rootBranch             = ['/']
            if len(al_rootBranch):
              if not isinstance(al_rootBranch, list):
                al_rootBranch           = ['/']
            self.core_construct()
            self.m_str                  = C_stringCore()
            str_treeRoot                = '/'
            self.ml_cwd                 = [str_treeRoot]
            self.msbranch_root          = C_snodeBranch([str_treeRoot])
            self.msnode_root            = self.msbranch_root.mdict_branch[str_treeRoot]
            self.msnode_root.msnode_parent      = self.msnode_root
            self.root()
            self.ml_allPaths            = self.ml_cwd[:]
            if len(al_rootBranch) and al_rootBranch != ['/']:
              self.mknode(al_rootBranch)
            
        def cwd(self):
          l_cwd         = self.ml_cwd[:]
          str_cwd       = '/'.join(l_cwd)
          if len(str_cwd)>1: str_cwd = str_cwd[1:]
          return str_cwd
          
        def pwd(self):
          return self.cwd()
        
        def ptree(self):
          return self.ml_allPaths
            
        def node_mustNotInclude(self, al_mustNotInclude, ab_reset=False):
          """
          Sets the <mustNotInclude> list of msnode_current
          """
          if ab_reset:
            self.msnode_current.ml_mustNotInclude = al_mustNotInclude[:]
          else:
            l_current   = self.msnode_current.ml_mustNotInclude[:]
            l_total     = l_current + al_mustNotInclude
            self.msnode_current.ml_mustNotInclude = l_total[:]
        
        def node_mustInclude(self, al_mustInclude, ab_reset=False):
          """
          Sets the <mustInclude> list of msnode_current
          """
          if ab_reset:
            self.msnode_current.ml_mustInclude = al_mustInclude[:]
          else:
            l_current   = self.msnode_current.ml_mustInclude[:]
            l_total     = l_current + al_mustInclude
            self.msnode_current.ml_mustInclude = l_total[:]
        
        def paths_update(self, al_branchNodes):
          """
          Add each node in <al_branchNodes> to the self.ml_cwd and
          append the combined list to ml_allPaths
          """
          for node in al_branchNodes:
            #print "appending %s" % node
            l_pwd       = self.ml_cwd[:]
            l_pwd.append(node)
            #print "l_pwd: %s" % l_pwd
            #print "ml_cwd: %s" % self.ml_cwd
            self.ml_allPaths.append(l_pwd)
                    
        def mknode(self, al_branchNodes):
          """
          Create a set of nodes (branches) at current node.
          """
          b_ret = True
          # First check that none of these nodes already exist in the tree
          l_branchNodes = []
          for node in al_branchNodes:
            l_path      = self.ml_cwd[:]
            l_path.append(node)
            #print l_path
            #print self.ml_allPaths
            #print self.b_pathOK(l_path)
            if not self.b_pathOK(l_path):
              l_branchNodes.append(node)
          snodeBranch   = C_snodeBranch(l_branchNodes)
          for node in l_branchNodes:
            snodeBranch.mdict_branch[node].msnode_parent = self.msnode_current
          self.msnode_current.node_dictBranch(snodeBranch.mdict_branch)
          # Update the ml_allPaths
          self.paths_update(al_branchNodes)
          return b_ret
        
        def b_pathOK(self, al_path):
          """
          Checks if the absolute path specified in the al_path
          is valid for current tree
          """
          b_OK  = True
          try:          self.ml_allPaths.index(al_path)
          except:       b_OK    = False
          return b_OK
        
        def b_pathInTree(self, astr_path):
          """
          Converts a string <astr_path> specifier to a list-based
          *absolute* lookup, i.e. "/node1/node2/node3" is converted
          to ['/' 'node1' 'node2' 'node3'].
          
          The method also understands a paths that start with: '..' or
          combination of '../../..' and is also aware that the root
          node is its own parent.
          
          If the path list conversion is valid (i.e. exists in the
          space of existing paths, ml_allPaths), return True and the
          destination path list; else return False and the current
          path list.
          """
          if astr_path == '/':  return True, ['/']
          al_path               = astr_path.split('/')
          # Check for absolute path
          if not len(al_path[0]):
            al_path[0]          = '/'
            #print "returning %s : %s" % (self.b_pathOK(al_path), al_path)
            return self.b_pathOK(al_path), al_path
          # Here we are in relative mode...
          # First, resolve any leading '..'
          l_path        = self.ml_cwd[:]
          if(al_path[0] == '..'):
            while(al_path[0] == '..' and len(al_path)):
              l_path    = l_path[0:-1]
              if(len(al_path) >= 2): al_path   = al_path[1:]
              else: al_path[0] = ''
              #print "l_path  = %s" % l_path
              #print "al_path = %s (%d)" % (al_path, len(al_path[0]))
            if(len(al_path[0])):  
              #print "extending %s with %s" % (l_path, al_path)  
              l_path.extend(al_path)
          else:
            l_path      = self.ml_cwd
            l_path.extend(al_path)
          #print "final path list = %s (%d)" % (l_path, len(l_path))
          if(len(l_path)>=1 and l_path[0] != '/'):      l_path.insert(0, '/')  
          if(len(l_path)>1):            l_path[0]       = ''
          if(not len(l_path)):          l_path          = ['/']
          #TODO: Possibly check for trailing '/', i.e. list ['']
          str_path      = '/'.join(l_path)
          #print "final path str  = %s" % str_path
          b_valid, al_path = self.b_pathInTree(str_path)
          return b_valid, al_path
          
        def cdnode(self, astr_path):
          """
          Change working node to astr_path. 
          The path is converted to a list, split on '/'
          
          Returns the cdnode path
          
          """
          
          # Start at the root and then navigate to the
          # relevant node
          l_absPath             = []
          b_valid, l_absPath    = self.b_pathInTree(astr_path)
          if b_valid:
            #print "got cdpath = %s" % l_absPath
            self.ml_cwd           = l_absPath[:]
            self.msnode_current   = self.msnode_root
            self.msbranch_current = self.msbranch_root
            #print l_absPath
            for node in l_absPath[1:]:
              self.msnode_current = self.msnode_current.mdict_contents[node]
            self.msbranch_current.mdict_branch = self.msnode_current.msnode_parent.mdict_contents
          return self.ml_cwd
                    
        def ls(self, astr_path=""):
          return self.str_lsnode(astr_path)
        
        def str_lsnode(self, astr_path=""):
          """
          Print/return the set of nodes branching from current node as string
          """
          self.m_str.reset()
          str_cwd       = self.cwd()
          if len(astr_path): self.cdnode(astr_path)
          for node in self.msnode_current.mdict_contents.keys():
            self.m_str.write('%s\n' % node)
          str_ls = self.m_str.strget()
          print str_ls
          if len(astr_path): self.cdnode(str_cwd)
          return str_ls
          
        def lst_lsnode(self, astr_path=""):
          """
          Return the set of nodes branching from current node as list
          """
          self.m_str.reset()
          str_cwd       = self.cwd()
          if len(astr_path): self.cdnode(astr_path)
          lst = self.msnode_current.mdict_contents.keys()
          if len(astr_path): self.cdnode(str_cwd)
          return lst
        
        def lsbranch(self, astr_path=""):
          """
          Print/return the set of nodes in current branch
          """
          self.m_str.reset()
          str_cwd       = self.cwd()
          if len(astr_path): self.cdnode(astr_path)
          self.m_str.write('%s' % self.msbranch_current.mdict_branch.keys())
          str_ls = self.m_str.strget()
          print str_ls
          if len(astr_path): self.cdnode(str_cwd)
          return str_ls
          
        def lstree(self, astr_path=""):
          """
          Print/return the tree from the current node.
          """
          self.m_str.reset()
          str_cwd       = self.cwd()
          if len(astr_path): self.cdnode(astr_path)
          str_ls        = '%s' % self.msnode_current
          print str_ls
          if len(astr_path): self.cdnode(str_cwd)
          return str_ls
          
        def lsmeta(self, astr_path=""):
          """
          Print/return the "meta" information of the node, i.e.
                o mustInclude
                o mustNotInclude
                o hitCount
          """
          self.m_str.reset()
          str_cwd       = self.cwd()
          if len(astr_path): self.cdnode(astr_path)
          b_contentsFlag        = self.msnode_current.mb_printContents
          self.msnode_current.mb_printContents = False
          str_ls        = '%s' % self.msnode_current
          print str_ls
          if len(astr_path): self.cdnode(str_cwd)
          self.msnode_current.mb_printContents  = b_contentsFlag
          return str_ls
          
        def treeRecurse(self, astr_startPath = '/', afunc_nodeEval = None):
          """
          Recursively walk through a C_stree, starting from node
          <astr_startPath>.

          The <afunc_nodeEval> is a function that is called on a node
          path. It is of form:

                afunc_nodeEval(astr_startPath)

          and must return either True or False.
          """
          [b_valid, l_path ] = self.b_pathInTree(astr_startPath)
          if b_valid and afunc_nodeEval:
            b_valid     = afunc_nodeEval(astr_startPath)
          #print 'processing node: %s' % astr_startPath
          if b_valid:
            for node in self.lst_lsnode(astr_startPath):
              if astr_startPath == '/': recursePath = "/%s" % node
              else: recursePath = '%s/%s' % (astr_startPath, node)
              self.treeRecurse(recursePath, afunc_nodeEval)
  
        #
        # Simple error handling
        def error_exit(self, astr_action, astr_error, astr_code):
            print "%s: FATAL error occurred" % self.mstr_obj
            print "While %s," % astr_action
            print "%s" % astr_error
            print "\nReturning to system with code %s\n" % astr_code
            sys.exit(astr_code)

