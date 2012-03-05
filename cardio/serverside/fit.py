from lmfit import Parameters, minimize

import tempfile

from numpy import *
from scipy.optimize import leastsq
import os
import sys

import matplotlib
# Force matplotlib to not use any Xwindows backend.
matplotlib.use( 'Agg' )

try:
    import pylab
    HASPYLAB = True
except ImportError:
    HASPYLAB = False




def residual( pars, x, data=None ):

    A = pars['A'].value
    B = pars['B'].value
    T1star = pars['T1star'].value

    model = abs( A - B * exp( -x / T1star ) )
    if data is None:
        return model
    return ( model - data )

# args are passed like this:
## python fit2.py '46.0,118.0,190.0,262.0,334.0,406.0,478.0,550.0,622.0,694.0,766.0,838.0,910.0,982.0,1054.0,1126.0' '451.3,211.2,25.9,118.7,144.7,253.1,340.4,425.1,450.1,471.6,488.5,494.6,497.8,505.0,507.3,508.8'
x = fromstring( sys.argv[1], dtype=float, count= -1, sep=',' )
data = fromstring( sys.argv[2], dtype=float, count= -1, sep=',' )

p_true = Parameters()
p_true.add( 'A', value=200 )
p_true.add( 'B', value=600 )
p_true.add( 'T1star', value=500 )

# n = 2500
# xmin = 0.
# xmax = 5.0
# noise = random.normal(scale=0.7215, size=n)
# x     = linspace(xmin, xmax, n)
# print x
# data  = residual(p_true, x) + noise
# print data

out = minimize( residual, p_true, args=( x, ), kws={'data':data} )

fit = residual( p_true, x )

#print ' N fev = ', out.nfev
#print out.chisqr, out.redchi, out.nfree

tmpfile = tempfile.NamedTemporaryFile( delete=False )

output = str( p_true['A'].value ) + ','
output += str( p_true['B'].value ) + ','
output += str( p_true['T1star'].value ) + ','
output += str( os.path.split( tmpfile.name )[1] )


if HASPYLAB:
    pylab.plot( x, data, 'ro' )
    pylab.plot( x, fit, 'b' )
    pylab.savefig( tmpfile )
    #pylab.show()


print output



