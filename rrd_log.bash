#!/bin/bash
#
# $1 = rrd file name (e.g. /var/lib/ganglia/rrds/fnndsc/__SummaryInfo__/cpu_idle.rrd)
# $2 = output log file name
#
G_RRDFILE=/var/lib/ganglia/rrds/fnndsc/__SummaryInfo__/cpu_idle.rrd
G_OUTFILE=/chb/osx1927/1/users/dicom/postproc/rrd_log.txt

if [ ! -z "$1" ] ; then
    G_RRDFILE=$1
fi

if [ ! -z "$2" ] ; then
    G_OUTFILE=$2
fi

# This sipmle script uses the specified RRD (generated with ganglia) to
# output the CPU utilization % to a file.
while [ 1 ] ; do
    IDLEPCNT=$(rrdtool fetch $G_RRDFILE AVERAGE -s -30s | tail -2 | head -1 | awk '{print $2}')
    if [ "$IDLEPCNT" != "nan" ] ; then
	USEPCNT=$(echo ${IDLEPCNT} | awk '{print 100.0-$1}')
	echo $USEPCNT > $G_OUTFILE
    fi
    sleep 1;
done