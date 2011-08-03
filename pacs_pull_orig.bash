#!/bin/bash

INPUT_CSV=subject_list.csv
AE_TITLE=osx2147
CALL_TITLE=osx2147
QUERY_HOST=134.174.12.21
QUERY_PORT=104
RCV_PORT=11112

awk -F',' '{print $1 " " $5}' ${INPUT_CSV} | while read SUBJECT SCANDATE
do
    # Convert date to DICOM date format
    DCMSCANDATE=$(echo "$SCANDATE" | awk -F'/' '{ print $3$1$2 }')

    echo "Querying for [ $SUBJECT, $DCMSCANDATE ]..."

    # Query for the subject by ID and scan date
    findscu -xi -S --call ${CALL_TITLE} --aetitle ${AE_TITLE} -k 0008,0052=STUDY -k 0010,0020="$SUBJECT" -k 0008,0060="MR" -k 0008,0020=${DCMSCANDATE} -k 0020,000D ${QUERY_HOST} ${QUERY_PORT} > findstdout.txt 2> findstderr.txt

    # Search for the Study UID in the returned result
    STUDYUID=""
    old_IFS=$IFS
    IFS=$'\n'
    while read line ; do
	STUDYLINE=$(echo $line | grep "0020,000d")
	if [[ "${STUDYLINE}" != "" ]] ; then
	    echo "STUDYLINE: ${STUDYLINE}"
	    STUDYUID=$(echo "$STUDYLINE" |  awk -F'['  '{print $2}' | awk -F']' '{print $1}')
	    if [[ "${STUDYUID}" != "" ]] ; then
		echo "STUDYUID: ${STUDYUID}"
		break;
            fi
        fi
    done < findstderr.txt
    IFS=$old_IFS
    
    # Get the StudyUID of the result
    if [[ "${STUDYUID}" != "" ]] ; then
	echo "FOUND: ${STUDYUID}"
	# Create the directory for the subject
	mkdir "${SUBJECT}_${DCMSCANDATE}"
	cd "${SUBJECT}_${DCMSCANDATE}"

	# Grab the result from the PACS
	movescu --call ${CALL_TITLE} --aetitle ${AE_TITLE} --move ${AE_TITLE} --study --port ${RCV_PORT} -k 0008,0052=STUDY -k 0020,000D=${STUDYUID} ${QUERY_HOST} ${QUERY_PORT}
	cd ..
    fi
    
done

