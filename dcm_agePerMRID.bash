#/bin/bash
#
# Simple script that prints a table of MRIDs and corresponding ages
#
# Depends on:
# 	o Run from /dicom/files directory
#	o dcm_MRID.log file
#	o FreeSurfer env
#


source ~/arch/scripts/common.bash

while read line ; do
    DIR=$(echo $line | awk '{print $1}')
    MRID=$(echo $line | awk '{print $2}')
    dirExist_check $DIR >/dev/null 
    if (( !$? )) ; then
    	printf "%55s\t" $DIR
    	printf "%50s\t" $MRID
    	cd $DIR >/dev/null 					
	AGE=$(dcm_bdayAgeGet.bash $(/bin/ls -1 | head -n 1) 	|\
	    grep Age | awk '{print $5}' | tr '\n' ' ')		
	printf "%10s\n" $AGE 					
    	cd ../							
    fi

done < dcm_MRID.log
