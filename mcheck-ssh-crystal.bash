#!/bin/bash
#
# mcheck-ssh-osx1927.bash
#
# Copyright 2010 Rudolph Pienaar
# Children's Hospital Boston
#
# GPL v2
#

# "include" the set of common script functions
source common.bash

G_REPORTLOG=/tmp/${G_SELF}.reportLog.$G_PID
G_ADMINUSERS=rudolph.pienaar@childrens.harvard.edu

declare -i targetList

declare -a TARGET_CHECK
declare -a TARGETACTION

G_SYNOPSIS="

 NAME

       mcheck-ssh-crystal.bash

 SYNOPSIS

       mcheck-ssh-crystal.bash

 DESCRIPTION
 
        'mcheck-ssh-crystal.bash' is used to check that certain script-defined
	conditions are true. If any of these conditions are false, it executes 
	a set of corrective actions.

	It should typically be called from a cron process, and this particular
	version of 'mcheck' is tailored to monitoring ssh tunnels between this
	host and remote hosts.

	This particular script sets up the web of ssh-tunnel connections allowing
	connections to FNNDSC hosts. These tunnels are made *directly* to NMR
	hosts, and are not via an intermediary, 'dreev.tch.harvard.edu'.
		
 PRECONDITIONS

	 o Conditions to check are defined in the script code itself. These
    	   are specified in two arrays: the first describing (per condition)
    	   the command to check; the second describing (per condition) whatever
    	   corrective action to run should the check command be false.
 	o  Conditions to check should be described in such a manner that, should
    	   the condition be false, the check command returns zero (0).
 
 POSTCONDITIONS

	o The corrective action (per condition) is executed if the check condition
    	  returns false (0).

 HISTORY
 24 April 2014
  o Adpated from mcheck-ssh-dreev.bash and opens reverse --sshArgs '-p 22022' tunnels directly to 
    'door.nmr.mgh.harvard.edu.
    
 07 December 2017
  o Added 'crystal' changes.

"

###\\\
# Global variables
###///

# Actions
A_badRestart="attempting a corrective action"
A_fileCheck="checking for a required file dependency"

# Error messages
EM_badRestart="the corrective action failed. Perhaps a target process failed?"
EM_fileCheck="it seems that a dependency is missing."

# Error codes
EC_badRestart=10
EC_fileCheck=1

DREEV=dreev.tch.harvard.edu
JOHANNESBURG=johannesburg.tch.harvard.edu
ZEUS=zeus.tch.harvard.edu
SEVILLE=seville.tch.harvard.edu
DURBAN=durban.tch.harvard.edu
NATAL=natal.tch.harvard.edu
CENTAURI=centauri.tch.harvard.edu
SHAKA=shaka.tch.harvard.edu
PANGEA=pangea.tch.harvard.edu
RCDRNO=rc-drno.tch.harvard.edu
RCRUSSIA=rc-russia.tch.harvard.edu
RCMAJESTY=rc-majesty.tch.harvard.edu
PRETORIA=pretoria.tch.harvard.edu
GATE=xtal200.harvard.edu
CHRIS=chris-tmp.tch.harvard.edu
MATLAB=rc-matlab.tch.harvard.edu
FNNDSC=fnndsc.tch.harvard.edu
TAUTONA=tautona.tch.harvard.edu
YESNABY=yesnaby.tch.harvard.edu
CHRISMGHPCC=chris-mghpcc.tch.harvard.edu
CHRISCHPC=chris-chpc.tch.harvard.edu
BRAIN=brain.chpc.ac.za
FIONA=10.17.24.60
PANGEA=pangea.tch.harvard.edu
TITAN=titan.tch.harvard.edu

H1=108.49.45.138
verbosity_check
REQUIREDFILES="common.bash tunnel.bash pgrep"

for file in $REQUIREDFILES ; do
#        printf "%40s"   "Checking for $file"
        file_checkOnPath $file >/dev/null || fatal fileCheck
done

targetList=58
#
##
### REVERSE TUNNELS -- from dreev
##
# VNC screen access on osx1927
TARGET_CHECK[0]="tunnel.bash --reverse --sshArgs '-p 22022' 	--from rudolphpienaar@${GATE}:9900 	--to ${JOHANNESBURG}:5900 --isRunning"
TARGETACTION[0]="tunnel.bash --reverse --sshArgs '-p 22022' 	--from rudolphpienaar@${GATE}:9900 	--to ${JOHANNESBURG}:5900"
# VNC screen access to osx1476
TARGET_CHECK[1]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:1476 	--to ${SEVILLE}:5900 --isRunning"
TARGETACTION[1]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:1476 	--to ${SEVILLE}:5900"
# VNC screen access to Siemens Longwood 3.0T
TARGET_CHECK[2]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:5214	--to 10.3.1.214:5900 --isRunning"
TARGETACTION[2]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:5214	--to 10.3.1.214:5900"
# VNC screen access to Siemens Waltham 3.0T
TARGET_CHECK[3]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:5241	--to 10.64.4.241:5900 --isRunning"
TARGETACTION[3]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:5241	--to 10.64.4.241:5900"
# DICOM transmission/reception to osx1927
TARGET_CHECK[4]="tunnel.bash --reverse --sshArgs '-p 22022' 	--from rudolphpienaar@${GATE}:10402 	--to ${PRETORIA}:10401 --isRunning"
TARGETACTION[4]="tunnel.bash --reverse --sshArgs '-p 22022' 	--from rudolphpienaar@${GATE}:10402 	--to ${PRETORIA}:10401"
# Web access to 'durban'
TARGET_CHECK[5]="tunnel.bash --reverse --sshArgs '-p 22022' 	--from rudolphpienaar@${GATE}:8001 	--to ${DURBAN}:80 --isRunning"
TARGETACTION[5]="tunnel.bash --reverse --sshArgs '-p 22022' 	--from rudolphpienaar@${GATE}:8001 	--to ${DURBAN}:80"
# Web access to 'johannesburg'
TARGET_CHECK[6]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8800	--to ${JOHANNESBURG}:80 --isRunning"
TARGETACTION[6]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8800	--to ${JOHANNESBURG}:80"
# Web access to 'natal'
TARGET_CHECK[7]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8880	--to ${NATAL}:80 --isRunning"
TARGETACTION[7]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8880	--to ${NATAL}:80"
# OsiriX listener on 'osx1927'
TARGET_CHECK[8]="tunnel.bash --reverse --sshArgs '-p 22022' 	--from rudolphpienaar@${GATE}:11112	--to ${JOHANNESBURG}:11112 --isRunning"
TARGETACTION[8]="tunnel.bash --reverse --sshArgs '-p 22022' 	--from rudolphpienaar@${GATE}:11112	--to ${JOHANNESBURG}:11112"
# SVN source code repositories
TARGET_CHECK[9]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:5555	--to ${ZEUS}:22 --isRunning"
TARGETACTION[9]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:5555	--to ${ZEUS}:22"
TARGET_CHECK[10]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:5556	--to ${NATAL}:22 --isRunning"
TARGETACTION[10]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:5556	--to ${NATAL}:22"
TARGET_CHECK[11]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:4212	--to ${CENTAURI}:22 --isRunning"
TARGETACTION[11]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:4212	--to ${CENTAURI}:22"
TARGET_CHECK[12]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:4214	--to ${SHAKA}:22 --isRunning"
TARGETACTION[12]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:4214	--to ${SHAKA}:22"
TARGET_CHECK[13]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:4216 	--to ${PANGEA}:22 --isRunning"
TARGETACTION[13]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:4216 	--to ${PANGEA}:22"
TARGET_CHECK[14]="tunnel.bash --reverse --sshArgs '-p 22022'    --from rudolphpienaar@${GATE}:7777 	--to ${JOHANNESBURG}:22 --isRunning"
TARGETACTION[14]="tunnel.bash --reverse --sshArgs '-p 22022'    --from rudolphpienaar@${GATE}:7777 	--to ${JOHANNESBURG}:22"
TARGET_CHECK[15]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:4215	--to ${PRETORIA}:22 --isRunning"
TARGETACTION[15]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:4215	--to ${PRETORIA}:22"
# Cluster repository
TARGET_CHECK[16]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3204	--to ${RCDRNO}:22 --isRunning"
TARGETACTION[16]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3204	--to ${RCDRNO}:22"
TARGET_CHECK[17]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2121      --to ${FNNDSC}:21 --isRunning"
TARGETACTION[17]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2121      --to ${FNNDSC}:21"
TARGET_CHECK[18]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3203	--to ${RCRUSSIA}:22 --isRunning"
TARGETACTION[18]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3203	--to ${RCRUSSIA}:22"
# ChRIS VM
TARGET_CHECK[19]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8888	--to ${CHRIS}:80 --isRunning"
TARGETACTION[19]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8888	--to ${CHRIS}:80"

#
##
### (1/2) FORWARD TUNNELS -- maps a port on localhost to port on intermediary;
### these are connection points for reverse --sshArgs '-p 22022' tunnels back to NMR.
##
# 
# tesla VNC
TARGET_CHECK[20]="tunnel.bash --forward --sshArgs '-p 22022'	--from 4900 --via rudolphpienaar@${GATE} --to tesla:4900 --isRunning"
TARGETACTION[20]="tunnel.bash --forward --sshArgs '-p 22022'	--from 4900 --via rudolphpienaar@${GATE} --to tesla:4900"
# kaos login
TARGET_CHECK[21]="tunnel.bash --forward --sshArgs '-p 22022' --from 7776 --via rudolphpienaar@${GATE} --to kaos:22 --isRunning"
TARGETACTION[21]="tunnel.bash --forward --sshArgs '-p 22022' --from 7776 --via rudolphpienaar@${GATE} --to kaos:22"
# tesla login
TARGET_CHECK[22]="tunnel.bash --forward --sshArgs '-p 22022'	--from 7775 --via rudolphpienaar@${GATE} --to tesla:22 --isRunning"
TARGETACTION[22]="tunnel.bash --forward --sshArgs '-p 22022'	--from 7775 --via rudolphpienaar@${GATE} --to tesla:22"
# kaos -- DICOM listener
TARGET_CHECK[23]="tunnel.bash --forward --sshArgs '-p 22022' --from 10301 --via rudolphpienaar@${GATE} --to kaos:10401 --isRunning"
TARGETACTION[23]="tunnel.bash --forward --sshArgs '-p 22022' --from 10301 --via rudolphpienaar@${GATE} --to kaos:10401"

#
##
### FORWARD TUNNELS -- to site H1
##
#
TARGET_CHECK[24]="tunnel.bash --forward --from 9000 --via rudolphpienaar@${H1} --to localhost:80 --sshArgs '-p 7778' --isRunning"
TARGETACTION[24]="tunnel.bash --forward --from 9000 --via rudolphpienaar@${H1} --to localhost:80 --sshArgs '-p 7778'"
TARGET_CHECK[25]="tunnel.bash --forward --from 6812 --via rudolphpienaar@${H1} --to localhost:22 --sshArgs '-p 7778' --isRunning"
TARGETACTION[25]="tunnel.bash --forward --from 6812 --via rudolphpienaar@${H1} --to localhost:22 --sshArgs '-p 7778'"

#
##
### FORWARD TUNNELS -- to Partners clusters
##
#
TARGET_CHECK[26]="tunnel.bash --forward --sshArgs '-p 22022'	--from 7774 --via rudolphpienaar@${GATE} --to launchpad:22 --isRunning"
TARGETACTION[26]="tunnel.bash --forward --sshArgs '-p 22022'	--from 7774 --via rudolphpienaar@${GATE} --to launchpad:22"
TARGET_CHECK[27]="tunnel.bash --forward --sshArgs '-p 22022'	--from 7773 --via rudolphpienaar@${GATE} --to erisone.partners.org:22 --isRunning"
TARGETACTION[27]="tunnel.bash --forward --sshArgs '-p 22022'	--from 7773 --via rudolphpienaar@${GATE} --to erisone.partners.org:22"

# MatLAB
TARGET_CHECK[28]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:27000  --to ${MATLAB}:27000 --isRunning"
TARGETACTION[28]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:27000  --to ${MATLAB}:27000 "


# ChRIS @ NMR
TARGET_CHECK[29]="tunnel.bash --forward --sshArgs '-p 22022'	--from 1148 --via rudolphpienaar@${GATE} --to machris:22 --isRunning"
TARGETACTION[29]="tunnel.bash --forward --sshArgs '-p 22022'	--from 1148 --via rudolphpienaar@${GATE} --to machris:22"
TARGET_CHECK[30]="tunnel.bash --forward --sshArgs '-p 22022'	--from 1188 --via rudolphpienaar@${GATE} --to machris:8000 --isRunning"
TARGETACTION[30]="tunnel.bash --forward --sshArgs '-p 22022'	--from 1188 --via rudolphpienaar@${GATE} --to machris:8000"
TARGET_CHECK[31]="tunnel.bash --forward --sshArgs '-p 22022'	--from 1143 --via rudolphpienaar@${GATE} --to machris:443 --isRunning"
TARGETACTION[31]="tunnel.bash --forward --sshArgs '-p 22022'	--from 1143 --via rudolphpienaar@${GATE} --to machris:443"

TARGET_CHECK[32]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:4443 --to ${CHRIS}:443 --isRunning"
TARGETACTION[32]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:4443 --to ${CHRIS}:443"

# Persistent hosts: fnndsc, tautona, rc-majesty
TARGET_CHECK[33]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2137 --to ${FNNDSC}:22 --isRunning"
TARGETACTION[33]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2137 --to ${FNNDSC}:22 "
TARGET_CHECK[34]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3228 --to ${TAUTONA}:22 --isRunning"
TARGETACTION[34]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3228 --to ${TAUTONA}:22 "
TARGET_CHECK[35]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2214 --to ${CHRIS}:22 --isRunning"
TARGETACTION[35]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2214 --to ${CHRIS}:22"
TARGET_CHECK[36]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3142 --to ${RCMAJESTY}:22 --isRunning"
TARGETACTION[36]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3142 --to ${RCMAJESTY}:22"

# heisenberg@NMR login
TARGET_CHECK[37]="tunnel.bash --forward --sshArgs '-p 22022'	--from 7772 --via rudolphpienaar@${GATE} --to heisenberg:22 --isRunning"
TARGETACTION[37]="tunnel.bash --forward --sshArgs '-p 22022'	--from 7772 --via rudolphpienaar@${GATE} --to heisenberg:22"

TARGET_CHECK[38]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:5901 --to ${RCMAJESTY}:5901 --isRunning"
TARGETACTION[38]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:5901 --to ${RCMAJESTY}:5901"
TARGET_CHECK[39]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3901 --to ${PRETORIA}:5901 --isRunning"
TARGETACTION[39]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3901 --to ${PRETORIA}:5901"
TARGET_CHECK[40]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3902 --to ${PRETORIA}:5902 --isRunning"
TARGETACTION[40]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3902 --to ${PRETORIA}:5902"
TARGET_CHECK[41]="tunnel.bash --forward --sshArgs '-p 22022'	--from 2901 --via rudolphpienaar@${H1} --to localhost:5901 --sshArgs '-p 7778' --isRunning"
TARGETACTION[41]="tunnel.bash --forward --sshArgs '-p 22022'	--from 2901 --via rudolphpienaar@${H1} --to localhost:5901 --sshArgs '-p 7778'"
TARGET_CHECK[42]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3904 --to ${PRETORIA}:5904 --isRunning"
TARGETACTION[42]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3904 --to ${PRETORIA}:5904"
TARGET_CHECK[43]="tunnel.bash --forward --sshArgs '-p 22022'	--from 6901 --via rudolphpienaar@${GATE} --to kaos:5901 --isRunning"
TARGETACTION[43]="tunnel.bash --forward --sshArgs '-p 22022'	--from 6901 --via rudolphpienaar@${GATE} --to kaos:5901"
TARGET_CHECK[44]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2439 --to ${CHRISMGHPCC}:22 --isRunning"
TARGETACTION[44]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2439 --to ${CHRISMGHPCC}:22 " 
TARGET_CHECK[45]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2443 --to ${CHRISMGHPCC}:443 --isRunning"
TARGETACTION[45]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2443 --to ${CHRISMGHPCC}:443 " 
TARGET_CHECK[46]="tunnel.bash --forward --sshArgs '-p 22022'	--from 7900 --via rudolphpienaar@${GATE} --to tesla:5900 --isRunning"
TARGETACTION[46]="tunnel.bash --forward --sshArgs '-p 22022'	--from 7900 --via rudolphpienaar@${GATE} --to tesla:5900"

TARGET_CHECK[47]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:7639 --to ${TITAN}:22 --isRunning"
TARGETACTION[47]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:7639 --to ${TITAN}:22" 
TARGET_CHECK[48]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:7901 --to ${PANGEA}:7901 --isRunning"
TARGETACTION[48]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:7901 --to ${PANGEA}:7901" 

TARGET_CHECK[49]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3000 --to ${TITAN}:3000 --isRunning"
TARGETACTION[49]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3000 --to ${TITAN}:3000" 
TARGET_CHECK[50]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:5000 --to ${TITAN}:5000 --isRunning"
TARGETACTION[50]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:5000 --to ${TITAN}:5000" 
TARGET_CHECK[51]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8000 --to ${TITAN}:8000 --isRunning"
TARGETACTION[51]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8000 --to ${TITAN}:8000" 
TARGET_CHECK[52]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8010 --to ${TITAN}:8010 --isRunning"
TARGETACTION[52]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8010 --to ${TITAN}:8010" 
TARGET_CHECK[53]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:6001 --to ${TITAN}:6001 --isRunning"
TARGETACTION[53]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:6001 --to ${TITAN}:6001" 

TARGET_CHECK[54]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:6156 --to megalodon.tch.harvard.edu:22 --isRunning"
TARGETACTION[54]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:6156 --to megalodon.tch.harvard.edu:22" 

TARGET_CHECK[55]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:1344 --to fnndsc.childrens.harvard.edu:22 --isRunning"
TARGETACTION[55]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:1344 --to fnndsc.childrens.harvard.edu:22" 

TARGET_CHECK[56]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3156 --to megalodon.tch.harvard.edu:3000 --isRunning"
TARGETACTION[56]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:3156 --to megalodon.tch.harvard.edu:3000" 
TARGET_CHECK[57]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8156 --to megalodon.tch.harvard.edu:8000 --isRunning"
TARGETACTION[57]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8156 --to megalodon.tch.harvard.edu:8000" 
TARGET_CHECK[58]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:7000 --to megalodon.tch.harvard.edu:7000 --isRunning"
TARGETACTION[58]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:7000 --to megalodon.tch.harvard.edu:7000" 




#TARGET_CHECK[47]="tunnel.bash --forward --sshArgs '-p 22022'	--from 7901 --via rudolphpienaar@${GATE} --to tesla:5901 --isRunning"
#TARGETACTION[47]="tunnel.bash --forward --sshArgs '-p 22022'	--from 7901 --via rudolphpienaar@${GATE} --to tesla:5901"

#TARGET_CHECK[47]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${H1}:2468 --to ${CHRISCHPC}:22 --sshArgs '-p 7778' --isRunning"
#TARGETACTION[47]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${H1}:2468 --to ${CHRISCHPC}:22 --sshArgs '-p 7778'"
#TARGET_CHECK[48]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${H1}:2444 --to ${CHRISCHPC}:443 --sshArgs '-p 7778' --isRunning"
#TARGETACTION[48]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${H1}:2444 --to ${CHRISCHPC}:443 --sshArgs '-p 7778'"

#TARGET_CHECK[48]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2468 --to ${CHRISCHPC}:22 --isRunning"
#TARGETACTION[48]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2468 --to ${CHRISCHPC}:22"
#TARGET_CHECK[49]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2444 --to ${CHRISCHPC}:443 --isRunning"
#TARGETACTION[49]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2444 --to ${CHRISCHPC}:443"

# FIONA BOX
#TARGET_CHECK[49]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2460 --to ${FIONA}:22 --isRunning"
#TARGETACTION[49]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:2460 --to ${FIONA}:22"


# ChRIS@brain.chpc.ac.za
#TARGET_CHECK[50]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rpienaar@${BRAIN}:5120 --to localhost:22 --isRunning"
#TARGETACTION[50]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rpienaar@${BRAIN}:5120 --to localhost:22"
#TARGET_CHECK[51]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:10403  --to ${CHRISCHPC}:10502 --isRunning"
#TARGETACTION[51]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:10403  --to ${CHRISCHPC}:10502"

#TARGET_CHECK[52]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8042 --to ${TAUTONA}:8042 --isRunning"
#TARGETACTION[52]="tunnel.bash --reverse --sshArgs '-p 22022'	--from rudolphpienaar@${GATE}:8042 --to ${TAUTONA}:8042"

#TARGET_CHECK[53]="tunnel.bash --reverse --sshArgs '-p 22022'	--from babymr5@babymri.org:3333 --to ${TAUTONA}:22 --sshArgs '-p 2222' --isRunning"
#TARGETACTION[53]="tunnel.bash --reverse --sshArgs '-p 22022'	--from babymr5@babymri.org:3333 --to ${TAUTONA}:22 --sshArgs '-p 2222'"



# Process command line options
while getopts hv: option ; do
        case "$option"
        in
		v) 	let Gi_verbose=$OPTARG	;;
                h)      echo "$G_SYNOPSIS"
		        shut_down 1 ;;
                \?)     echo "$G_SYNOPSIS"
                        shut_down 1 ;;
        esac
done

rm -f $G_REPORTLOG
b_logGenerate=0

for i in $(seq 0 $(expr $targetList - 1)) ; do
        result=$(eval ${TARGET_CHECK[$i]})
	if (( result == 0 )) ; then
	        #echo "${TARGETACTION[$i]}"
		lprintn "Restarting target action..."
	        eval "${TARGETACTION[$i]} "
		ret_check $? || fatal badRestart
		TARGETRESTARTED="$TARGETRESTARTED $i"
		b_logGenerate=1
	fi
done

for i in $TARGETRESTARTED ; do
        echo ""
        echo -e "Failed:\t\t${TARGET_CHECK[$i]}"        >> $G_REPORTLOG
        echo -e "Executed:\t${TARGETACTION[$i]}"        >> $G_REPORTLOG
        echo ""
done

messageFile=/tmp/$SELF.message.$PID
if [ "$b_logGenerate" -eq "1" ] ; then
        message="
	
	$SELF
        
	Some of the events I am monitoring signalled a FAILED condition
	The events and the corrective action I implemented are:
	
$(cat $G_REPORTLOG)
	
        "
	echo "$message" > $messageFile
	mail -s "Failed conditions restarted" $G_ADMINUSERS < $messageFile
fi

if [[ -f $messageFile ]] ; then
	rm -f $messageFile 2>/dev/null
fi

# This is commented out otherwise cron noise becomes unbearable
#shut_down 0
