#!/bin/bash

G_VERSION="2011b"
G_SYNOPSIS="

    NAME
    
        matlab
        
    SYNOPSIS
    
        matlab [-c] [-v <version>]
        
    ARGS
    
        -c
        Run MatLAB with '-nosplash -nodesktop'

	-v <version> (Default '2011b')
	Force a specific version of MatLAB to run. Currently supported
	are '2010a' and '2011b'. 
        
    DESCRIPTION
    
        'matlab' is a simple dispatching layer that allows for host-specific
        customizations on running MatLAB. Essentially, the script maintains
        an internal list of host names, and depending on host, sets up
        host-specific env variables or paths as necessary.
        
        In practice, the scipt detects if the calling host is on the pices
        cluster, and if so, launches a cluster-local version of MatLAB.
        
    HISTORY
    
        10 Dec 2010
        o Initial development.
        
	12 Dec 2011
	o Different version handling.

        27 April 2012
        o Different version handling: R2012
        o Command line option '-v' used usable everywhere.
"

HOST=$(hostname -s)
HOST_PREFIX=$(echo $HOST | awk -F\- '{print $1}')

OSTYPE=$(uname -s)


while getopts cv: option ; do
    case "$option" 
    in
        c) MARGS="-nosplash -nodesktop" ;;
        v) G_VERSION="$OPTARG"          ;;
        *) echo "$G_SYNOPSIS"
           exit 1                       ;;
    esac
done

if [[ $HOST_PREFIX == "rc" ]] ; then
    printf "Using 'pices' local install of MatLAB...\n"
    export PATH=/chb/pices/arch/x86_64-Linux/packages/matlab/R${G_VERSION}/bin:$PATH
else
    printf "Using local install of MatLAB...\n"
    case $OSTYPE 
    in 
        Linux)  export PATH=/opt/MATLAB/R2011b/bin:/chb/arch/x86_64-Linux/packages/matlab/R${G_VERSION}/bin:$PATH
                ;;
        Darwin) export PATH=/chb/arch/x86_64-Darwin/packages/matlab/MATLAB_${G_VERSION}.app/bin:$PATH
    esac
fi


echo "matlab $MARGS"
matlab $MARGS





