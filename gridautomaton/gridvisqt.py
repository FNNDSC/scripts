#!/usr/bin/env python
import sys
import os
import random
import time
from PyQt4 import QtGui, QtCore
from _common import FNNDSCUtil as u
from _common import FNNDSCParser
from _common import FNNDSCConsole as c

import  numpy           as np

from    C_spectrum_CAM  import *
from    C_CAE           import *

import  systemMisc      as misc


"""
"""

class GridView( QtGui.QGraphicsView ):
  """
  A Qt Widget to manage a grid defined by rows and columns and the actual widget size.
  """

  def __init__( self, parent=None, rows=10, cols=10, openGL=False ):
    super ( GridView, self ).__init__( parent )

    # global settings
    self.__parent = parent
    self.__rows = rows
    self.__cols = cols

    # all rectangles
    self.__padding = 0
    self.__rectangles = []

    # create the scene
    self.__scene = QtGui.QGraphicsScene()
    self.setScene( self.__scene )
    # accelerate on demand
    if openGL:
      self.setViewport( QtOpenGL.QGLWidget() )

  def draw( self, i, j, r, g, b ):

    self.__d_w = self.size().width() / self.__cols
    self.__d_h = self.size().height() / self.__rows

    color = QtGui.QColor( r, g, b )

    # find the coordinates to draw
    x = ( self.__d_w + self.__padding / 2 ) * j
    y = ( self.__d_h + self.__padding / 2 ) * i

    # draw a rectangle
    rect = QtGui.QGraphicsRectItem()
    rect.setPen( color )
    rect.setBrush( color )
    rect.setRect( x, y, self.__d_w - 2 * self.__padding, self.__d_h - 2 * self.__padding )

    self.__scene.addItem( rect )

  def clear( self ):
    self.__scene.clear()

  def scene( self ):
    return self.__scene



class GridVisUI( QtGui.QWidget ):
  """
  The main program - creates a UI showing a GridView and some buttons.
  """

  def __init__( self, 
                test            = False, 
                matrix          = None, 
                maxIterations   = -1,
                updateAmount    = 9, 
                convergence     = -1, 
                output          = None, 
                filestem        = 'matrix' ):
    super( GridVisUI, self ).__init__()

    # args
    self.__test                 = test
    self.__maxIterations        = maxIterations
    self.__updateAmount         = float(updateAmount)
    self.__output               = output
    self.__filestem             = filestem
    
    self.__array = None

    self.__layout = QtGui.QGridLayout()
    self.__layout.setSpacing( 10 )

    self.__timer = QtCore.QTimer()
    QtCore.QObject.connect( self.__timer, QtCore.SIGNAL( "timeout()" ), self.onTick )

    # the toolbar
    self.__toolbar = QtGui.QHBoxLayout()
    self.__toolbar.setSpacing( 10 )
    self.__playButton = QtGui.QPushButton( 'Start' )
    self.__playButton.clicked.connect( self.togglePlay )
    self.__toolbar.addWidget( self.__playButton )
    self.__saveButton = QtGui.QPushButton( 'Save...' )
    self.__saveButton.clicked.connect( self.save )
    self.__toolbar.addWidget( self.__saveButton )
    self.__iterationLabel = QtGui.QLabel( 'Iterations: 0' )
    self.__toolbar.addWidget( self.__iterationLabel )
    self.__toolbar.insertStretch( -1, 1 )

    self.__layout.addLayout( self.__toolbar, 1, 0 )

    self.setLayout( self.__layout )

    self.setGeometry( 640, 405, 660, 700 )
    self.setFixedSize( 660, 700 )
    self.setWindowTitle( 'GridVisQt' )
    self.show()

    # stats
    self.__iterations = 0

    # World and related
    self.__world                = None

    self.setupGrid( matrix )

    if convergence == "corners":
        self.__b_stopAtCorners = True
    else:
        self.__b_stopAtCorners = False
        convergence = float(convergence)
        if convergence > 0:
            f_diaglen   = np.sqrt(self.__world.m_rows**2 + self.__world.m_cols**2)
            print "world size: %d x %d" % (self.__world.m_rows, self.__world.m_cols)
            print "diagonal length: %f" % f_diaglen
            self.__maxIterations = int(convergence * f_diaglen)
            print "maxIterations: %d" % self.__maxIterations

    self.togglePlay()


  def setupGrid( self, matrix ):

    if self.__test:
      self.__rows = 101
      self.__cols = 101

      self.__gridWidget = GridView( self, self.__rows, self.__cols, False )
      self.__layout.addWidget( self.__gridWidget, 0, 0 )

      b_overwriteSpectralValue = True
      maxEnergy = 255 / 3
      automaton = C_spectrum_CAM_RGB( maxQuanta=maxEnergy )
      automaton.component_add( 'R', maxEnergy / 3, b_overwriteSpectralValue )
      automaton.component_add( 'G', maxEnergy / 3, b_overwriteSpectralValue )
      automaton.component_add( 'B', maxEnergy / 3, b_overwriteSpectralValue )
      automaton.updateRule_changeAmount(self.__updateAmount)

      world = C_CAE( np.array( ( self.__rows, self.__cols ) ), automaton )
      world.verbosity_set( 1 )
      arr_world = np.zeros( ( self.__rows, self.__cols ) )
      arr_world[0, 0] = 1
      arr_world[50, 50] = maxEnergy / 3 + 1
      arr_world[100, 100] = maxEnergy / 3 * 2 + 1

    elif matrix:
      maxEnergy = 255

      arr_worldRaw = np.loadtxt( matrix, float, '#', '\t' )
      arr_world = misc.arr_normalize( arr_worldRaw, scale=maxEnergy )

      self.__rows, self.__cols = arr_world.shape

      self.__gridWidget = GridView( self, self.__rows, self.__cols, False )
      self.__layout.addWidget( self.__gridWidget, 0, 0 )

      b_overwriteSpectralValue = True
      automaton = C_spectrum_CAM_RGB( maxQuanta=maxEnergy )
      automaton.component_add( 'R', maxEnergy / 3, b_overwriteSpectralValue )
      automaton.component_add( 'G', maxEnergy / 3, b_overwriteSpectralValue )
      automaton.component_add( 'B', maxEnergy / 3, b_overwriteSpectralValue )
      print "Update amount = %d" % self.__updateAmount
      automaton.updateRule_changeAmount(self.__updateAmount)

      world = C_CAE( np.array( ( self.__rows, self.__cols ) ), automaton )
      world.verbosity_set( 1 )

    else:
      c.error( 'No test mode and no matrix..' )
      sys.exit()

    print arr_world
    world.initialize( arr_world )

    self.__world = world
    #self.draw()

  def togglePlay( self ):
    '''
    '''
    if not self.__timer.isActive():
      self.__timer.start( 200 )
      self.__playButton.setText( 'Pause' )
    else:
      self.__timer.stop()
      self.__playButton.setText( 'Start' )

  def onTick( self ):
    '''
    '''
    # update the iterations counter
    self.__iterations += 1
    self.__iterationLabel.setText( 'Iterations: ' + str( self.__iterations ) )
    self.__world.state_transition()

    # draw it
    self.draw()

    b_cornersDominant = False
    if self.__b_stopAtCorners:
        b_cornersDominant = self.__world.currentGridCorners_areAllDominant()

    if self.__iterations >= int( self.__maxIterations ) and \
       int( self.__maxIterations ) != -1                or \
       self.__b_stopAtCorners and b_cornersDominant:

      # max. iterations reached

      self.__timer.stop()
      if self.__b_stopAtCorners: self.__playButton.setText('All corners are active')
      else: self.__playButton.setText( 'Maximum iterations reached' )
      self.__playButton.setEnabled( False )

      if self.__output:
        # take a screenshot and exit
        self.save( self.__output, self.__filestem )
        c.info( 'Took screenshot and saved matrix.')
        c.info( 'Output: ' + str( self.__output ) + os.sep + self.__filestem + '.*)' )
        c.info( 'Number of iterations: %d' % self.__iterations )
        c.info( 'Good-bye!' )
        sys.exit()

  def save( self, output=None, filestem='matrix' ):
    '''
    '''
    if not output:
      output = QtGui.QFileDialog.getExistingDirectory( self, 
                        "Location for saving a screenshot and the evolved matrix",
                        "",
                        QtGui.QFileDialog.ShowDirsOnly );

    screenshotFile = str( output + os.sep + filestem + '.png' )
    dataFile = str( output + os.sep + filestem + '.npy' )
    r_dataFile = str( output + os.sep + filestem + '_r.dat' )
    g_dataFile = str( output + os.sep + filestem + '_g.dat' )
    b_dataFile = str( output + os.sep + filestem + '_b.dat' )

    # take screenshot
    scene = self.__gridWidget.scene()
    isize = scene.sceneRect().size().toSize()
    self.qimage = QtGui.QImage( isize, QtGui.QImage.Format_ARGB32 )
    self.painter = QtGui.QPainter( self.qimage )
    scene.render( self.painter )
    self.qimage.save( screenshotFile, 'PNG', 100 )

    # save matrix
    # .. grab the current grid in synced state
    matrix = self.__world.currentgrid_get( True )
    np.save( dataFile, matrix )

    r_matrix = np.zeros( matrix.shape )
    g_matrix = np.zeros( matrix.shape )
    b_matrix = np.zeros( matrix.shape )


    for i in range( matrix.shape[0] ):
      for j in range( matrix.shape[1] ):
        str_pure = self.__world.spectrum_get(i, j).dominant_harmonic()
        if str_pure == 'R': r_matrix[i, j] = matrix[i, j][0]
        if str_pure == 'G': g_matrix[i, j] = matrix[i, j][1]
        if str_pure == 'B': b_matrix[i, j] = matrix[i, j][2]

    np.savetxt( r_dataFile, r_matrix )
    np.savetxt( g_dataFile, g_matrix )
    np.savetxt( b_dataFile, b_matrix )

  def draw( self ):

    self.__gridWidget.clear()

    for i in range( self.__rows ):
      for j in range( self.__cols ):

        r, g, b = self.__world.spectrum_get( i, j ).arr_get()

        self.__gridWidget.draw( i, j, r, g, b )

#
# entry point
#
if __name__ == "__main__":
  parser = FNNDSCParser( description='Visualize the evolution of a grid.' )

  parser.add_argument( '-t', '--test', action='store_true', dest='test', required=False, 
        help='activate a test case (101x101, initialized at 3 points along the diagonal' )
  parser.add_argument( '-i', '--iterations', action='store', dest='iterations', 
        default=-1, required=False, 
        help='Optional number of max. iterations.' )
  parser.add_argument( '-c', '--convergenceCriteria', action='store', dest='convergence',
        default=-1, required=False, 
        help="""
        Stopping criteria. If "corners", stop when every corner cell of the grid has become
        active. If a float number, stop once the number of system iterations is equal
        to the float multiple of the number of elements on the diagonal."
        """ )
  parser.add_argument( '-u', '--updateAmount', action='store', dest='updateAmount', 
        default=-1, required=False, 
        help='''
        If specified, set the incremental update amount to the passed value. This
        controls the 'amount' of spectral energy that is shifted during an 
        update cycle in a targeted cell.
        ''' )
  parser.add_argument( '-o', '--output', action='store', dest='output', 
        default=None, required=False, 
        help='''
        Folder in which to store a screenshot of the evolved matrix as well as the
        numpy matrix itself. Used if either -i/--iterations or -c/--stopAtCorners
        is specified.
        ''' )
  parser.add_argument( '-f', '--filestem', action='store', dest='filestem', 
        default='matrix', required=False, 
        help='Filestem to use to name the output files, by default: \'matrix\'.' )
  parser.add_argument( '-m', '--matrix', action='store', dest='matrix', required=True, 
        help='File path of a 2D-grid (matrix) in ascii format, delimiter: tab.' )

  # always show the help if no arguments were specified
  if len( sys.argv ) == 1:
    parser.print_help()
    sys.exit( 1 )

  options = parser.parse_args()
  app = QtGui.QApplication( sys.argv )
  print options
  gui = GridVisUI( options.test, 
                   options.matrix, 
                   options.iterations,
                   options.updateAmount, 
                   options.convergence, 
                   options.output, 
                   options.filestem )
  sys.exit( app.exec_() )

