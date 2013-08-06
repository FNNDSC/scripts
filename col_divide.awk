#!/usr/bin/awk -f

function synopsis_show() {
     printf("\n");
     printf("NAME\n");
     printf("\n");
     printf("\tcol_divide.awk\n");
     printf("\n");
     printf("SYNOPSIS\n");
     printf("\n");
     printf("\tawk -f col_divide.awk\t\t\t\t\t\\\n");
     printf("\t\t\t --assign col=<val>\t\t\t\\\n");
     printf("\t\t\t --assign mul=<val>\t\t\t\\\n");
     printf("\t\t\t <fileToProcess>\n");
     printf("\n");
     printf("DESCRIPTION\n");
     printf("\n");
     printf("\t'col_divide.awk' is a simple awk script that accepts as input\n");
     printf("\ta column dominant array of numbers, and divides a given\n");
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
     printf("\n\t\tdiv=<val>");
     printf("\n\t\tThe divisor.\n");
     printf("\n");
     printf("\t\twidth=<cellWidth>\n");
     printf("\t\tSet the display cell width to <cellWidth>. Default is 12.\n");
     printf("\n");
     printf("\t\tprec=<precision>\n");
     printf("\t\tSet the display precision to <precision>. Default is 4.\n");
     printf("\n\nEXAMPLES\n");
     printf("\n");
     printf("\tTo divide the 2nd column of data in file 'test.mat' with 10:\n");
     printf("\n");
     printf("\t\tcol_divide.awk --assign col=2 --assign div=10 test.mat\n");
     printf("\n");
     printf("\tor even\n");
     printf("\n");
     printf("\t\tcat test.mat | col_divide.awk --assign col=2 --assign div=10\n");
     printf("\n");
}

BEGIN {
    if(!width)		width		= 12;
    if(!precision)	precision	= 4;
    if(help) {
	synopsis_show();
	exit(0);
    }
}
     

#
# Main function 
#
{
    $(col)		/= div;
    for(i=1; i<=NF; i++)
        printf("%*.*f ", width, precision, $i);
    printf("\n")
}

END {
   
}


