#!/bin/bash

USERLIST=$(ypcat passwd | awk -F \: '{print $1}')

for USER in $USERLIST ; do
        EMAIL=$(ypcat aliases | grep -i ${USER: -4} 2>/dev/null | head -n 1)
        if (( ! ${#EMAIL} )) ; then
            EMAIL=$(ypcat aliases | grep -i ${USER:0:4} 2>/dev/null | head -n 1)
        fi
        if (( ! ${#EMAIL} )) ; then 
            EMAIL=rudolph.pienaar@childrens.harvard.edu
        fi
        NAME=$(ypcat passwd | grep $USER | awk -F \: '{print $5}')
        printf "%s:%s:%s\n" "$USER" "$EMAIL" "$NAME"
done
