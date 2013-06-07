#!/usr/bin/env python

#
#   ___         __
# .'  _|.--.--.|  |--..-----..----..-----.
# |   _||  |  ||  _  ||  _  ||   _||  _  |
# |__|  |___  ||_____||_____||__|  |___  |
#       |_____|                    |_____|
#
# THE ULTIMATE SCALAR MAPPING FRAMEWORK FOR TRACKVIS (.TRK) FILES
#
#
#
# (c) 2012 FNNDSC, Children's Hospital Boston
#
#

import fnmatch
import matplotlib
matplotlib.use( 'Agg' )  # switch to offscreen rendering
import matplotlib.pyplot as plot
from matplotlib.colors import LogNorm
import multiprocessing
import numpy as np
import os
import scipy.io
import shutil
import subprocess
import sys
import time

import fyborg
import fyborg.colortable
from fyborg.logger import Logger
from fyborg._colors import Colors
from fyborg._common import FNNDSCConsole as c
from fyborg._common import FNNDSCFileIO as io

class FyborgLogic:

  def __init( self ):
    '''
    '''


  def intro( self ):


    intro = Colors.CYAN + """
    
                        _.--'''--._
                      .'           `.
                     /               \\
                  .-'                 '-.
                 /                       \\            .----------------.
                / _.--._           _.--._ \\         __i """ + Colors.RED + """*FYBORG POWER*""" + Colors.CYAN + """ |
               / /      `-._   _.-'      \ \\        '-.________________:
              : :      """ + Colors.RED + """.--._""" + Colors.CYAN + """) (""" + Colors.RED + """_.--.""" + Colors.CYAN + """      : :
              | `.    """ + Colors.RED + """/""" + Colors.CYAN + """    / : \    """ + Colors.RED + """\ """ + Colors.CYAN + """   .' |
              :   `-.___.-':/ \:`-.___.-'   :
               \   _       \:_:/       _   /
                `.' "`-.           .-'" '.'
                  :     `-._   _.-'     :
                  |                     |
                  :     _.--._.--._     :
                   \   ^-.__   __.-^   /
                    `-.     '''     .-'
                       \           /
                      /;`-._____.-';\\
                __..-'/             \\'-..__
           __.-'  _.-'               '-._  `-.__
                                             fsc

                          FYBORG
  >> THE ULTIMATE SCALAR MAPPING FRAMEWORK FOR TRACKVIS FILES <<
                
  (c) 2012 FNNDSC / Boston Children's Hospital
  E-Mail us: dev@babyMRI.org

""" + Colors._CLEAR

    print intro

  def outro( self ):

    outro = Colors.CYAN + """
                            .---.--.       .--.   
                          ,(     ),.`.   .'.--.`. 
                          ; \\   / : \\ ;.'.'    \\ ;
\\                         ; """ + Colors.RED + """_""" + Colors.CYAN + """; :""" + Colors.RED + """_""" + Colors.CYAN + """ :""-/ /-.     ;:
 \\                        ;""" + Colors.RED + """'-""" + Colors.CYAN + """;":""" + Colors.RED + """-'""" + Colors.CYAN + """:"-/ /-._^.   ;:
\\ \\                       :  : ;  ; / /  / \\ \\  ;:
\\\\ \\                      :\\  V  / : :  :   ; ;-';
 \\\\ \\                     ; ;._.':,' ;  ;   : :-' 
\\ \\\\ \\                   : : ; : ;o /-._;   : :   
 \\ \\\\ \\                 _;o; : ; '-'.'.-"`. :-^,  
  \\ \\\\ \\            .-.;:_"  _..--"/ /  _  ;y  ;  
   \\ \\\\ \\         .' / '-,; ::    : :  (o) ;   :  
    \\ \\\\ "-.     /  :    ;: ;;    ; ;     /    :  
bug  : \\\\   \\   :   ;    :: ;;  .' ;._..+:     ;  
     :  \\\\   \\  :  _:    ;: :: /   ; ;  ; ;(o):   
"-.   \\  \\\\   \\/ Y' '.  // ^ \\Y   / /  :  '._.;   
\\  \\   \\  ;"-. ;/     7"" / \\ :.-'.' .';  /  /    
\\\\  \\   \\ :   ":_    :"\\ ;..-^'--" .' /  /  /     
 \\\\  \\   "+.;-"" )._..^-""        /  / .' .'      
  ;"+.;_.-" :--=<___)    __..__  /  :-" .'        
\\ :/_. ;  .-" \\ _____.--""__..--""   ;.-"         
 ":  '+'  __..-\\/\\  ''''T__..___..-":             
  :   :\\."      \\/;     ;: () ;  .-" ;            
   "--q/\\        "      :;    :-"    :            
       \\/;              ;:    ;   ..-(            
        "               :-\\__/-+""-. .^.          
                         ; \\  (     \\;  `.        
                        /`. `-/\\ ,=. '.   `.      
                       : \\ \\ :"-:/ .`. \\    \\     
                       ;  ; ;;"-;\\/ .'`."-.  ;    
                      :   : ;"-.: \\/ .' j  "-:    
                      ;   : :"-.;  `: ,' ;    \\   
                     :    : :"-:     "..':     ;  
                     ;    ; ;"-;       `=;  ;  :  
""" + Colors._CLEAR

    print outro

  def run( self, input, output, radius, length, stage, cortex_only, verbose ):
    '''
    '''

    if stage == 0:
      # create output directory
      # but not if we start with a different stage
      os.mkdir( output )

    # activate log file
    self.__debug = verbose
    self.__logger = Logger( os.path.join( output, 'log.txt' ), verbose )
    sys.stdout = self.__logger
    sys.stderr = self.__logger

    # the input data
    _inputs = {'adc':[ '*adc.nii', None],
              'b0':[ '*b0.nii', None],
              'b0_resampled':[ '*_b0_resampled.nii.gz', None],
              'e1':['*e1.nii', None],
              'e2':[ '*e2.nii', None],
              'e3':[ '*e3.nii', None],
              'fa':[ '*fa.nii', None],
              'fibers':['*streamline.trk', '*/final-trackvis/*.trk', None],
              'segmentation': ['*aparc+aseg.mgz', None],
              'T1':['*T1.mgz', None]
              # 'T1':['*T1-TO-b0.nii.gz', None],
              # 'T1toB0matrix':['*T1-TO-b0.mat', None]
              }

    # the output data
    _outputs = {'T1':os.path.join( output, 'T1-to-b0.nii' ),
                'segmentation':os.path.join( output, 'aparc+aseg-to-b0.nii' ),
                'T1toB0matrix':os.path.join( output, 'T1-to-b0.mat' ),
                'b0':os.path.join( output, 'dti_b0.nii' ),
                'adc':os.path.join( output, 'dti_adc.nii' ),
                'fa':os.path.join( output, 'dti_fa.nii' ),
                'e1':os.path.join( output, 'dti_e1.nii' ),
                'e2':os.path.join( output, 'dti_e2.nii' ),
                'e3':os.path.join( output, 'dti_e3.nii' ),
                'fibers':os.path.join( output, 'fybers.trk' ),
                'fibers_mapped':os.path.join( output, 'fybers_mapped.trk' ),
                'fibers_mapped_length_filtered':os.path.join( output, 'fybers_mapped_length_filtered.trk' ),
                'fibers_mapped_length_filtered_cortex_only':os.path.join( output, 'fybers_mapped_length_filtered_cortex_only.trk' ),
                'fibers_final':os.path.join( output, 'fybers_final.trk' ),
                'matrix_all': os.path.join( output, 'matrix_all.mat' ),
                'matrix_fibercount': os.path.join( output, 'matrix_fibercount.csv' ),
                'matrix_length': os.path.join( output, 'matrix_length.csv' ),
                'matrix_adc': os.path.join( output, 'matrix_adc.csv' ),
                'matrix_inv_adc': os.path.join( output, 'matrix_inv_adc.csv' ),
                'matrix_fa': os.path.join( output, 'matrix_fa.csv' ),
                'matrix_e1': os.path.join( output, 'matrix_e1.csv' ),
                'matrix_e2': os.path.join( output, 'matrix_e2.csv' ),
                'matrix_e3': os.path.join( output, 'matrix_e3.csv' ),
                'roi':os.path.join( output, 'roi' )
                }

    self.intro()

    # 4 x beep
    print '\a\a\a\a\a\a\a'

    # time.sleep( 3 )

    # stage 1
    c.info( Colors.YELLOW + '>> STAGE [' + Colors.PURPLE + '1' + Colors.YELLOW + ']: ' + Colors.YELLOW + ' ANALYZING INPUT DATA' + Colors._CLEAR )

    if stage <= 2:  # we can never skip stage 1 without skipping stage 2
      _inputs = self.analyze_input_data( input, _inputs )
    else:
      c.info( Colors.PURPLE + '  skipping it..' + Colors._CLEAR )

    # stage 2
    c.info( Colors.YELLOW + '>> STAGE [' + Colors.PURPLE + '2' + Colors.YELLOW + ']: ' + Colors.YELLOW + ' PREPROCESSING' + Colors._CLEAR )

    if stage <= 2:
      self.preprocessing( _inputs, _outputs )
    else:
      c.info( Colors.PURPLE + '  skipping it..' + Colors._CLEAR )

    # stage 3
    c.info( Colors.YELLOW + '>> STAGE [' + Colors.PURPLE + '3' + Colors.YELLOW + ']: ' + Colors.YELLOW + ' MAPPING' + Colors._CLEAR )

    if stage <= 3:
      self.mapping( _inputs, _outputs, radius )
    else:
      c.info( Colors.PURPLE + '  skipping it..' + Colors._CLEAR )

    c.info( Colors.YELLOW + '>> STAGE [' + Colors.PURPLE + '4' + Colors.YELLOW + ']: ' + Colors.YELLOW + ' FILTERING' + Colors._CLEAR )

    if stage <= 4:
      self.filtering( _inputs, _outputs, length, cortex_only )
    else:
      c.info( Colors.PURPLE + '  skipping it..' + Colors._CLEAR )

    c.info( Colors.YELLOW + '>> STAGE [' + Colors.PURPLE + '5' + Colors.YELLOW + ']: ' + Colors.YELLOW + ' CONNECTIVITY MATRICES' + Colors._CLEAR )

    if stage <= 5:
      self.connectivity( _inputs, _outputs, cortex_only )
    else:
      c.info( Colors.PURPLE + '  skipping it..' + Colors._CLEAR )

    c.info( Colors.YELLOW + '>> STAGE [' + Colors.PURPLE + '6' + Colors.YELLOW + ']: ' + Colors.YELLOW + ' ROI EXTRACTION' + Colors._CLEAR )

    if stage <= 6:
      self.roi_extract( _inputs, _outputs )
    else:
      c.info( Colors.PURPLE + '  skipping it..' + Colors._CLEAR )



    self.outro()
    c.info( '' )
    c.info( 'ALL DONE! SAYONARA..' )

  def preprocessing( self, inputs, outputs ):
    '''
    Co-Register the input files using Flirt.
    '''

    # copy T1-to-b0 and segmentation
    # shutil.copyfile(inputs['T1'][-1], outputs['T1']+'.gz')

    # copy transformation matrix
    # shutil.copyfile(inputs['T1toB0matrix'][-1], outputs['T1toB0matrix'])


    # convert the T1.mgz to T1.nii
    cmd = 'ss;'
    cmd += 'chb-fsstable;'
    cmd += 'mri_convert ' + inputs['T1'][-1] + ' ' + outputs['T1']
    c.info( Colors.YELLOW + '  Converting ' + Colors.PURPLE + 'T1.mgz' + Colors.YELLOW + ' to ' + Colors.PURPLE + 'T1.nii' + Colors.YELLOW + '!' + Colors._CLEAR )
    sp = subprocess.Popen( ["/bin/bash", "-i", "-c", cmd], stdout=sys.stdout )
    sp.communicate()

    # convert aparc+aseg.mgz to aparc+aseg.nii.gz
    cmd = 'ss;'
    cmd += 'chb-fsstable;'
    cmd += 'mri_convert ' + inputs['segmentation'][-1] + ' ' + outputs['segmentation']
    c.info( Colors.YELLOW + '  Converting ' + Colors.PURPLE + 'aparc+aseg.mgz' + Colors.YELLOW + ' to ' + Colors.PURPLE + 'aparc+aseg.nii' + Colors.YELLOW + '!' + Colors._CLEAR )
    sp = subprocess.Popen( ["/bin/bash", "-i", "-c", cmd], stdout=sys.stdout )
    sp.communicate()

    # register T1 to B0
    cmd = 'ss;'
    cmd += 'chb-fsstable;'
    flirtcmd = 'flirt -in ' + outputs['T1'] + ' -ref ' + inputs['b0'][-1] + ' -usesqform -nosearch -dof 6 -cost mutualinfo -out ' + outputs['T1'] + '.gz -omat ' + outputs['T1toB0matrix'] + ';'
    cmd += flirtcmd
    self.__logger.debug( flirtcmd )
    c.info( Colors.YELLOW + '  Registering ' + Colors.PURPLE + 'T1.nii' + Colors.YELLOW + ' to ' + Colors.PURPLE + os.path.split( outputs['T1'] )[1] + Colors.YELLOW + ' and storing ' + Colors.PURPLE + os.path.split( outputs['T1toB0matrix'] )[1] + Colors.YELLOW + '!' + Colors._CLEAR )
    sp = subprocess.Popen( ["/bin/bash", "-i", "-c", cmd], stdout=sys.stdout )
    sp.communicate()

    # resample aparc+aseg to DTI space

    # ideally use the b0_resampled but only if it exists
    if not inputs['b0_resampled'][-1]:
      inputs['b0_resampled'][-1] = inputs['b0'][-1]
      c.info( Colors.YELLOW + '  Using ' + Colors.PURPLE + ' original b0 and *NOT* the resampled version.' + Colors._CLEAR )

    cmd = 'ss;'
    cmd += 'chb-fsstable;'
    flirtcmd = 'flirt -in ' + outputs['segmentation'] + ' -ref ' + inputs['b0_resampled'][-1] + ' -out ' + outputs['segmentation'] + '.gz -init ' + outputs['T1toB0matrix'] + ' -applyxfm -interp nearestneighbour;'
    cmd += flirtcmd
    self.__logger.debug( flirtcmd )
    c.info( Colors.YELLOW + '  Resampling ' + Colors.PURPLE + os.path.split( outputs['segmentation'] )[1] + Colors.YELLOW + ' as ' + Colors.PURPLE + os.path.split( outputs['segmentation'] )[1] + Colors.YELLOW + ' using ' + Colors.PURPLE + os.path.split( outputs['T1toB0matrix'] )[1] + Colors.YELLOW + '!' + Colors._CLEAR )
    sp = subprocess.Popen( ["/bin/bash", "-i", "-c", cmd], stdout=sys.stdout )
    sp.communicate()

    # unzip T1-to-b0 and segmentation
    cmd = 'gzip -d -f ' + outputs['T1'] + '.gz;'
    cmd += 'gzip -d -f ' + outputs['segmentation'] + '.gz;'
    sp = subprocess.Popen( ["/bin/bash", "-i", "-c", cmd], stdout=sys.stdout )
    sp.communicate()

    # copy all dti volumes and fibers
    for i in inputs:

      if i == 'segmentation' or i == 'T1' or i == 'T1toB0matrix' or i == 'b0_resampled':
        # we do not map these
        continue
      c.info( Colors.YELLOW + '  Copying ' + Colors.PURPLE + os.path.split( inputs[i][-1] )[1] + Colors.YELLOW + ' to ' + Colors.PURPLE + os.path.split( outputs[i] )[1] + Colors.YELLOW + '!' + Colors._CLEAR )
      shutil.copyfile( inputs[i][-1], outputs[i] )


  def mapping( self, inputs, outputs, radius ):
    '''
    Map all detected scalar volumes to each fiber.
    '''

    # check if we have all required input data
    # we need at least:
    #  - outputs['fibers'] == Track file in T1 space
    #  - outputs['segmentation'] == Label Map
    if not os.path.exists( outputs['fibers'] ):
      c.error( Colors.RED + 'Could not find ' + Colors.YELLOW + outputs['fibers'] + Colors.RED + ' but we really need it to start with stage 3!!' + Colors._CLEAR )
      sys.exit( 2 )
    if not os.path.exists( outputs['segmentation'] ):
      c.error( Colors.RED + 'Could not find ' + Colors.YELLOW + outputs['segmentation'] + Colors.RED + ' but we really need it to start with stage 3!!' + Colors._CLEAR )
      sys.exit( 2 )

    actions = []

    for i in inputs:

      if i == 'fibers' or i == 'segmentation' or i == 'T1' or i == 'b0' or i == 'T1toB0matrix' or i == 'b0_resampled':
        # we do not map these
        continue

      if not os.path.exists( outputs[i] ):
        # we can't map this since we didn't find the file
        continue

      # for normal scalars: append it to the actions
      actions.append( fyborg.FyMapAction( i, outputs[i] ) )

      c.info( Colors.YELLOW + '  Configuring mapping of ' + Colors.PURPLE + os.path.split( outputs[i] )[1] + Colors.YELLOW + ' to ' + Colors.PURPLE + os.path.split( outputs['fibers'] )[1] + Colors.YELLOW + '!' + Colors._CLEAR )

    # now the segmentation with the lookaround radius
    actions.append( fyborg.FyRadiusMapAction( 'segmentation', outputs['segmentation'], radius ) )
    c.info( Colors.YELLOW + '  Configuring mapping of ' + Colors.PURPLE + os.path.split( outputs['segmentation'] )[1] + Colors.YELLOW + ' to ' + Colors.PURPLE + os.path.split( outputs['fibers'] )[1] + Colors.YELLOW + '!' + Colors._CLEAR )

    # and also the fiber length
    actions.append( fyborg.FyLengthAction() )
    c.info( Colors.YELLOW + '  Configuring mapping of ' + Colors.PURPLE + 'fiber length' + Colors.YELLOW + ' to ' + Colors.PURPLE + os.path.split( outputs['fibers'] )[1] + Colors.YELLOW + '!' + Colors._CLEAR )

    # run, forest, run!!
    c.info( Colors.YELLOW + '  Performing configured mapping for ' + Colors.PURPLE + os.path.split( outputs['fibers'] )[1] + Colors.YELLOW + ' and storing as ' + Colors.PURPLE + os.path.split( outputs['fibers_mapped'] )[1] + Colors.YELLOW + ' (~ 30 minutes)!' + Colors._CLEAR )
    if self.__debug:
      fyborg.fyborg( outputs['fibers'], outputs['fibers_mapped'], actions, 'debug' )
    else:
      fyborg.fyborg( outputs['fibers'], outputs['fibers_mapped'], actions )


  def filtering( self, inputs, outputs, length, cortex_only ):
    '''
    Filter the mapped fibers.
    '''

    # check if we have all required input data
    # we need at least:
    #  - outputs['fibers_mapped'] == Track file in T1 space with mapped scalars
    if not os.path.exists( outputs['fibers_mapped'] ):
      c.error( Colors.RED + 'Could not find ' + Colors.YELLOW + outputs['fibers_mapped'] + Colors.RED + ' but we really need it to start with stage 4!!' + Colors._CLEAR )
      sys.exit( 2 )

    # find the order of the mapped scalars
    header = io.loadTrkHeaderOnly( outputs['fibers_mapped'] )
    scalars = list( header['scalar_name'] )

    # split the length range
    length = length.split( ' ' )
    min_length = int( length[0] )
    max_length = int( length[1] )

    # length filtering

    c.info( Colors.YELLOW + '  Filtering ' + Colors.PURPLE + 'fiber length' + Colors.YELLOW + ' to be ' + Colors.PURPLE + '>' + str( min_length ) + ' and <' + str( max_length ) + Colors.YELLOW + ' for ' + Colors.PURPLE + os.path.split( outputs['fibers_mapped'] )[1] + Colors.YELLOW + ' and store as ' + Colors.PURPLE + os.path.split( outputs['fibers_mapped_length_filtered'] )[1] + Colors.YELLOW + '!' + Colors._CLEAR )
    fyborg.fyborg( outputs['fibers_mapped'], outputs['fibers_mapped_length_filtered'], [fyborg.FyFilterLengthAction( scalars.index( 'length' ), min_length, max_length )] )

    header = io.loadTrkHeaderOnly( outputs['fibers_mapped_length_filtered'] )
    new_count = header['n_count']

    c.info( Colors.YELLOW + '  Number of tracks after ' + Colors.PURPLE + 'length filtering' + Colors.YELLOW + ': ' + str( new_count ) + Colors.YELLOW + Colors._CLEAR )

    if cortex_only:

      # special cortex filtering

      c.info( Colors.YELLOW + '  Filtering for ' + Colors.PURPLE + 'valid cortex structures' + Colors.YELLOW + ' in ' + Colors.PURPLE + os.path.split( outputs['fibers_mapped_length_filtered'] )[1] + Colors.YELLOW + ' and store as ' + Colors.PURPLE + os.path.split( outputs['fibers_mapped_length_filtered_cortex_only'] )[1] + Colors.YELLOW + '!' + Colors._CLEAR )
      c.info( Colors.PURPLE + '    Conditions for valid fibers:' + Colors._CLEAR )
      c.info( Colors.PURPLE + '    1.' + Colors.YELLOW + ' The fiber track has to pass through the cerebral white matter. (Label values: ' + Colors.PURPLE + '[2, 41]' + Colors.YELLOW + ')' + Colors._CLEAR )
      c.info( Colors.PURPLE + '    2.' + Colors.YELLOW + ' The fiber track shall only touch sub-cortical structures not more than ' + Colors.PURPLE + '5 times' + Colors.YELLOW + '. (Label values: ' + Colors.PURPLE + '[10, 49, 16, 28, 60, 4, 43]' + Colors.YELLOW + ')' + Colors._CLEAR )
      c.info( Colors.PURPLE + '    3.' + Colors.YELLOW + ' The track shall not pass through the corpus callosum (Labels: ' + Colors.PURPLE + '[251, 255]' + Colors.YELLOW + ') and end in the same hemisphere (Labels: ' + Colors.PURPLE + '[1000-1035]' + Colors.YELLOW + ' for left, ' + Colors.PURPLE + '[2000-2035]' + Colors.YELLOW + ' for right).' + Colors._CLEAR )

      fyborg.fyborg( outputs['fibers_mapped_length_filtered'], outputs['fibers_mapped_length_filtered_cortex_only'], [fyborg.FyFilterCortexAction( scalars.index( 'segmentation' ) )] )

      header = io.loadTrkHeaderOnly( outputs['fibers_mapped_length_filtered_cortex_only'] )
      new_count = header['n_count']

      c.info( Colors.YELLOW + '  Number of tracks after ' + Colors.PURPLE + 'cortex filtering' + Colors.YELLOW + ': ' + str( new_count ) + Colors.YELLOW + Colors._CLEAR )

      c.info( Colors.YELLOW + '  Copied filtered tracks from ' + Colors.PURPLE + os.path.split( outputs['fibers_mapped_length_filtered_cortex_only'] )[1] + Colors.YELLOW + ' to ' + Colors.PURPLE + os.path.split( outputs['fibers_final'] )[1] + Colors.YELLOW + '!' + Colors._CLEAR )
      shutil.copyfile( outputs['fibers_mapped_length_filtered_cortex_only'], outputs['fibers_final'] )

    else:

      c.info( Colors.YELLOW + '  Info: ' + Colors.PURPLE + 'Cortical _and_ sub-cortical structures ' + Colors.YELLOW + 'will be included..' + Colors._CLEAR )

      c.info( Colors.YELLOW + '  Copied filtered tracks from ' + Colors.PURPLE + os.path.split( outputs['fibers_mapped_length_filtered'] )[1] + Colors.YELLOW + ' to ' + Colors.PURPLE + os.path.split( outputs['fibers_final'] )[1] + Colors.YELLOW + '!' + Colors._CLEAR )
      shutil.copyfile( outputs['fibers_mapped_length_filtered'], outputs['fibers_final'] )



  def connectivity( self, inputs, outputs, cortex_only ):
    '''
    Generate connectivity matrices using mapped values.
    '''
    # check if we have all required input data
    # we need at least:
    #  - outputs['fibers_mapped'] == Track file in T1 space with mapped scalars
    if not os.path.exists( outputs['fibers_final'] ):
      c.error( Colors.RED + 'Could not find ' + Colors.YELLOW + outputs['fibers_final'] + Colors.RED + ' but we really need it to start with stage 5!!' + Colors._CLEAR )
      sys.exit( 2 )

    s = io.loadTrk( outputs['fibers_final'] )
    tracks = s[0]
    header = s[1]

    scalarNames = header['scalar_name'].tolist()
    matrix = {}
    indices = {}

    # check if the segmentation is mapped
    try:
      indices['segmentation'] = scalarNames.index( 'segmentation' )
    except:
      c.error( Colors.RED + 'Could not find ' + Colors.YELLOW + 'segmentation' + Colors.RED + ' as a mapped scalar but we really need it!' )
      sys.exit( 2 )

    if cortex_only:
      labels = [2012, 2019, 2032, 2014, 2020, 2018, 2027, 2028, 2003, 2024, 2017, 2026, 2002, 2023, 2010, 2022, 2031, 2029, 2008, 2025, 2005, 2021, 2011, 2013, 2007, 2016, 2006, 2033, 2009, 2015, 2001, 2030, 2034, 2035, 1012, 1019, 1032, 1014, 1020, 1018, 1027, 1028, 1003, 1024, 1017, 1026, 1002, 1023, 1010, 1022, 1031, 1029, 1008, 1025, 1005, 1021, 1011, 1013, 1007, 1016, 1006, 1033, 1009, 1015, 1001, 1030, 1034, 1035]
    else:
      labels = [2012, 2019, 2032, 2014, 2020, 2018, 2027, 2028, 2003, 2024, 2017, 2026, 2002, 2023, 2010, 2022, 2031, 2029, 2008, 2025, 2005, 2021, 2011, 2013, 2007, 2016, 2006, 2033, 2009, 2015, 2001, 2030, 2034, 2035, 49, 50, 51, 52, 58, 53, 54, 1012, 1019, 1032, 1014, 1020, 1018, 1027, 1028, 1003, 1024, 1017, 1026, 1002, 1023, 1010, 1022, 1031, 1029, 1008, 1025, 1005, 1021, 1011, 1013, 1007, 1016, 1006, 1033, 1009, 1015, 1001, 1030, 1034, 1035, 10, 11, 12, 13, 26, 17, 18, 16]

    c.info( Colors.YELLOW + '  Getting ready to create connectivity matrices for the following labels: ' + Colors.PURPLE + str( labels ) + Colors._CLEAR )
    c.info( Colors.YELLOW + '  Note: Mapped scalar values along the points will be averaged for each fiber track.' + Colors._CLEAR )

    # create matrices for the attached scalars
    for i, s in enumerate( scalarNames ):

      if i >= header['n_scalars']:
        break

      if not s or s == 'segmentation':
        continue

      # this is a scalar value for which a matrix will be created
      matrix[s] = np.zeros( [len( labels ), len( labels )] )
      indices[s] = scalarNames.index( s )
      c.info( Colors.YELLOW + '  Preparing matrix (' + Colors.PURPLE + '[' + str( len( labels ) ) + 'x' + str( len( labels ) ) + ']' + Colors.YELLOW + ') for ' + Colors.PURPLE + s + Colors.YELLOW + ' values!' + Colors._CLEAR )

      if s == 'adc':
        s = 'inv_adc'
        matrix[s] = np.zeros( [len( labels ), len( labels )] )
        indices[s] = scalarNames.index( 'adc' )
        c.info( Colors.YELLOW + '  Preparing matrix (' + Colors.PURPLE + '[' + str( len( labels ) ) + 'x' + str( len( labels ) ) + ']' + Colors.YELLOW + ') for ' + Colors.PURPLE + s + Colors.YELLOW + ' values!' + Colors._CLEAR )


    # always create one for the fiber counts
    matrix['fibercount'] = np.zeros( [len( labels ), len( labels )] )
    indices['fibercount'] = 0
    c.info( Colors.YELLOW + '  Preparing matrix (' + Colors.PURPLE + '[' + str( len( labels ) ) + 'x' + str( len( labels ) ) + ']' + Colors.YELLOW + ') for ' + Colors.PURPLE + 'fibercount' + Colors.YELLOW + ' values!' + Colors._CLEAR )

    c.info( Colors.YELLOW + '  Analyzing fibers of ' + Colors.PURPLE + os.path.split( outputs['fibers_final'] )[1] + Colors.YELLOW + '..' + Colors._CLEAR )
    for tCounter, t in enumerate( tracks ):

      tCoordinates = t[0]
      tScalars = t[1]

      # find the segmentation labels for the start and end points
      start_label = tScalars[0, indices['segmentation']]
      end_label = tScalars[-1, indices['segmentation']]

      try:
        # now grab the index of the labels in our label list
        start_index = labels.index( start_label )
        end_index = labels.index( end_label )
      except:
        # this label is not monitored, so ignore this track
        continue

      # loop through all different scalars
      for m in matrix:

        # calculate the mean for each track
        value = np.mean( tScalars[:, indices[m]] )

        if m == 'inv_adc':
          # invert the value since it is 1-ADC
          value = 1 / value
        elif m == 'fibercount':
          # in the case of fibercount, add 1
          value = 1

        # store value in the matrix
        matrix[m][start_index, end_index] += value
        if not start_index == end_index:
          matrix[m][end_index, start_index] += value

    # fiber loop is done, all values are stored
    # now normalize the matrices
    np.seterr( all='ignore' )  # avoid div by 0 warnings
    cbar = None
    for m in matrix:
      if not m == 'fibercount':
        # normalize it
        matrix[m][:] /= matrix['fibercount']
        matrix[m] = np.nan_to_num( matrix[m] )

      # store the matrix
      c.info( Colors.YELLOW + '  Storing ' + Colors.PURPLE + m + Colors.YELLOW + ' connectivity matrix as ' + Colors.PURPLE + os.path.split( outputs['matrix_' + m] )[1] + Colors.YELLOW + '!' + Colors._CLEAR )
      np.savetxt( outputs['matrix_' + m], matrix[m], delimiter='\t' )

      # store a picture
      picture_path = os.path.splitext( os.path.split( outputs['matrix_' + m] )[1] )[0] + '.png'
      c.info( Colors.YELLOW + '  Generating ' + Colors.PURPLE + m + ' image' + Colors.YELLOW + ' as ' + Colors.PURPLE + picture_path + Colors.YELLOW + '!' + Colors._CLEAR )
      img = plot.imshow( matrix[m], interpolation='nearest' )
      img.set_cmap( 'jet' )
      img.set_norm( LogNorm() )
      img.axes.get_xaxis().set_visible( False )
      img.axes.get_yaxis().set_visible( False )
      if not cbar:
        cbar = plot.colorbar()
      cbar.set_label( m )
      cbar.set_ticks( [] )
      plot.savefig( os.path.join( os.path.split( outputs['matrix_' + m] )[0], picture_path ) )

    np.seterr( all='warn' )  # reactivate div by 0 warnings

    # now store the matlab version as well
    c.info( Colors.YELLOW + '  Storing ' + Colors.PURPLE + 'matlab data bundle' + Colors.YELLOW + ' containing ' + Colors.PURPLE + 'all matrices' + Colors.YELLOW + ' as ' + Colors.PURPLE + os.path.split( outputs['matrix_all'] )[1] + Colors.YELLOW + '!' + Colors._CLEAR )
    scipy.io.savemat( outputs['matrix_all'], matrix, oned_as='row' )


  def roi_extract( self, inputs, outputs ):
    '''
    '''
    # check if we have all required input data
    # we need at least:
    #  - outputs['fibers_mapped'] == Track file in T1 space with mapped scalars
    if not os.path.exists( outputs['fibers_final'] ):
      c.error( Colors.RED + 'Could not find ' + Colors.YELLOW + outputs['fibers_final'] + Colors.RED + ' but we really need it to start with stage 6!!' + Colors._CLEAR )
      sys.exit( 2 )

    s = io.loadTrk( outputs['fibers_final'] )
    tracks = s[0]
    header = s[1]

    scalarNames = header['scalar_name'].tolist()
    labels = {}

    # check if the segmentation is mapped
    try:
      seg_index = scalarNames.index( 'segmentation' )
    except:
      c.error( Colors.RED + 'Could not find ' + Colors.YELLOW + 'segmentation' + Colors.RED + ' as a mapped scalar but we really need it!' )
      sys.exit( 2 )

    # create the roi subfolder
    if not os.path.exists( outputs['roi'] ):
      os.mkdir( outputs['roi'] )

    # parse the color table
    lut = fyborg.colortable.freesurfer.split( '\n' )
    colors = {}
    for color in lut:
      if not color or color[0] == '#':
        continue

      splitted_line = color.split( ' ' )
      splitted_line = filter( None, splitted_line )
      colors[splitted_line[0]] = splitted_line[1]


    # loop through tracks
    for i, t in enumerate( tracks ):

      tCoordinates = t[0]
      tScalars = t[1]

      # grab the scalars for each point
      for scalar in tScalars:

        # but only the label value
        label_value = str( int( scalar[seg_index] ) )

        if not label_value in labels:

          labels[label_value] = []

        if not i in labels[label_value]:
          # store the unique fiber id for this label
          labels[label_value].append( i )

    # now loop through all detected labels
    for l in labels:

      new_tracks = []

      for t_id in labels[l]:
        # grab the fiber + scalars
        current_fiber = tracks[t_id]

        new_tracks.append( current_fiber )

      # now store the trk file
      trk_outputfile = l + '_' + colors[l] + '.trk'
      nii_outputfile = l + '_' + colors[l] + '.nii.gz'
      c.info( Colors.YELLOW + '  Creating fiber ROI ' + Colors.PURPLE + trk_outputfile + Colors.YELLOW + '!' + Colors._CLEAR )
      io.saveTrk( os.path.join( outputs['roi'], trk_outputfile ), new_tracks, header, None, True )

      # also create a roi label volume for this label value
      c.info( Colors.YELLOW + '  Creating NII ROI ' + Colors.PURPLE + nii_outputfile + Colors.YELLOW + '!' + Colors._CLEAR )
      cmd = 'ss;'
      cmd += 'chb-fsstable;'
      cmd += 'mri_binarize --i ' + outputs['segmentation'] + ' --o ' + os.path.join( outputs['roi'], nii_outputfile ) + ' --match ' + l + ' --binval ' + l + ';'
      self.__logger.debug( cmd )
      sp = subprocess.Popen( ["/bin/bash", "-i", "-c", cmd], stdout=sys.stdout )
      sp.communicate()



  def analyze_input_data( self, input_directory, inputs ):
    '''
    Scan an input directory for all kind of inputs. Connectome Pipeline output has 
    higher priority than Tractography Pipeline output since the Connectome pipeline 
    also includes the Tractography output.
    
    Returns a dictionary of found files.
    '''
    for root, dirs, files in os.walk( input_directory ):

      dirs.sort()

      for f in files:
        fullpath = os.path.join( root, f )

        # try to find the files
        for _f in inputs:

          # don't check if we already found this one
          if inputs[_f][-1] != None:
            continue

          for _mask in inputs[_f][:-1]:

            if fnmatch.fnmatch( fullpath, _mask ):
              # this matches our regex
              c.info( Colors.YELLOW + '  Found ' + Colors.PURPLE + f + Colors.YELLOW + '!' + Colors._CLEAR )
              self.__logger.debug( 'Full path: ' + fullpath )
              inputs[_f][-1] = fullpath
              # time.sleep( 1 )
              # don't consider any other option
              break

    return inputs



# ENTRYPOINT
if __name__ == "__main__":

  # 1) scan input directory
  # 2) preform preprocessing
  # 3) perform mapping
  # 4) perform filtering
  # 5) create connectivity matrices

  parser = fyborg._common.FNNDSCParser( description='fyborg - THE ULTIMATE SCALAR MAPPING FRAMEWORK FOR TRACKVIS (.TRK) FILES' )


  parser.add_argument( '-i', '--input', action='store', dest='input', required=True, help='The input folder which gets scanned automatically for usable volume- and track-files.' )
  parser.add_argument( '-o', '--output', action='store', dest='output', required=True, help='The output folder which gets created if it does not exit' )
  parser.add_argument( '-r', '--radius', action='store', dest='radius', default=3, type=int, help='The look-a-round radius in voxels. E.g. --radius 10, DEFAULT: 3' )
  parser.add_argument( '-l', '--length', action='store', dest='length', default="20 200", help='The lower and upper borders for length thresholding in mm. E.g. --length "60 100", DEFAULT "20 200" ' )
  parser.add_argument( '-co', '--cortex_only', action='store_true', dest='cortex_only', help='Perform filtering for cortex specific analysis and skip sub-cortical structures.' )
  parser.add_argument( '-s', '--stage', action='store', dest='stage', default=0, type=int, help='Start with a specific stage while skipping the ones before. E.g. --stage 3 directly starts the mapping without preprocessing, --stage 4 starts with the filtering' )
  parser.add_argument( '-overwrite', '--overwrite', action='store_true', dest='overwrite', help='Overwrite any existing output. DANGER!!' )
  parser.add_argument( '-v', '--verbose', action='store_true', dest='verbose', help='Show verbose output' )

  # always show the help if no arguments were specified
  if len( sys.argv ) == 1:
    parser.print_help()
    sys.exit( 1 )

  options = parser.parse_args()

  # validate the inputs here
  if not os.path.isdir( options.input ):

    c.error( Colors.RED + 'Could not find the input directory! Specify a valid directory using -i $PATH.' + Colors._CLEAR )
    sys.exit( 2 )

  if os.path.exists( options.output ) and int( options.stage ) == 0:

    if not options.overwrite:
      c.error( Colors.RED + 'The output directory exists! Add --overwrite to erase previous content!' + Colors._CLEAR )
      c.error( Colors.RED + 'Or use --stage > 2 to start with a specific stage which re-uses the previous content..' + Colors._CLEAR )
      sys.exit( 2 )
    else:
      # silently delete the existing output
      shutil.rmtree( options.output )

  if options.stage > 0 and not os.path.exists( options.output ):
    # we start with a specific stage so we need the output stuff
    c.error( Colors.RED + 'The output directory does not exist! We need it when using -s/--stage to resume the process!' + Colors._CLEAR )
    sys.exit( 2 )


  logic = FyborgLogic()
  logic.run( options.input, options.output, options.radius, options.length, int( options.stage ), options.cortex_only, options.verbose )
