# This is an example script showing how to configure your environment for the
# neuropipeline.  These environment variables should be set to match your desired
# configuration.

# Location of DICOM Dictionary used by DCMTK
export DCMDICTPATH=/usr/share/dcmtk/dicom.dic

# Location of DICOM data path where the storescp-based litener will
# output its intermediate dicom files
export CHB_DCMDATAPATH=/home/dicom/neuropipe/incoming

# Location of whether the incoming DICOM data will ultimately
# be stored after initial processing
export CHB_SESSIONPATH=/home/dicom/neuropipe/files

# Location where logs of incoming DICOM receptions will be written
export CHB_LOGDIR=/home/dicom/neuropipe/log

# Location of where the scripts are stored
export CHB_SCRIPTPATH=/home/dicom/chb/trunk/scripts

# Application Entity Title for storescp listener
export CHB_AETITLE=neuropipe

# Set FREESURFER_HOME
export FREESURFER_HOME=/usr/local/freesurfer
. ${FREESURFER_HOME}/SetUpFreeSurfer.sh

export PATH=$PATH:${CHB_SCRIPTPATH}
