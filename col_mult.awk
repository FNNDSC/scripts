#!/usr/bin/awk -f

function synopsis_show() {
     printf("\n");
     printf("NAME\n");
     printf("\n");
     printf("\tcol_mult.awk\n");
     printf("\n");
     printf("SYNOPSIS\n");
     printf("\n");
     printf("\tawk -f col_mult.awk\t\t\t\t\t\\\n");
     printf("\t\t\t --assign col=<val>\t\t\t\\\n");
     printf("\t\t\t --assign mul=<val>\t\t\t\\\n");
     printf("\t\t\t <fileToProcess>\n");
     printf("\n");
     printf("DESCRIPTION\n");
     printf("\n");
     printf("\t'col_mult.awk' is a simple awk script that accepts as input\n");
     printf("\ta column dominant array of numbers, and multiplies a given\n");
     printf("\tcolumn <col> with a given value <val>.\n");
     printf("\n");
     printf("ARGUMENTS\n");
     printf("\n");
     printf("\tThe following variables passed with --assign <var>=<val>\n");
     printf("\tprogram behaviour:\n");
     printf("\n");
     printf("\n\t\tcol=<val>");
     printf("\n\t\tThe column index to process.");
     printf("\n");
     printf("\n\t\tmul=<val>");
     printf("\n\t\tThe multiplier.");
     printf("\n");
     printf("EXAMPLES\n");
     printf("\n");
     printf("\tTo multiple the 2nd column of data in file 'test.mat' with 10:\n");
     printf("\n");
     printf("\tcol_mult.awk --assign col=2 --assign mul=10 test.mat\n");
     printf("\n");
     printf("\tor even\n");
     printf("\n");
     printf("\tcat test.mat | col_mult.awk --assign col=2 --assign mul=10\n");
     printf("\n");
}

BEGIN {
    if(help) {
	synopsis_show();
	exit(0);
    }
}
     

#
# Main function 
#
{
    $(col)		*= mul;
}

END {
   
}


