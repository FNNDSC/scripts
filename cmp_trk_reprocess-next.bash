#!/bin/bash

# "include" the set of common script functions
source common.bash
source getoptx.bash

G_LOGFILE="-x"
G_TRKFILE="-x"

G_SYNOPSIS="

 NAME

        cmp_trk_reprocess.bash

 SYNOPSIS

        cmp_trk_reprocess.bash  -l <connectomeLogFile>                  \\
                                -t <trkFile>

 DESCRIPTION

        'cmp_trk_reprocess.bash' re-runs the final stages of the
        connectivity pipeline, using the passed <trkFile> as source
        for determining connectivity maps.

        It is something of a hack, and somewhat automated. The 'hack'
        part is because this script relies on a successfully completed 
        prior analysis that it then swaps out a previous track file 
        on the filesystem and re-runs, followed by some housekeeping
        on the create cff file. The 'automated' part is that the script
        tries to create the least disruption possible to the orignal
        output file tree.
        
 ARGUMENTS

        -v <level> (Optional)
        Verbosity level. A value of '10' is a good choice here.

        -l <connectomeLogFile>
        The log file created by a previously successful run of the
        original pipeline. This log file is parsed to extract the
        'connectome_web.py' line, which is slightly edited
        and re-run.
        
        -t <trkFile>
        The tract file to swap into the system.
        
 OUTPUT

        Any previous output file, '3-cmt_.cff' will be overwritten. To 
        conserve this, the existing cff is backed up. When completed,
        the 'new' cff file is appropriately renamed, and the original
        restored.

        In addition, the created cff is also unpacked (with an 
        appropriate name).

 PRECONDITIONS
        
        o A successfully completed connectome run.


 POSTCONDITIONS

        o New connectivity object built off passed track file.

 SEE ALSO

        o connectome_meta.bash -- main script controlling connectome
          runs.

 HISTORY

        03 November 2011
        o Initial design and coding.

"

# Actions
A_noLogFileArg="checking on the log file"
A_noTrkFileArg="checking on the trk file"
A_badLogFile="accessing the log file"
A_badTrkFile="accessing the trk file"
A_noStreamTrk="checking on the original streamline trk"
A_noCmtCff="checking on the original cff output"

# Error messages
EM_noLogFileArg="you must specify a '-l <connectomeLogFile>."
EM_noTrkFileArg="you must specify a '-t <trkFile>."
EM_badLogFile="I couldn't access the log file. Does it exist?"
EM_badTrkFile="I couldn't access the trk file. Does it exist?"
EM_noStreamTrk="I couldn't access the file. Does it exist?"
EM_noCmtCff="I couldn't access the file. Does it exist?"

# Error codes
EC_noLogFileArg=11
EC_noTrkFileArg=12
EC_badLogFile=21
EC_badTrkFile=22
EC_noStreamTrk=31
EC_noCmtCff=32

###\\\
# Process command options
###///

while getoptex "v: l: t: h" "$@" ; do
        case "$OPTOPT"
        in
            v)      Gi_verbose=$OPTARG                  ;;
            l)      G_LOGFILE=$OPTARG                   ;;
            t)      G_TRKFILE=$OPTARG                   ;;
            h)      synopsis_show 
                    exit 0;;
        esac
done

verbosity_check
topDir=$(pwd)
echo ""
cprint  "hostname"      "[ $(hostname) ]"

statusPrint     "Checking -l <connectomeLogFile>"
if [[ "$G_LOGFILE" == "-x" ]] ; then fatal noLogFileArg ; fi
ret_check $?

statusPrint     "Accessing <connectomeLogFile>"
fileExist_check $G_LOGFILE || fatal badLogFile

statusPrint     "Checking -t <trkFile>"
if [[ "$G_TRKFILE" == "-x" ]] ; then fatal noTrkFileArg ; fi
ret_check $?

statusPrint     "Accessing <trkFile>"
fileExist_check $G_TRKFILE || fatal badTrkFile

LOGCONTENTS=$(cat $G_LOGFILE)
CMPWEB=$(echo "$LOGCONTENTS"            |\
            grep connectome_web.py      |\
            head -n 1                   |\
            awk -F\| '{print $3}'       |\
            sed 's/Stage RUN  \(.*\)/\1/')

# re-direct to the 'trk' version
NEWCMPPCKL=$(echo "$CMPWEB" | sed 's/ connectome_web.py\(.*\)/connectome_trk-next.py \1/')
NEWCMP=$(echo "$NEWCMPPCKL" | awk -F'--writePickle' '{print $1}')
echo $NEWCMP

ROOTDIR=$(echo "$NEWCMP" | awk -F'-d' '{print $2}' | awk '{print $1}')

CMTTRKDIR=${ROOTDIR}/CMP/fibers
STREAMLINETRK=${CMTTRKDIR}/streamline_filtered.trk
CMTCFFDIR=${ROOTDIR}/CMP/cff
CMTCFF=${CMTCFFDIR}/3-cmt_.cff

statusPrint     "Checking on streamline_filtered.trk"
fileExist_check  $STREAMLINETRK || fatal noStreamTrk

statusPrint     "Backing up streamline_filtered.trk"
cp $STREAMLINETRK ${STREAMLINETRK}.$G_PID
ret_check $?

statusPrint     "Checking on the original cff output"
fileExist_check  $CMTCFF || fatal noCmtCff

statusPrint     "Backing up original cff output"
cp $CMTCFF ${CMTCFF}.$G_PID
ret_check $?

statusPrint     "Swapping out trk file"
cp $G_TRKFILE $STREAMLINETRK
ret_check $?

statusPrint     "Generating new connectivity structures" "\n"

echo "DEBUGGING"
pwd
eval $NEWCMP

statusPrint     "Unpacking new connectivity structures"
BASETRK=$(basename $G_TRKFILE)
cp $CMTCFF $CMTCFF.$BASETRK
UNPACKDIR=${CMTCFFDIR}/$BASETRK

mkdir -p $UNPACKDIR
cd $UNPACKDIR
unzip -o ../3-cmt_.cff
ret_check $?

statusPrint     "Extracting MatLAB matrices" "\n"
cd CNetwork >/dev/null
cnt_mat.py connectome_freesurferaparc.gpickle $(basename $(dirname $(pwd))) .trk

statusPrint     "Restoring previous streamline_filtered.trk"
mv ${STREAMLINETRK}.$G_PID $STREAMLINETRK 
ret_check $?

statusPrint     "Restoring previous cff file"
mv ${CMTCFF}.$G_PID $CMTCFF 
ret_check $?

shut_down 0





