#!/usr/bin/env python

'''

    This script analyzes cumulative centroid files using the
    'C_centroid_cloud' class.
    
'''

# Sytem imports
import  os
import  sys
import  string
import  argparse
import  socket

# System data organization imports
import  csv
from    collections             import  defaultdict
import  itertools

# Maths / statistical imports
import  scipy.stats             as stats
import  numpy                   as np
import  pylab
from    shapely.geometry        import  Point           as sgPoint
from    shapely.geometry        import  Polygon         as sgPolygon
from    shapely.geometry        import  MultiPolygon    as sgMultiPolygon

# FNNDSC imports
from    _common import systemMisc       as misc
from    _common import crun
from    C_centroidCloud import *
import  error
import  message
import  stage
import  fnndsc  as base


scriptName      = os.path.basename(sys.argv[0])

class FNNDSC_CentroidCloud(base.FNNDSC):
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
            'exitCode'      : 14},
    }


    def l_hemisphere(self):
        return self._l_hemi

    def l_surface(self):
        return self._l_surface

    def l_curv(self):
        return self._l_curv

    def l_gid(self):
        return self._l_gid

    def l_gidComb(self):
        return self._l_gidComb

    def d_centroids(self):
        return self._d_centroids

    def subj(self):
        return self._str_subj

    def surface(self):
        return self._str_surface

    def hemi(self):
        return self._str_hemi

    def curvList(self):
        return self._curvList

    def curv(self):
        return self._str_curv

    def subjDir(self):
        return "%s/%s" % (self._str_workingDir, self._str_subj)

    def analysisDir(self):
        return "%s/%s/%s/%s/%s" % \
            (self.subjDir(), _str_HBWMdir, self._str_hemi, self._str_surface, self._str_curv)

    def startDir(self):
        return self._str_workingDir

    def verbosity(self, *args):
        """
        Get/set the boundary points.
        """
        if len(args):
            self._verbosity = args[0]
        else:
            return self._verbosity

    def showPlots(self, *args):
        """
        Get/set the boundary points.
        """
        if len(args):
            self._showPlots = args[0]
        else:
            return self._showPlots


    def vprint(self, astr_output, averbosity=1):
        '''
        Verbosity-aware print.
        '''
        if self._verbosity >= averbosity:
            print(astr_output)
                    
    def __init__(self, **kwargs):
        '''
        Basic constructor. Checks on named input args, checks that files
        exist and creates directories.

        '''
        base.FNNDSC.__init__(self, **kwargs)

        self._lw                        = 60
        self._rw                        = 20
        self._verbosity                 = 0

        self._b_showPlots               = False

        # Command line arg holders
        self._str_subjectDir            = ''
        self._stageslist                = '0'
        self._hemiList                  = 'lh,rh'
        self._surfaceList               = 'smoothwm,pial'
        self._curvList                  = 'H,K'
        self._str_dataDir               = '-x'
        self._centroidTypeList          = 'pos,neg,natural'
        self._colorSpecList             = 'red,yellow,green,blue,cyan,magenta'
        self._markerSpecList            = '+,d,o,*,x,s,^'

        # List variables
        self._l_subject                 = []
        self._l_hemi                    = self._hemiList.split(',')
        self._l_surface                 = self._surfaceList.split(',')
        self._l_curv                    = self._curvList.split(',')
        self._l_type                    = self._centroidTypeList.split(',')
        self._l_color                   = self._colorSpecList.split(',')
        self._l_marker                  = self._markerSpecList.split(',')

        # Internal tracking vars
        self._str_gid                   = ''
        self._str_subj                  = ''
        self._str_hemi                  = ''
        self._str_surface               = ''
        self._str_curv                  = ''
        self._str_ctype                 = ''
        self._str_markerSpec            = ''

        # Lists for tracking groups
        self._l_gidTotal                = []
        self._l_gid                     = []
        self._str_gidList               = '' # A string of the gid list
        self._l_gidComb                 = []

        # Dictionaries for tracking data trees
        self._d_centroids               = {} # All the centroids per subject
        self._d_cloud                   = {} # Each group's cloud
        self._d_boundary                = {} # Each group's boundary
        self._d_poly                    = {} # Each group's *polygon* boundary
        self._d_polyArea                = {} # Each group's cloud area
        self._d_overlapLR               = {} # The left->right overlap norm
        self._d_overlapRL               = {} # The right->left overlap norm
        
        # Dictionaries containing all the cloud classes
        self._c_cloud                   = {}
        self._zOrderDeviation           = 3;

        # Callback functions executed in the innermost loop of a data
        # dictionary
        self._f_callBack                = lambda **x: True      # function
        self._f_callBackArgs            = {'val': True}         # args
        
        self._str_workingDir            = os.getcwd()
        self._csv                       = None

        for key, value in kwargs.iteritems():
            if key == 'stages':           self._stageslist        = value
            if key == 'dataDir':
                os.chdir(value)
                self._str_dataDir       = os.path.basename(value)
            if key == 'colorSpecList':    self._l_color           = value.split(',')
            if key == 'markerSpecList':   self._l_marker          = value.split(',')
            if key == 'centroidTypeList': self._l_type            = value.split(',')
            if key == 'subjectList':      self._l_subject         = value.split(',')
            if key == 'hemiList':         self._l_hemi            = value.split(',')
            if key == 'surfaceList':      self._l_surface         = value.split(',')
            if key == 'curvList':
                self._l_curv            = value.split(',')
                self._curvList          = value

        # Read initial centroids file to determine number of subjects
        self._str_centroidFile = 'cumulative-centroids-%s.%s.%s.smoothwm.txt' % \
                (self._l_hemi[0], self._l_curv[0], self._str_dataDir)
        self._csv = csv.DictReader(file(self._str_centroidFile, "rb"), delimiter=" ", skipinitialspace=True)
        for entry in self._csv:
            self._l_subject.append(entry['Subj'])
        
        # Build core data dictionary that contains all the centroids
        self._d_centroids               = misc.dict_init(self._l_subject)
        for subj in self._l_subject:
            self._d_centroids[subj]     = misc.dict_init(self._l_hemi)
            for hemi in self._l_hemi:
                self._d_centroids[subj][hemi]   = misc.dict_init(self._l_surface)
                for surf in self._l_surface:
                    self._d_centroids[subj][hemi][surf] = misc.dict_init(self._l_curv)
                    for curv in self._l_curv:
                        self._d_centroids[subj][hemi][surf][curv] = misc.dict_init(self._l_type)

    def centroids_read(self):
        '''
        Reads all the relevant centroid files into internal dictionary.
        '''
        for self._str_hemi in self._l_hemi:
            for self._str_surface in self._l_surface:
                for self._str_curv in self._l_curv:
                    self._str_centroidFile = 'cumulative-centroids-%s.%s.%s.%s.txt' % \
                            (self._str_hemi, self._str_curv, self._str_dataDir,
                            self._str_surface)
                    self._log('Reading centroid file: %s\n' % (self._str_centroidFile))
                    self._csv = csv.DictReader(
                                file(self._str_centroidFile, "rb"),
                                delimiter = " ",
                                skipinitialspace = True)
                    for entry in self._csv:
                        f_xn    = float(entry['xn'])
                        f_yn    = float(entry['yn'])
                        f_xp    = float(entry['xp'])
                        f_yp    = float(entry['yp'])
                        f_xc    = float(entry['xc'])
                        f_yc    = float(entry['yc'])
                        v_n     = np.array( [f_xn, f_yn] )
                        v_p     = np.array( [f_xp, f_yp] )
                        v_c     = np.array( [f_xc, f_yc] )
                        self._d_centroids[entry['Subj']][self._str_hemi][self._str_surface][self._str_curv]['neg'] = v_n
                        self._d_centroids[entry['Subj']][self._str_hemi][self._str_surface][self._str_curv]['pos'] = v_p
                        self._d_centroids[entry['Subj']][self._str_hemi][self._str_surface][self._str_curv]['natural'] = v_c

    def initialize(self):
        '''
        This method provides some "post-constructor" initialization. It is
        typically called after the constructor and after other class flags
        have been set (or reset).
        
        '''

        # First, this script should only be run on cluster nodes.
        lst_clusterNodes = ['rc-drno', 'rc-russia', 'rc-thunderball',
                            'rc-goldfinger', 'rc-twice']
        str_hostname    = socket.gethostname()

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
        
        #for str_subj in self._l_subject:
            #self._log('Checking on subjectDir <%s>' % str_subj,
                        #debug=9, lw=self._lw)
            #if os.path.isdir(str_subj):
                #self._log('[ ok ]\n', debug=9, rw=self._rw, syslog=False)
            #else:
                #self._log('[ not found ]\n', debug=9, rw=self._rw,
                            #syslog=False)
                #error.fatal(self, 'subjectDirnotExist')


    def groupIntersections_initialize(self):
        '''
        Initializes all the combinations of the group IDs, taken two
        at a time. This is used in determining the intersections
        between all pairs of boundary polygons.

        Builds the internal dictionaries that track this information.
        
        '''
        self._str_gidList       = ''.join(self._l_gid)
        self._l_gidComb         = list(itertools.combinations(self._str_gidList, 2))
        for key in range(0, len(self._l_gidComb)):
            self._l_gidComb[key] = ''.join(self._l_gidComb[key])
        self._d_overlapLR       = self.dict_ninit(self._l_gidComb,
                                                  self._l_hemi,
                                                  self._l_surface,
                                                  self._l_curv,
                                                  self._l_type)
        self._d_overlapRL       = self._d_overlapLR.copy()


    def groupIntersections_determine(self, **kwargs):
        '''
        Determines the LR and RL overlap percentages between pairs
        of intersecting polygon groups.
        '''
        group   = self._str_gid
        hemi    = self._str_hemi
        surface = self._str_surface
        curv    = self._str_curv
        ctype   = self._str_ctype

        g1      = group[0]
        g2      = group[1]
        p1      = self._d_poly[g1][hemi][surface][curv][ctype]
        p2      = self._d_poly[g2][hemi][surface][curv][ctype]
        f_ar    = p1.area
        f_al    = p2.area
        f_or    = 0
        f_ol    = 0

        f_overlap = p1.intersection(p2).area
        f_or    = f_overlap / f_ar * 100
        f_ol    = f_overlap / f_al * 100
        _str_fileName = '%s-%s-%s-centroids-analyze-%s.%s.%s.%s' % (ctype, g1, g2, hemi, curv, self._str_dataDir, surface)
        self.vprint("%60s: %10.5f %10.5f" % (_str_fileName, f_ol, f_or), 1)
        self._d_overlapLR[group][hemi][surface][curv][ctype]    = f_ol
        self._d_overlapRL[group][hemi][surface][curv][ctype]    = f_or
        misc.file_writeOnce('%s.txt-overlapL' % _str_fileName, '%s' % f_ol)
        misc.file_writeOnce('%s.txt-overlapR' % _str_fileName, '%s' % f_or)


    def groupTtest_determine(self, **kwargs):
        '''
        Determine the two-sided t-test on all pairwise combinations
        of centroid clouds
        '''
        group   = self._str_gid
        hemi    = self._str_hemi
        surface = self._str_surface
        curv    = self._str_curv
        ctype   = self._str_ctype

        g1      = group[0]
        g2      = group[1]
        v1      = self._d_cloud[g1][hemi][surface][curv][ctype]
        v2      = self._d_cloud[g2][hemi][surface][curv][ctype]

        v_tstat, v_pval = stats.ttest_ind(v1, v2)
        f_pval  = np.linalg.norm(v_pval)
        _str_fileName = '%s-%s-%s-pval-%s.%s.%s.%s' % (ctype, g1, g2, hemi, curv, self._str_dataDir, surface)
        vstr_tstat = ' '.join('%10.6f'%F for F in v_tstat)
        vstr_pval  = ' '.join('%10.6f'%F for F in v_pval)
        self.vprint("%s, pvalue: (%s), pvalueN: %f" %\
            (_str_fileName, vstr_pval, f_pval), 1)
        if f_pval > 0.05:       misc.file_writeOnce('%s-ge5.txt' % _str_fileName, '%f' % f_pval)
        if f_pval <= 0.05:      misc.file_writeOnce('%s-le5.txt' % _str_fileName, '%f' % f_pval)
        if f_pval <= 0.01:      misc.file_writeOnce('%s-le1.txt' % _str_fileName, '%f' % f_pval)


    def groups_determine(self):
        '''
        Analyzes a given centroid table for all subjects and determines the
        number of groups.
        
        PRECONDITIONS
        o self._l_subject list
        
        POSTCONDITIONS
        o self._l_gidTotal
        o self._l_gid
        
        '''
        for subj in self._l_subject:
            self._l_gidTotal.append(subj[0])
        self._l_gid = sorted(set(self._l_gidTotal))

     
    def negCentroid_exists(self, str_curv):
        '''
        Returns a boolean True/False if a negative centroid exists
        for the passed str_curv.
        '''
        ret = True
        l_noNeg = ['C', 'BE', 'S', 'FI', 'thickness']
        if str_curv in l_noNeg: ret = False
        return ret
        
        
    def dict_ninit(self, *l_args):
        '''
        Initialize a "nested" dictionary of multiple shells, each shell
        defined by an l_args[n]
        '''

        _dict = defaultdict(lambda:\
                    defaultdict(lambda:\
                        defaultdict(lambda:\
                            defaultdict(lambda:\
                                defaultdict(np.array)))))
                                
        l_keys = list(itertools.product(*l_args))

        for group, hemi, surface, curv, ctype in l_keys:
            _dict[group][hemi][surface][curv][ctype] = zeros((1,1))
        return _dict


    def internals_build(self):
        '''
        Construct the internal dictionaries that hold analysis data.
        '''
        self._c_cloud           = self.dict_ninit(self._l_gid,
                                                  self._l_hemi,
                                                  self._l_surface,
                                                  self._l_curv,
                                                  self._l_type)

        self._d_cloud           = self.dict_ninit(self._l_gid,
                                                  self._l_hemi,
                                                  self._l_surface,
                                                  self._l_curv,
                                                  self._l_type)

        self._d_boundary        = self.dict_ninit(self._l_gid,
                                                  self._l_hemi,
                                                  self._l_surface,
                                                  self._l_curv,
                                                  self._l_type)

        self._d_poly            = self.dict_ninit(self._l_gid,
                                                  self._l_hemi,
                                                  self._l_surface,
                                                  self._l_curv,
                                                  self._l_type)

        self._d_polyArea        = self.dict_ninit(self._l_gid,
                                                  self._l_hemi,
                                                  self._l_surface,
                                                  self._l_curv,
                                                  self._l_type)



    def innerLoop_hscgt(self, func_callBack, *args, **callBackArgs):
        '''

        A loop function that calls func_callBack(**callBackArgs)
        at the innermost loop the nested data dictionary structure.

        The 'hscgt' refers to the loop order:

            hemi, surface, curv, group, type

        Note that internal tracking object variables, _str_gid ... _str_ctype
        are automatically updated by this script.

        The **callBackArgs is a generic dictionary holder that is interpreted
        by both this loop controller and also passed down to the callback
        function.

        In the context of the loop controller, loop conditions can
        be changed by passing appropriately name args in the
        **callBackArgs structure.

        '''
        ret             = True
        l_hemi          = self._l_hemi
        l_surface       = self._l_surface
        l_curv          = self._l_curv
        l_group         = self._l_gid
        l_type          = self._l_type
        
        for key, val in callBackArgs.iteritems():
            if key == 'hemi':           l_hemi          = val
            if key == 'surface':        l_surface       = val
            if key == 'curv':           l_curv          = val
            if key == 'group':          l_group         = val
            if key == 'ctype':          l_type          = val
        
        for self._str_hemi in l_hemi:
            for self._str_surface in l_surface:
                for self._str_curv in l_curv:
                    for self._str_gid in l_group:
                        for self._str_ctype in l_type:
                            if self._str_ctype == 'neg' and not\
                            self.negCentroid_exists(self._str_curv): continue
                            ret = func_callBack(**callBackArgs)
        return ret

        
    def innerLoop_ghsct(self, func_callBack, **callBackArgs):
        '''

        A loop function that calls func_callBack(**callBackArgs)
        at the innermost loop the nested data dictionary structure.

        The 'ghsct' refers to the loop order:

            gid, hemi, surface, curv, type

        Note that internal tracking object variables, _str_gid ... _str_ctype
        are automatically updated by this script.

        The **callBackArgs is a generic dictionary holder that is interpreted
        by both this loop controller and also passed down to the callback
        function.

        In the context of the loop controller, loop conditions can
        be changed by passing appropriately name args in the
        **callBackArgs structure.
        
        '''
        ret             = True
        l_hemi          = self._l_hemi
        l_surface       = self._l_surface
        l_curv          = self._l_curv
        l_group         = self._l_gid
        l_type          = self._l_type

        for key, val in callBackArgs.iteritems():
            if key == 'hemi':           l_hemi          = val
            if key == 'surface':        l_surface       = val
            if key == 'curv':           l_curv          = val
            if key == 'group':          l_group         = val
            if key == 'ctype':          l_type          = val

        for self._str_gid in l_group:
            for self._str_hemi in l_hemi:
                for self._str_surface in l_surface:
                    for self._str_curv in l_curv:
                        for self._str_ctype in l_type:
                            if self._str_ctype == 'neg' and not\
                            self.negCentroid_exists(self._str_curv): continue
                            ret = func_callBack(**callBackArgs)
        return ret


    def clouds_define(self, **kwargs):
        '''
        '''
        group   = self._str_gid
        hemi    = self._str_hemi
        surface = self._str_surface
        curv    = self._str_curv
        ctype   = self._str_ctype
        
        b_firstElementPerCluster = False
        for subj in self._l_subject:
            if subj[0] == group:
                if not b_firstElementPerCluster:
                    self._d_cloud[group][hemi][surface][curv][ctype] = \
                    self._d_centroids[subj][hemi][surface][curv][ctype]
                    b_firstElementPerCluster = True
                else:
                    self._d_cloud[group][hemi][surface][curv][ctype] = \
                    np.vstack((self._d_cloud[group][hemi][surface][curv][ctype],
                    self._d_centroids[subj][hemi][surface][curv][ctype]))
        self._c_cloud[group][hemi][surface][curv][ctype] = \
            C_centroidCloud(cloud=self._d_cloud[group][hemi][surface][curv][ctype])
        self._c_cloud[group][hemi][surface][curv][ctype].confidenceBoundary_find()
        self._d_boundary[group][hemi][surface][curv][ctype] = \
            self._c_cloud[group][hemi][surface][curv][ctype].boundary()
        return True


    def callback_test(self):
        print "in callback!"


    def boundary_areaAnalyze(self):
        group   = self._str_gid
        hemi    = self._str_hemi
        surface = self._str_surface
        curv    = self._str_curv
        ctype   = self._str_ctype

        _str_fileName = '%s-Ap%s-%s.%s.%s.%s.txt' % (ctype, group, hemi, curv, self._str_dataDir, surface)
        p = sgPolygon(self._d_boundary[group][hemi][surface][curv][ctype])
        self._d_poly[group][hemi][surface][curv][ctype] = p
        f_A = p.area
        self._d_polyArea[group][hemi][surface][curv][ctype] = f_A
        self.vprint("%60s: %10.5f" % (_str_fileName, f_A), 1)
        misc.file_writeOnce(_str_fileName, '%s' % f_A)
      

    def deviation_plot(self, al_points, str_fillColor = 'red', str_edgeColor = 'black'):
        poly    = pylab.Polygon(al_points,
                            facecolor = str_fillColor,
                            edgecolor = str_edgeColor, zorder=self._zOrderDeviation)
        pylab.gca().add_patch(poly)
        return poly
        
        
    def clouds_plot(self):
        '''
        Generate (and save) the actual centroid plot for given parameters.
        Displaying the plot is controlled through the internal self._b_showPlots
        boolean.
        '''
        for hemi in self._l_hemi:
            for surface in self._l_surface:
                for curv in self._l_curv:
                    pylab.figure()
                    pylab.grid()
                    _d_plot     = misc.dict_init(self._l_gid)
                    for group in self._l_gid:
                        for ctype in self._l_type:
                            if ctype == 'natural': continue
                            if ctype == 'neg' and not self.negCentroid_exists(curv):
                                continue
                            _M_cloud = self._c_cloud[group][hemi][surface][curv][ctype].cloud()
                            _v0 = _M_cloud[:,0]
                            _v1 = _M_cloud[:,1]
                            if np.isnan(np.sum(_v0)): continue
                            _str_fileName = '%s-%s-centroids-%s.%s.%s.%s' % (ctype, group, hemi, curv, self._str_dataDir, surface)
                            np.savetxt(_str_fileName, _M_cloud, fmt='%10.7f')
                            self._log("Saving centroid cloud data to %s                    \t\t\t\r" % _str_fileName)
                            _d_plot[group], = plot(_v0, _v1,
                                                    color = self._l_color[int(group)-1],
                                                   marker = self._l_marker[int(group)-1],
                                                       ls = 'None',
                                                   zorder = 1)
                            self.deviation_plot(self._d_boundary[group][hemi][surface][curv][ctype],
                                               self._l_color[int(group)-1])
                    _str_title = '%s.%s.%s.%s' % (hemi, curv, args.dataDir, surface)                           
                    pylab.title(_str_title)
                    pylab.xlabel('group mean cuvature')
                    pylab.ylabel('group expected occurrence')
                    pylab.savefig('centroids-deviationContour-%s.png' % _str_title, bbox_inches=0)
                    pylab.savefig('centroids-deviationContour-%s.pdf' % _str_title, bbox_inches=0)
        if self._b_showPlots: pylab.show()
        self._log('\n')

                
    def run(self):
        '''
        The main 'engine' of the class.

        '''
        base.FNNDSC.run(self)
            
            
def synopsis(ab_shortOnly = False):
    shortSynopsis =  '''
    SYNOPSIS

            %s                            \\
                            [--stages <stages>]                 \\
                            [-v|--verbosity <verboseLevel>]     \\
                            [--dataDir|-d <dataDir>]            \\
                            [--colorSpec|-l <colorSpec>]        \\
                            [--centroidType|-t <centroidType]   \\
                            [--hemi|-h <hemisphere>]            \\
                            [--surface|-f <surface>]            \\
                            [--curv|-c <curvType>
    ''' % scriptName
  
    description =  '''
    DESCRIPTION

        `%s' performs a centroid cloud analysis on the passed
        <Subj> <curvType> <hemi> <surface> specification.

    ARGS

        --dataDir <dataDir>
        The directory containing the centroid table files. These 
        files contain a per-subject list of centroids:

            Subj        xn      yn      xp      yp      xc      yc

        for the negative, positive, and natural centroids.

        --centroidType <centroidType>
        The "type" of centroid to analyze. One (or more) of:

                neg,pos,natural

        --colorSpec <colorSpec>
        A comma-separated string defining the colors to use for each
        centroid cloud. For example,

            'red,yellow,green,blue,cyan,magenta'

        would define six groups, with colors in order as spec'd.
    
        --hemi <hemisphere>
        The hemisphere to process. For both 'left' and 'right', pass
        'lh,rh'.

        --surface <surface>
        The surface to process. One of 'pial' or 'smoothwm'. To process both,
        use 'smoothwm,pial'.

        --curv <curvType> 
        The curvature map function stem name to analyze. The actual curvature
        file is contructed from <hemi>.<surface>.<curvType>.crv.

        --stages|-s <stages>
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


def f_blockOnScheduledJobs(**kwargs):
    '''
    A simple wrapper around a stage.blockOnShellCmd(...)
    call.
    '''
    str_blockCondition  = 'mosq listall | wc -l'
    str_blockProcess    = 'undefined'
    str_blockUntil      = "0"
    timepoll            = 10
    for key, val in kwargs.iteritems():
        if key == 'obj':                stage                   = val
        if key == 'blockCondition':     str_blockCondition      = val
        if key == 'blockUntil':         str_blockUntil          = val
        if key == 'blockProcess':
            str_blockProcess            = val
            str_blockCondition          = 'mosq listall | grep %s | wc -l' % str_blockProcess
        if key == 'timepoll':           timepoll                = val
    str_blockMsg    = '''\n
    Postconditions are still running: multiple '%s' instances
    detected in MOSIX scheduler. Blocking until all scheduled jobs are
    completed. Block interval = %s seconds.
    \n''' % (str_blockProcess, timepoll)
    str_loopMsg     = 'Waiting for scheduled jobs to complete... ' +\
                      '(hit <ctrl>-c to kill this script).    '

    stage.blockOnShellCmd(  str_blockCondition, str_blockUntil,
                            str_blockMsg, str_loopMsg, timepoll)
    return True


        
#
# entry point
#
if __name__ == "__main__":


    # always show the help if no arguments were specified
    if len( sys.argv ) == 1:
        print(synopsis())
        sys.exit( 1 )

    l_subj      = []
    b_query     = False
    verbosity   = 0

    parser = argparse.ArgumentParser(description = synopsis(True))
    
    #parser.add_argument('l_subj',
                        #metavar='SUBJECT', nargs='+',
                        #help='SubjectIDs to process')
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
    parser.add_argument('--dataDir',
                        dest='dataDir',
                        action='store',
                        default='',
                        help='data directory containing centroid files')
    parser.add_argument('--centroidType',
                        dest='centroidType',
                        action='store',
                        default='pos',
                        help='centroid type spec to process')
    parser.add_argument('--colorSpec',
                        dest='colorSpec',
                        action='store',
                        default='',
                        help='colorSpec to process')
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
    parser.add_argument('--reset', '-r',
                        dest='b_reset',
                        action="store_true",
                        default=False)
    parser.add_argument('--curv', '-c',
                        dest='curv',
                        action='store',
                        default='H',
                        help='curvature map to process')
    args = parser.parse_args()

    OSshell = crun.crun()
    OSshell.echo(False)
    OSshell.echoStdOut(False)
    OSshell.detach(False)

    Ccloud = FNNDSC_CentroidCloud(
                        dataDir                 = args.dataDir,
                        colorSpecList           = args.colorSpec,
                        centroidTypeList        = args.centroidType,
                        stages                  = args.stages,
                        hemiList                = args.hemi,
                        surfaceList             = args.surface,
                        curvList                = args.curv,
                        logTo                   = 'CentroidCloud.log',
                        syslog                  = True,
                        logTee                  = True
                        )

    Ccloud.verbosity(args.verbosity)
    pipeline    = Ccloud.pipeline()
    pipeline.poststdout(True)
    pipeline.poststderr(True)

    stage0 = stage.Stage(
                        name            = 'CentroidCloud',
                        fatalConditions = True,
                        syslog          = True,
                        logTo           = 'CentroidCloud-process.log',
                        logTee          = True,
                        )
    def f_stage0callback(**kwargs):
        lst_subj        = []
        for key, val in kwargs.iteritems():
            if key == 'subj':   lst_subj        = val
            if key == 'obj':    stage           = val
            if key == 'pipe':   pipeline        = val
        lst_hemi        = pipeline.l_hemisphere()
        lst_surface     = pipeline.l_surface()
        lst_curv        = pipeline.l_curv()

        pipeline.centroids_read()
        pipeline.groups_determine()

        pipeline.internals_build()

        pipeline.innerLoop_ghsct(pipeline.clouds_define)
        pipeline.innerLoop_hscgt(pipeline.boundary_areaAnalyze)

        pipeline.groupIntersections_initialize()
        pipeline.innerLoop_ghsct(pipeline.groupIntersections_determine,
                                 group=pipeline.l_gidComb())
        pipeline.innerLoop_ghsct(pipeline.groupTtest_determine,
                                 group=pipeline.l_gidComb())
        
        pipeline.clouds_plot()

        os.chdir(pipeline.startDir())
        return True
    stage0.def_stage(f_stage0callback, obj=stage0, pipe=Ccloud)
    stage0.def_postconditions(f_blockOnScheduledJobs, obj=stage0,
                              blockProcess    = 'Ccloud.py')

    Ccloudlog = Ccloud.log()
    Ccloudlog('INIT: (%s) %s %s\n' % (os.getcwd(), scriptName, ' '.join(sys.argv[1:])))
    Ccloud.stage_add(stage0)
    Ccloud.initialize()

    Ccloud.run()
  
