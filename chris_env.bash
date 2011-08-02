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
#       source /some/path/chris.env.bash
#
# Customization should only need to set the CHRIS_DICOMROOT var and
# the scripts var
#
#

# Root dir of DICOM packer subsystem
export CHRIS_DICOMROOT=/chb/users/dicom

# CHRIS script storage location
export CHRIS_SCRIPTPATH=${CHRIS_DICOMROOT}/repo/trunk/scripts

# FreeSurfer environment sourcing script: 
export FSSOURCE=${CHRIS_SCRIPTPATH}/chris-fsdev

#
# +----- You shouldn't need to set anything below this line: -----------+
# |     |       |       |       |       |       |       |       |       | 
# V     V       V       V       V       V       V       V       V       V


# Location of DICOM Dictionary used by DCMTK. This depends somewhat on
# architecture:

case "$OS"
in 
        "Darwin")       export DCMDICTPATH=/opt/local/lib/dicom.dic     ;;
        "Linux")        export DCMDICTPATH=/usr/share/dcmtk/dicom.dic   ;;
esac

# Location of DICOM data path where the storescp-based litener will
# output its intermediate dicom files
export CHRIS_DCMDATAPATH=${CHRIS_DICOMROOT}/incoming

# Location of whether the incoming DICOM data will ultimately
# be stored after initial processing
export CHRIS_SESSIONPATH=${CHRIS_DICOMROOT}/files

# Location where logs of incoming DICOM receptions will be written
export CHRIS_LOGDIR=${CHRIS_DICOMROOT}/log

# Application Entity Title for storescp listener
export CHRIS_AETITLE=CHRIS

# Location of DTK matrices
export DSI_PATH=${CHRIS_DICOMROOT}/dtk/matrices/

# Source FreeSurfer env
$FSSOURCE

export PATH=$PATH:${CHB_SCRIPTPATH}:${FSLDIR}:${FSLDIR}/bin

