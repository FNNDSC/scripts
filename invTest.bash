#!/bin/bash
#
# invTest.bash
#
# Copyright 2014 Rudolph Pienaar
# Boston Children's Hospital
#
# SPDX-License-Identifier: MIT
#


declare -i MATRIXSIZE=0
declare -i LOOPS=0

G_MATLAB="/neuro/arch/x86_64-Linux/packages/matlab/current/bin/matlab"

G_SYNOPSIS="

 NAME

	invTest.bash

 SYNOPSIS

	invTest.bash -M <MATRIXSIZE> -L <LOOPS>

 DESCRIPTION

	'invTest.bash' is a wrapper about a MatLAB
	function. Its purpose is to demonstrate how to
	run non-interactive MatLAB scripts on the cluster.

 ARGUMENTS

        -M <MATRIXSIZE>
        The size of the matrix to invert.

        -L <LOOPS> 
        The number of times to perform the inversion.

 PRECONDITIONS
	
	o MatLAB

 POSTCONDITIONS

	o None

 HISTORY

	13 February 2014
	o Initial design and coding.

"


function matlab_scriptCreate
{
    local BASEDIR=$1
    local SCRIPT=$2

    ROOTDIR=$(dirname $BASEDIR)
    
    cat > $SCRIPT <<-end-of-script
function [aM, aM_inv] = invTest(aMatrixSize, aNumberOfLoops, varargin)

tic;
fprintf(1, 'Looping %d times over matrix of size %d\n', aNumberOfLoops, aMatrixSize);
aM      = rand(aMatrixSize, aMatrixSize);
aM_inv  = aM;
for i=1:aNumberOfLoops
        aM_inv = inv(aM_inv);
end
toc;
end-of-script

}

###\\\
# Process command options
###///

while getopts M:L: option ; do 
	case "$option"
	in
                M)      MATRIXSIZE=$OPTARG              ;;
                L)      LOOPS=$OPTARG                   ;;
	esac
done

MATLABSCRIPT=invTest.m
#matlab_scriptCreate $(pwd) $MATLABSCRIPT
CMD="eval \"$G_MATLAB -nodesktop -nosplash -nojvm	\
              -r \\\"[N M] = invTest($MATRIXSIZE, $LOOPS) ; exit\\\"\"" 
echo $CMD
echo $CMD | sh              
exit 0              
              
