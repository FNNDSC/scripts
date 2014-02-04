#!/bin/bash

G_VERSION="2013b"
G_SYNOPSIS="

    NAME
    
        matlab
        
    SYNOPSIS
    
        matlab [-c] [-l] [-v <version>]
        
    ARGS
    
        -c
        Run MatLAB with '-nosplash -nodesktop'

	-l
	Check for a local installation of MatLAB.
	Mac: 	/Applications
	Linux:	/usr/local/matlab/

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

	08 August 2013
	o Added '-l' specifically for cases when the BCH offered version
	  of MatLAB has been installed.
"

HOST=$(hostname -s)
HOST_PREFIX=$(echo $HOST | awk -F\- '{print $1}')

OSTYPE=$(uname -s)

declare -i b_local=0
declare -i b_useLocal=0

while getopts clv: option ; do
    case "$option" 
    in
        c) MARGS="-nosplash -nodesktop" ;;
	l) b_local=1			;;
        v) G_VERSION="$OPTARG"          ;;
        *) echo "$G_SYNOPSIS"
           exit 1                       ;;
    esac
done

printf "Setting version to R$G_VERSION...\n"

if (( b_local )) ; then
    printf "Checking for local BCH installation on this computer, %s\n" $(hostname)
    case $(uname)
    in
	Linux) 	export MPATH=/usr/local/matlab/R${G_VERSION}/bin	;;
	Darwin)	export MPATH=/Applications/MATLAB_R${G_VERSION}.app/bin	;;
    esac
    if [[ -x $MPATH/matlab ]] ; then
	printf "Found local BCH installation.\n"
	export PATH=$MPATH:$PATH
	b_useLocal=1
    else
	printf "No standard BCH installation found.\n"
	b_useLocal=0
    fi
fi

if (( ! b_useLocal )) ; then
    if [[ $HOST_PREFIX == "rc" ]] ; then
        printf "Using 'pices' local install of MatLAB...\n"
        export MPATH=/neuro/arch/x86_64-Linux/packages/matlab/R${G_VERSION}/bin
        export PATH=$MPATH:$PATH
    else
        printf "Using FNNDSC local install of MatLAB...\n"
        case $(uname) 
        in 
            Linux)  export MPATH=/neuro/arch/x86_64-Linux/packages/matlab/R${G_VERSION}/bin
              	    export PATH=$MPATH:$PATH
                    ;;
            Darwin) export MPATH=/neuro/arch/x86_64-Darwin/packages/matlab/MATLAB_R${G_VERSION}.app/bin
                    export PATH=$MPATH:$PATH
		    ;;
        esac
    fi
fi

echo "$MPATH/matlab $MARGS"

$MPATH/matlab $MARGS 



