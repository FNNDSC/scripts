#!/bin/bash
#
# pl_batch_web.bash
#
# Copyright 2009 Dan Ginsburg
# Children's Hospital Boston
#
# GPL v2
#
# $1 = Package directory
# $2 = Scripts directory
# $3 = Command-line arguments to fs_meta.bash (in quotes)
# $4 = Working directory to execute from
# $5 = basename of log files

# Set freesurfer home
. $2/chb-fsdev
PKGDIR=$1
PATH=$PATH:$PKGDIR/mricron:$PKGDIR/dtk:$PKGDIR/gdcm/bin:$PKGDIR/Slicer/current
PATH=$PATH:$2
export PATH
echo $PATH

cd $4
pl_batch.bash $3 > $5.std 2> $5.err
