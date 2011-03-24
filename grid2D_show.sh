#/bin/bash


G_SYNOPSIS="

  NAME
       
      grid2D_show.sh
 
  SYNPOSIS

      grid2D_show.sh <X-ordering> <Y-ordering>

  DESC

      'grid2D_show.sh' accepts two ordering strings as generated
      by 'ordering_tabulate.sh', one for X-order and one for the Y-order.
      It generates the [row,col] positions of the group indices in 
      a 2D space.
    
  ARGS

      <X-ordering> <Y-ordering>
      The string order desription of the cluster groups. Note that the
      Y-ordering is assumed to be left-right decreasing (i.e. the left most
      value is the highest Y-group -- see the example).

  EXAMPLE
  Typical example:
        $>grid2D_show.sh 4312 4321
        4: 1, 1
        3: 2, 2
        1: 4, 3
        2: 3, 4

  SEE ALSO 
  o grid2D_show.py -- python equivalent that draws an actual spatial grid.

"

while getopts option h; do
    case "$option" 
    in
        \?) echo "$G_SYNOPSIS"
            exit 1                      ;;
    esac
done

Xorder=$1
Yorder=$2

groupsX=${#Xorder}
groupsY=${#Yorder}

if (( groupsX != groupsY )) ; then
    printf "Error! X-ordering and Y-ordering strings are unequal length.\n"
    exit 1
fi

for GROUP in $(seq 0 $(expr $groupsX - 1)) ; do
    GROUPIDX=${Xorder:$GROUP:1}
    COL=$(echo $(expr index "$Xorder" $GROUPIDX))
    ROW=$(echo $(expr index "$Yorder" $GROUPIDX))
    printf "%s: %s, %s\n" $GROUPIDX $ROW $COL
done




