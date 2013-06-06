#!/usr/bin/env python

import nibabel, numpy, scipy.spatial, sys, types
from _common import FNNDSCParser

def find_nearest_neighbor( mesh, point, k=1, radius= -1 ):

  vertices, faces = nibabel.freesurfer.read_geometry( mesh )

  kd_tree = scipy.spatial.KDTree( vertices )

  if k == 0:
    print 'Found 0 results!'
    return

  if radius == -1:
    results = kd_tree.query( point, k )[1]
  else:
    results = kd_tree.query_ball_point( point, radius )

  if k == 1 and radius == -1:
    results = [results]

  print 'Found', len( results ), 'results!'
  for r in results:

    print vertices[r], 'vertex index:', r, 'distance:', numpy.linalg.norm( vertices[r] - point )


#
# entry point
#
if __name__ == "__main__":
  parser = FNNDSCParser( description='Find nearest neighbors on a Freesurfer mesh.' )


  parser.add_argument( '-i', '--input', action='store', dest='input', required=True, help='the Freesurfer mesh, f.e. -i lh.smoothwm' )
  parser.add_argument( '-p', '--point', action='store', nargs=3, dest='point', type=float, required=True, help='the source point in RAS space ([mm]), f.e. -p 123.05 12.3 144.2' )
  parser.add_argument( '-k', '--k', action='store', dest='k', required=False, type=int, help='number of points to find. DEFAULT: 1', default=1 )
  parser.add_argument( '-r', '--radius', action='store', dest='radius', type=float, required=False, help='radius [mm] to include in point search (overrides -k/--k). DEFAULT: -1 to ignore.', default= -1 )

  # always show the help if no arguments were specified
  if len( sys.argv ) == 1:
    parser.print_help()
    sys.exit( 1 )

  options = parser.parse_args()

  find_nearest_neighbor( options.input, options.point, options.k, options.radius )
