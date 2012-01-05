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
    self.__rectangleRadiusX = 0
    self.__rectangleRadiusY = 0
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
    self.__rectangleRadiusX = ( ( w / self.__cols ) - self.__padding ) / 2
    self.__rectangleRadiusY = ( ( h / self.__rows ) - self.__padding ) / 2

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
    rect.setRect( x, y, self.__rectangleRadiusX * 2, self.__rectangleRadiusY * 2 )

    self.__scene.addItem( rect )

  def clear( self ):
    self.__scene.clear()



class GridVisUI( QtGui.QWidget ):
  """
  The main program - creates a UI showing a GridView and some buttons.
  """

  def __init__( self, random=False, interval=1 ):
    super( GridVisUI, self ).__init__()

    self.__random = random

    self.__array = None
    self.__rows = 101
    self.__cols = 101

    self.__layout = QtGui.QGridLayout()
    self.__layout.setSpacing( 10 )

    self.__timer = QtCore.QTimer()
    QtCore.QObject.connect( self.__timer, QtCore.SIGNAL( "timeout()" ), self.onTick )

    self.__gridWidget = GridView( self, self.__rows, self.__cols, False )
    self.__gridWidget.setSize( 600, 400 )
    self.__layout.addWidget( self.__gridWidget, 0, 0 )

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

    self.setGeometry( 640, 405, 660, 480 )
    self.setFixedSize( 660, 480 )
    self.setWindowTitle( 'GridVisQt' )
    self.show()

    # stats
    self.__iterations = 0

    self.__world = None

    self.setup()


  def setup( self ):

    b_overwriteSpectralValue = True
    maxEnergy = 249
    automaton = C_spectrum_CAM_RGB( maxQuanta=maxEnergy )
    automaton.component_add( 'R', maxEnergy / 3, b_overwriteSpectralValue )
    automaton.component_add( 'G', maxEnergy / 3, b_overwriteSpectralValue )
    automaton.component_add( 'B', maxEnergy / 3, b_overwriteSpectralValue )

    world = C_CAE( np.array( ( 101, 101 ) ), automaton )
    world.verbosity_set( 1 )
    arr_world = np.zeros( ( 101, 101 ) )
    arr_world[0, 0] = 1
    arr_world[50, 50] = maxEnergy / 3 + 1
    arr_world[100, 100] = maxEnergy / 3 * 2 + 1

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

  def draw( self ):

    self.__gridWidget.clear()

    for i in range( self.__rows ):
      for j in range( self.__cols ):

        rgb = self.__world.spectrum_get( i, j )

        r = rgb[0]
        g = rgb[1]
        b = rgb[2]

#        r = random.randint( 0, 255 )
#        g = random.randint( 0, 255 )
#        b = random.randint( 0, 255 )

        self.__gridWidget.draw( i, j, r, g, b )







#
# entry point
#
if __name__ == "__main__":
  parser = FNNDSCParser( description='Visualize a grid..' )

  parser.add_argument( '-r', '--random', action='store', dest='random', required=True, help='visualize random data' )
  #parser.add_argument( '-i', '--input', action = 'store', dest = 'input', required = True, help = 'input grid file, f.e. -i ~/files/f01.trk -i ~/files/f02.trk -i ~/files/f03.trk ..' )
  #parser.add_argument( '-o', '--output', action = 'store', dest = 'output', required = True, help = 'output trackvis file, f.e. -o /tmp/f_out.trk' )
  #parser.add_argument( '-j', '--jobs', action = 'store', dest = 'jobs', default = multiprocessing.cpu_count(), help = 'number of parallel computations, f.e. -j 10' )
  #parser.add_argument( '-v', '--verbose', action = 'store_true', dest = 'verbose', help = 'show verbose output' )
  #parser.add_argument( 'mode', choices = ['add', 'sub'], help = 'ADD all input tracks to one file or SUBTRACT all other input tracks from the first specified input' )

  # always show the help if no arguments were specified
  if len( sys.argv ) == 1:
    parser.print_help()
    sys.exit( 1 )

  options = parser.parse_args()

  app = QtGui.QApplication( sys.argv )
  gui = GridVisUI()
  sys.exit( app.exec_() )

