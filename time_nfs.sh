#!/bin/bash

G_SYNPOSIS="

NAME

	time_nfs.sh

SYNPOSIS

	time_nfs read|write [<count> [<file>]]

DESCRIPTION

	'time_nfs.sh' returns the time to read or write a <file>
	of <count> 16k chunks.

	If <count> is not specified, defaults to 32768 (about a 512MB file).

	If <file> is not specified, defaults to ./readWriteTest.raw.

EXAMPLES

	$>time_nfs.sh write 65536 file.raw
	Create a 1.1GB file <file.raw> and return the time to create.

"

TYPE=$1
COUNT=$2
FILE=$3

if (( ! ${#TYPE} )) ; then
    printf "%s" "$G_SYNOPSIS"
    exit 1
fi 

if (( ! ${#COUNT} )) ; then
    COUNT=32768
fi

if (( ! ${#FILE} )) ; then
    FILE=./readWriteTest.raw
fi

OP="Invalid operation... must be either 'write' or 'read'."

case $TYPE 
in
	"write") OP=$(time dd if=/dev/zero of=$FILE bs=16k count=$COUNT) 	;;
	"read")  OP=$(time dd if=$FILE of=/dev/null bs=16k)			;;
esac

printf "%s" "$OP"



