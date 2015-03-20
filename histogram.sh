#!/bin/bash

G_SYNOPSIS="
  NAME

	histogram.sh

  SYNOPSIS

	histogram.sh [-b] [-v]

  DESCRIPTION

	'histogram.sh' provides a simple text based histogram on input text
	stream.

  ARGS

	-b
	If specified, remove any blank lines from input stream prior
	to processing.

  PRECONDITIONS

	o Should be used as part of a pipe.

"
let b_removeBlankLines=0
let b_showInput=0

while getopts bxv option ; do 
        case "$option"
        in
                'b') let b_removeBlankLines=1		;;
                'x') echo "$G_SYNOPSIS" ; exit 1 	;; 
		'v') let b_showInput=1			;;
	esac
done

shift $(($OPTIND - 1))

# first, read all the input into a variable
INPUT=""
let count=0
while read line
do
    if (( b_removeBlankLines )) ; then
	if (( ! ${#line} )) ; then
	    continue
	fi
    fi
    if (( ! $count )) ; then
        INPUT=$line
    else
        INPUT=$(printf "%s\n%s" "$INPUT" "$line")
    fi
    count=$(( count + 1 )) 
done < "${1:-/dev/stdin}"

if (( b_showInput )) ; then
	echo "..."
	echo "$count"
	echo "..."
	echo "$INPUT"
	echo "..."
fi 

echo "$INPUT" | awk '{print $1}'|sort|uniq -c|sort -rn|head -20|awk '!max{max=$1;}{r="";i=s=60*$1/max;while(i-->0)r=r"#";printf "%30s %5d %s %s",$2,$1,r,"\n";}'
