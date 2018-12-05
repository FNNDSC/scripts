#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
Gstr_synopsis   = """
NAME

    age_calc.py

SYNOPSIS

    age_calc.py <birthDate> <scanDate> 

DESCRIPTION

    'age_calc.py' accepts as input <birthDate> and <scanDate> which must be
     of the format YYYYMMDD (from DICOM StudyDate and PatientBirthDate).
     This script will convert it to a DICOM Age String which is of the format:

     'A string of characters with one of the following formats -- nnnD, nnnW, 
     nnnM, nnnY; where nnn shall contain the number of days for D, weeks for W, 
     months for M, or years for Y.  Example: '018M' would represent an age of
     18 months.'
        
ARGUMENTS

     o <birthDate> and <scanDate>
        
PRECONDITIONS

    o The <birthDate> and <scanDate> must be of form 'YYYYMMDD' as described 
      above.
    
POSTCONDITIONS

    o  This script will convert the difference in dates to a i
       DICOM Age String (DICOM Table 6.2-1)
        
HISTORY

12 April 2010
o Initial development implementation.

05 December 2018
o Minor updates to python3

"""
import sys 
import datetime

if len(sys.argv) != 3:
    sys.exit(Gstr_synopsis)

birthDayStr = sys.argv[1]
scanDateStr = sys.argv[2]
 
birthY, birthM, birthD = int(birthDayStr[0:4]), int(birthDayStr[4:6]), int(birthDayStr[6:8])
scanY, scanM, scanD = int(scanDateStr[0:4]), int(scanDateStr[4:6]), int(scanDateStr[6:8])

birthDate = datetime.date(birthY, birthM, birthD)
scanDate = datetime.date(scanY, scanM, scanD)

dateDiff = abs(scanDate - birthDate)
print('%05d days | ' % dateDiff.days, end = '')
if dateDiff.days < 31:
    print('%03dD | ' % dateDiff.days, end = '')
elif dateDiff.days < (9*30.44):
    print('%03dW | ' % (dateDiff.days / 7), end = '')
elif dateDiff.days < (2*365.2524):
    print('%03dM | ' % (dateDiff.days / 30.44), end = '')
else:
    print('%03dY | ' % (dateDiff.days / 365.2425), end = '')
        
# How many years is this?
YR              = int(dateDiff.days / 365.2425)

# How many months (after YR) is this?
daysAfterYR     = int(dateDiff.days - (YR * 365.2425))
MO              = int(daysAfterYR / 30.44)

# How many days (after YR/MO) is this?
daysAfterYRMO   = daysAfterYR - (MO * 30.44)
DA              = daysAfterYRMO

print('%02d-yr/%02d-mo/%02d-da' % (YR, MO, DA))


sys.exit(0)
