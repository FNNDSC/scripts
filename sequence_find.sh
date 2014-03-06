#!/bin/bash

# "include" the set of common script functions
source common.bash

declare -i Gi_mtime=-365
declare -i Gi_verbosity=10

G_TOCFILE="toc.txt"
G_SEQUENCE="-x"
G_DICOMROOTDIR="$CHRIS_SESSIONPATH"

G_SYNOPSIS="
 NAME

        sequence_find.sh

 SYNOPSIS

        sequence_find.sh	-s <sequenceName>                      	\\
                                [-t <mtimeArg>]                     	\\

 DESCRIPTION

	'sequence_find.sh' greps through the 'toc.txt' table-of-contents
	files in the DICOM server repository, searching for a specific 
	sequence, <sequenceName>.
	
	The optional <mtimeArg> can be used to provide a cutoff time. By
	default, the script will search in all sequences pushed over the
	last year.

 ARGUMENTS

        -v <level> (optional)
        Verbosity level.

        -s <sequenceName>
        A string to search for in the toc.txt files. For best results, keep
	this as short as possible.
	
        -t <mtimeArg> (default: $Gi_mtime)
	The time window cutoff for the search. Only files that have been pushed
	prior to the cutoff date are searched. For example, to search only over
	the last week of pushed sequences, use '-t -7'.

 HISTORY
 27-Jan-2009
 o Initial design and coding.
"

# Actions
A_noSequenceArg="checking on the sequence argument"

# Error messages
EM_noSequenceArg="you haven't specified a sequence directory."

# Error codes
EC_noSequenceArg=1


###\\\
# Process command options
###///

while getopts s:t: option ; do 
	case "$option"
	in
                s)      G_SEQUENCE=$OPTARG         	;;
                t)      Gi_mtime=$OPTARG     		;;
		\?)     synopsis_show 
                        exit 0;;
	esac
done

if [[ "$G_SEQUENCE" == "-x" ]] ; then fatal noSequenceArg ; fi

cd $G_DICOMROOTDIR

CMD="find . -mtime $Gi_mtime -iname $G_TOCFILE		|\
      xargs -i@ echo \"grep -l $G_SEQUENCE @\"		|\
      sh						|\
      awk '{printf(\"cat %s | grep ID\n\", \$1);}'	|\
      sh						|\
      grep Patient					|\
      awk '{print \$3}'					|\
      sort -n -u"
      
eval "$CMD"

exit 0
