#!/bin/bash

G_VERSION="2013a"
G_SYNOPSIS="

    NAME
    
        matlab
        
    SYNOPSIS
    
        matlab [-c] [-v <version>]
        
    ARGS
    
        -c
        Run MatLAB with '-nosplash -nodesktop'

	-v <version> (Default: $G_VERSION )
	Force a specific version of MatLAB to run. Currently supported
	are '2010a', '2011b', '2012a'. 
        
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

printf "Setting version to R$G_VERSION...\n"

if [[ $HOST_PREFIX == "rc" ]] ; then
    printf "Using 'pices' local install of MatLAB...\n"
    export MPATH=/chb/pices/arch/x86_64-Linux/packages/matlab/R${G_VERSION}/bin
    export PATH=$MPATH:$PATH
else
    printf "Using local install of MatLAB...\n"
    case $(uname) 
    in 
        Linux)  export MPATH=/chb/arch/x86_64-Linux/packages/matlab/R${G_VERSION}/bin
          	export PATH=$MPATH:$PATH
                ;;
        Darwin) export MPATH=/chb/arch/x86_64-Darwin/packages/matlab/MATLAB_R${G_VERSION}.app/bin
                export PATH=$MPATH:$PATH
		;;
    esac
fi


echo "$MPATH/matlab $MARGS"

$MPATH/matlab $MARGS 






