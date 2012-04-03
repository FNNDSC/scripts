from numpy import *

import os
import tempfile

import matplotlib
# Force matplotlib to not use any Xwindows backend.
matplotlib.use( 'Agg' )

import pylab
from scipy import stats
import sys

x = fromstring( sys.argv[1], dtype=float, count= -1, sep=',' )
y = fromstring( sys.argv[2], dtype=float, count= -1, sep=',' )

# args are passed like this:
## python reg.py '46.0,118.0,190.0,262.0,334.0,406.0,478.0,550.0,622.0,694.0,766.0,838.0,910.0,982.0,1054.0,1126.0' '451.3,211.2,25.9,118.7,144.7,253.1,340.4,425.1,450.1,471.6,488.5,494.6,497.8,505.0,507.3,508.8'

#x = [359.138781368336, 472.018571433674, 523.2912367840789, 1205.717884171721]
#y = [520.3911334476048, 621.4583656595216, 619.8437972452668, 837.1687705867008]




#pylab.show()

slope, intercept, r_value, p_value, std_err = stats.linregress( x, y )
print slope, intercept, r_value, p_value, std_err

reg = []
for xv in x:
  reg.append( intercept + slope * xv )

reg_t = []
for xv in x:
  reg_t.append( intercept + 0.488 * xv );

tmpfile = tempfile.NamedTemporaryFile( delete=False )

output = str( slope ) + ','
output += str( os.path.split( tmpfile.name )[1] )



pylab.plot( x, y, 'ro' )
pylab.plot( x, reg, 'b' )
#pylab.plot( x, reg_t, 'g' )
pylab.savefig( tmpfile )


print output
