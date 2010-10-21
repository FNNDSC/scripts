#!/usr/bin/awk -f

BEGIN {
   if(!r)	r = 6;
}

{
    if(NF >= r) {
	for(row = r-1; row >= 0; row--) {
		printf("%f\t", $(NF-row));
	}
	printf("\n");
    }
}
