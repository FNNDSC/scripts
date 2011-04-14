OS=$(uname -a | awk '{print $1}')
export PROMPTPREFIX=[$name:$HOSTTYPE-$OS]

