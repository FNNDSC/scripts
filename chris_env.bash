# CHRIS -- CHildren's Research Imaging System
#
# bash env settings file
#
# This file configures several environment variables that
# are accessed by components of the CHRIS system.
#
# Typical usage is to explicitly source this file by any CHRIS
# subsystem script, i.e.
#
#       source /some/path/chris_env.bash
#
# Customization should only need to set the following:
# 	CHRIS_DICOMROOT 
# 	CHRIS_SCRIPTPATH
# 	CHRIS_CLUSTER
# 	CHRIS_WEBSITE
# 	CHRIS_POSTPROC
# 	 -- assuming all other paths/locations 
# are setup in the standard fashion.
#
#

# +- Pay particular attention to the settings below. -----------+
# |  These should be the only components that might need        |
# |  explicit setting, assuming all other components follow     |
# |  standard layout.                                           |
# +-------------------------------------------------------------+	 
# |     |       |       |       |       |       |       |       | 
# V     V       V       V       V       V       V       V       V

# Root dir of CHRIS DICOM packer subsystem -- this is the main 
# directory housing everything relevant to CHRIS
export CHRIS_HOME=/chb/users/dicom
export CHRIS_DICOMROOT=/chb/users/dicom
# CHRIS script storage location -- contains all script and related
# files relevant to CHRIS
export CHRIS_SCRIPTPATH=${CHRIS_DICOMROOT}/repo/trunk/scripts
# Webpage address
export CHRIS_WEBSITE=http://durban.tch.harvard.edu
# Postprocessing root
export CHRIS_POSTPROC=${CHRIS_DICOMROOT}/postproc

# Cluster info
# Local cluster name/dir 
export CHRIS_CLUSTER=pices
# Location of cluster schedule file
export CHRIS_CLUSTERDIR=${CHRIS_POSTPROC}/$CHRIS_CLUSTER

# +- The following settings can be tweaked. They are not critical ------+
# |  to CHRIS functioning, but should problably be customized           |
# |  to the local instance.                                             |
# +---------------------------------------------------------------------+		 
# |     |       |       |       |       |       |       |       | 	|
# V     V       V       V       V       V       V       V       V	V

# The name of this CHRIS instance. Used on web front end and in any emails
# communicated to end users by the system.
export CHRIS_NAME=CHRIS

# Admin user(s) of the CHRIS deployment -- comma separated if multiple
# admins
export CHRIS_ADMINUSERS=rudolph.pienaar@childrens.harvard.edu

# Mail binary location
export CHRIS_MAIL=/usr/bin/mail

# FreeSurfer environment sourcing script
export FSSOURCE=${CHRIS_SCRIPTPATH}/chris-fsdev

#
# +----- You shouldn't need to set anything below this line: -----------+
# |     |       |       |       |       |       |       |       |       | 
# V     V       V       V       V       V       V       V       V       V

# The CHRIS_ETC directory contains scripts and files relevant mostly to the 
# DICOM reception and unpacking of data.
export CHRIS_ETC=${CHRIS_DICOMROOT}/etc

# When called from a launchctl process or xinet.d, this script does not
# have a full path, hence we need to specify it here.
export PATH=/usr/bin:/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/games:/etc:/usr/etc:/usr/bin/X11:/usr/X11R6/bin:/opt/gnome/bin:/opt/local/bin:/sw/bin:$PATH

# storescp binary
export CHRIS_STORESCP=$(type storescp | head -n 1 | awk '{print $3}')
export CHRIS_DCMRENAME=${CHRIS_ETC}/dcm_rename

# Location of DICOM Dictionary used by DCMTK. This depends somewhat on
# architecture:
case "$OS"
in 
        "Darwin")       export CHRIS_DCMDICTPATH=/opt/local/lib/dicom.dic     ;;
        "Linux")        export CHRIS_DCMDICTPATH=/usr/share/dcmtk/dicom.dic   ;;
esac

# Location of DICOM data path where the storescp-based litener will
# output its intermediate dicom files
export CHRIS_DCMDATAPATH=${CHRIS_DICOMROOT}/incoming

# Location of whether the incoming DICOM data will ultimately
# be stored after initial processing
export CHRIS_SESSIONPATH=${CHRIS_DICOMROOT}/files

# Location where logs of incoming DICOM data will be written
export CHRIS_LOGDIR=${CHRIS_DICOMROOT}/log

# Application Entity Title for storescp listener
export CHRIS_AETITLE=CHRIS

# Source FreeSurfer env
source $FSSOURCE > /dev/null

# PACKAGEDIR should be defined in the FS env
export DTDIR=${PACKAGEDIR}/dtk
export DSI_PATH=${DTDIR}/matrices

export PATH=$PATH:${CHB_SCRIPTPATH}:${FSLDIR}:${FSLDIR}/bin

