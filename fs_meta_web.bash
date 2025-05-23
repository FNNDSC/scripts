#!/bin/bash
#
# fs_meta_web.bash
#
# Copyright 2009 Dan Ginsburg
# Children's Hospital Boston
#
# SPDX-License-Identifier: MIT
#
# $1 = Package directory
# $2 = Scripts directory
# $3 = Command-line arguments to fs_meta.bash (in quotes)
#
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

fs_meta.bash $3 > /home/danginsburg/fs_meta.bash.std 2> /home/danginsburg/fs_meta.bash.err