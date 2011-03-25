#/bin/bash

Gstr_Xorder=""
Gstr_Yorder=""

G_SYNOPSIS="

  NAME
       
      grid2D_show.sh
 
  SYNPOSIS

      grid2D_show.sh -X <X-ordering> -Y <Y-ordering>

  DESC

      'grid2D_show.sh' accepts two ordering strings as generated
      by 'ordering_tabulate.sh', one for X-order and one for the Y-order.
      It generates the [row,col] positions of the group indices in 
      a 2D space.
    
  ARGS

      -X <X-ordering> -Y <Y-ordering>
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

while getopts X:Y:h option ; do
    case "$option" 
    in
        X)  Gstr_Xorder=$OPTARG         ;;
        Y)  Gstr_Yorder=$OPTARG         ;;
        \?) echo "$G_SYNOPSIS"
            exit 1                      ;;
    esac
done

groupsX=${#Gstr_Xorder}
groupsY=${#Gstr_Yorder}

if (( groupsX != groupsY )) ; then
    printf "Error! X-ordering and Y-ordering strings are unequal length.\n"
    exit 1
fi

for GROUP in $(seq 0 $(expr $groupsX - 1)) ; do
    GROUPIDX=${Gstr_Xorder:$GROUP:1}
    COL=$(echo $(expr index "$Gstr_Xorder" $GROUPIDX))
    ROW=$(echo $(expr index "$Gstr_Yorder" $GROUPIDX))
    printf "%s: %s, %s\n" $GROUPIDX $ROW $COL
done




