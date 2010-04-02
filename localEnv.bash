OS=$(uname -a | awk '{print $1}')
export PROMPTPREFIX=[$HOSTTYPE-$OS]

