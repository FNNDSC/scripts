#!/bin/bash

G_SYNOPSIS="

    NAME
    
        matlab
        
    SYNOPSIS
    
        matlab [-c]
        
    ARGS
    
        -c
        Run MatLAB with '-nosplash -nodesktop'
        
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
        
        
"

HOST=$(hostname -s)
HOST_PREFIX=$(echo $HOST | awk -F\- '{print $1}')

OSTYPE=$(uname -s)

if [[ $HOST_PREFIX == "rc" ]] ; then
    printf "Using 'pices' local install of MatLAB...\n"
    export PATH=/chb/pices/arch/x86_64-Linux/bin:$PATH
else
    printf "Using local install of MatLAB...\n"
    case $OSTYPE 
    in 
        Linux)  export PATH=/opt/MATLAB/R2010b/bin:/chb/arch/x86_64-Linux/packages/matlab/R2010b/bin:$PATH
                ;;
        Darwin) export PATH=/chb/arch/x86_64-Darwin/packages/matlab/MATLAB_R2011b.app/bin:$PATH
    esac
fi

while getopts c option ; do
    case "$option" 
    in
        c) MARGS="-nosplash -nodesktop" ;;
        *) echo "$G_SYNOPSIS"
           exit 1                       ;;
    esac
done

echo "matlab $MARGS"
matlab $MARGS





