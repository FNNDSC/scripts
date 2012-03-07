OS=$(uname -a | awk '{print $1}')
ME=$(whoami)
export PROMPTPREFIX=[$ME@$name:$HOSTTYPE-$OS]

