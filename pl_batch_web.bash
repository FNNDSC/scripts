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
# TODO : Clean this up to use Rudolph's common.bash framework

PKGDIR=$1
FSLDIR=$PKGDIR/fsl
FSDIR=$PKGDIR/freesurfer
. $FSLDIR/etc/fslconf/fsl.sh
. $FSDIR/SetUpFreeSurfer.sh
PATH=$PATH:$FSLDIR/bin
PATH=$PATH:$PKGDIR/mricron:$PKGDIR/dtk
PATH=$PATH:$2
export FSLDIR PATH
echo $PATH

cd $4
pl_batch.bash $3 > /home/danginsburg/pl_batch.bash.std 2> /home/danginsburg/pl_batch.bash.err