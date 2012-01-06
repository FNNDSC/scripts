#!/usr/bin/env python
import sys
import os
import random
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

    # update the parameters using the current size
    self.setSize( self.size().width(), self.size().height() )

  def setSize( self, w, h ):

    self.size().setWidth( w )
    self.size().setHeight( h )
    self.__scene.setSceneRect( 5, 5, w - 5, h - 5 )

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



class GridVisUI( QtGui.QWidget ):
  """
  The main program - creates a UI showing a GridView and some buttons.
  """

  def __init__( self, test=False, matrix=None ):
    super( GridVisUI, self ).__init__()

    self.__random = random

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

    self.__world = None

    self.setupGrid( test, matrix )


  def setupGrid( self, test, matrix ):

    if test:
      self.__rows = 101
      self.__cols = 101

      self.__gridWidget = GridView( self, self.__rows, self.__cols, False )
      self.__gridWidget.setSize( 600, 600 )
      self.__layout.addWidget( self.__gridWidget, 0, 0 )

      b_overwriteSpectralValue = True
      maxEnergy = 255 / 3
      automaton = C_spectrum_CAM_RGB( maxQuanta=maxEnergy )
      automaton.component_add( 'R', maxEnergy / 3, b_overwriteSpectralValue )
      automaton.component_add( 'G', maxEnergy / 3, b_overwriteSpectralValue )
      automaton.component_add( 'B', maxEnergy / 3, b_overwriteSpectralValue )

      world = C_CAE( np.array( ( self.__rows, self.__cols ) ), automaton )
      world.verbosity_set( 1 )
      arr_world = np.zeros( ( self.__rows, self.__cols ) )
      arr_world[0, 0] = 1
      arr_world[50, 50] = maxEnergy / 3 + 1
      arr_world[100, 100] = maxEnergy / 3 * 2 + 1

    elif matrix:
      maxEnergy = 255

      arr_worldRaw = np.loadtxt( matrix, float, '#', '\t' )
      arr_world = misc.arr_normalize(arr_worldRaw, scale=maxEnergy)

      self.__rows, self.__cols = arr_world.shape

      self.__gridWidget = GridView( self, self.__rows, self.__cols, False )
      self.__gridWidget.setSize( 600, 600 )
      self.__layout.addWidget( self.__gridWidget, 0, 0 )

      b_overwriteSpectralValue = True
      automaton = C_spectrum_CAM_RGB( maxQuanta=maxEnergy )
      automaton.component_add( 'R', maxEnergy / 3, b_overwriteSpectralValue )
      automaton.component_add( 'G', maxEnergy / 3, b_overwriteSpectralValue )
      automaton.component_add( 'B', maxEnergy / 3, b_overwriteSpectralValue )

      world = C_CAE( np.array( ( self.__rows, self.__cols ) ), automaton )
      world.verbosity_set( 1 )

    else:
      c.error( 'No test mode and no matrix..' )
      sys.exit()

    print arr_world
    world.initialize( arr_world )

    self.__world = world

  def togglePlay( self ):
    '''
    '''
    if not self.__timer.isActive():
      self.__timer.start( 300 )
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
    self.draw()
    self.__world.state_transition()

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
  parser = FNNDSCParser( description='Visualize a grid..' )

  parser.add_argument( '-t', '--test', action='store_true', dest='test', required=False, help='activate a test case (101x101, initialized at 3 points along the diagonal' )
  parser.add_argument( '-m', '--matrix', action='store', dest='matrix', required=True, help='File path of a connectivity matrix in ascii format, delimiter: space.' )
  # always show the help if no arguments were specified
#  if len( sys.argv ) == 1:
#    parser.print_help()
#    sys.exit( 1 )

  options = parser.parse_args()

  app = QtGui.QApplication( sys.argv )
  gui = GridVisUI( options.test, options.matrix )
  sys.exit( app.exec_() )

