#!/bin/bash

# "include" the set of common script functions
source ~/arch/scripts/common.bash

declare -i Gb_customStorescu=0
declare -i Gi_verbose=0
declare -i Gb_anonymize=0

G_STORESCU="storescu"
G_FILEEXT=""
G_HOST=heisenberg.nmr.mgh.harvard.edu
G_AETITLE="DCM4CHEE"
G_LISTENPORT=11112

G_SYNOPSIS="

 NAME

	dicom_dirSend.bash

 SYNOPSIS

        dicom_dirSend.bash	[-v <verbosity>]                        \\
				[-a <aetitle>]				\\
				[-h <dicomHost>]			\\
				[-p <listenPort>]			\\
				[-s <storescu>]				\\
                                [-A]                                    \\
                                [-E <fileExt>]                          \\
				<dicomDir1> <dicomDir2> ... <dicomDirN>

 DESCRIPTION

        'dicom_dirSend' is a shell wrapper that recursively sends a 
	group of directories containing DICOM images to a remote
	PACS server.

 PRECONDITIONS

	o common.bash script source.

 ARGUMENTS

        -v <level> (Optional)
        Verbosity level. A value of '10' is a good choice here.
        
        -A (Optional)
        If specified, anonymize data before transmission.
        
        -E <fileExt> (Optional)
        If specified, only transmit files ending in *.<fileExt>, otherwise
        transmit all files in the target directory. Specifying the 
        <fileExt> is useful, since the transmission program will
        fail if attempting to transmit non-dicom files.

	-a <aetitle> (optional, default = $G_AETITLE)
	The aetitle of the PACS process to receive the data.

	-h <remoteNMRhost> (optional, default = $G_HOST)
	The host running the PACS process, i.e. the hostname of the DICOM
	peer.

	-p <listenPort> (optional, default = $G_LISTENPORT)
	The port number on which the PACS process is listening.

	-s <storescu> (optional, default = $G_STORESCU)
	Use this option to specify a <storescu> binary, typically used
	if <storescu> is not on the standard PATH. The basename of
	<storescu> is assumed to also contain any necessary libraries.

	<dicomDir1> <dicomDir2> ... <dicomDirN>
	The list of DICOM directories to transmit to the PACS process.

 EXAMPLES

  o To transmit to the dcmtk server on 'kaos':

    $>dicom_dirSend.bash -v 10 -a ELLENGRANT -h kaos.nmr.mgh.harvard.edu \\
      -p 10401 <DIR1>... <DIRn>
"

###\\\
# Globals are in capital letters. Immutable globals are prefixed by 'G'.
###///
G_SELF=`basename $0`
G_PID=$$

# Actions
A_fileCheck="checking on 'storescu'"
A_dirlistCheck="checking for the DICOM directory list"
A_dirCheck="checking the DICOM directory access"
A_storescu="executing the 'storescu' process"
A_dirAccess="attempting to access a directory"

# Error messages
EM_fileCheck="I couldn't find the 'storescu' executable on your path."
EM_dirlistCheck="no DICOM directory list was specified!"
EM_dirCheck="the DICOM directory could not be accessed."
EM_storescu="an error was returned."
EM_dirAccess="I couldn't access the directory. Does it exist? Do you have access rights?"

# Error codes
EC_fileCheck="10"
EC_dirlistCheck="20"
EC_dirCheck="30"
EC_storescu="40"
EC_dirAccess="50"

###\\\
# Function definitions
###///

###\\\
# Process command options
###///

while getopts v:a:h:p:s:AE: option ; do
        case "$option"
        in
                v) Gi_verbose=$OPTARG					;;
                A) Gb_anonymize=1                                       ;;
                E) G_FILEEXT=".${OPTARG}"                               ;;
		a) G_AETITLE=$OPTARG					;;
		h) G_HOST=$OPTARG					;;
		p) G_LISTENPORT=$OPTARG					;;
		s) G_STORESCU=$OPTARG					
		   Gb_customStorescu=1					;;
                \?) synopsis_show
                    exit 0;;
        esac
done

topDir=$(pwd)
verbosity_check

REQUIREDFILES="$G_STORESCU"
for file in $REQUIREDFILES ; do
        statusPrint	"Checking for $file..."
        file_checkOnPath $file || fatal fileCheck
done

if (( Gb_customStorescu )) ; then
	DIRNAME=$(dirname $G_STORESCU)
	statusPrint	"Checking <storescu> dirname"
	cd $DIRNAME	>/dev/null
	ret_check $? || fatal dirAccess
	DIRNAME=$(pwd)
	export DCMDICTPATH=$(pwd)/dicom.dic
	cd $topDir	>/dev/null
fi

shift $(($OPTIND - 1))
declare -i b_DCMLIST=0
DCMLIST=$*
b_DCMLIST=$(echo $DCMLIST | wc -w)

if (( !b_DCMLIST )) ; then
	fatal dirlistCheck
fi

if (( ${#G_FILEEXT} )) ; then
    cprint "DICOM file extension"       "[ $G_FILEEXT ]"
fi

topDir=$(pwd)
for DIR in $DCMLIST ; do
	statusPrint	"Checking access to $DIR" "\n"
        lprint          "Access check"
	dirExist_check "$DIR" || fatal dirCheck
        if (( Gb_anonymize )) ; then
            statusPrint "Anonymizing $DIR..." "\n"
            INPUTDIR=$DIR
            OUTPUTDIR=${DIR}-anon
            dcmanon_meta.bash -v 10 -D $INPUTDIR -O $OUTPUTDIR
            DIR=$OUTPUTDIR
            cprint      "Anonymization" "[ ok ]"
        fi
	statusPrint	"Transmitting *$G_FILEEXT files in $DIR..." "\n"
	cd "$DIR" >/dev/null
        lprint          "Transmission"
	$G_STORESCU -aet "$G_SELF" -aec $G_AETITLE $G_HOST $G_LISTENPORT *${G_FILEEXT}
	ret_check $? || fatal storescu
        cd ../
        if (( Gb_anonymize )) ; then
            lprint      "Removing temp directory"
            rm -fr "$DIR"
            rprint      "[ ok ]"
        fi
done

shut_down 0
