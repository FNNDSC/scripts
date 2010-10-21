#!/usr/bin/awk -f

function synopsis_show() {
     printf("\n");
     printf("NAME\n");
     printf("\n");
     printf("\tcol_weigh.awk\n");
     printf("\n");
     printf("SYNOPSIS\n");
     printf("\n");
     printf("\tawk -f col_weigh.awk\t\t\t\t\\\n");
     printf("\t\t\t [-v <var2>=<val2>\t\t\\\n");
     printf("\t\t\t  -v <varN>=<valN>]\t\t\\\n");
     printf("\t\t\t <fileToProcess>\n");
     printf("\n");
     printf("DESCRIPTION\n");
     printf("\n");
     printf("\t'col_weigh.awk' is a simple awk script that accepts as input\n");
     printf("\ta column dominant array of numbers, and returns for each colum\n");
     printf("\tits values weighed by the column index.\n");
     printf("\n");
     printf("ARGUMENTS\n");
     printf("\n");
     printf("\tThe following variables passed with -v <var>=<val>\n");
     printf("\tprogram behaviour:\n");
     printf("\n");
     printf("\t-v width=<cellWidth>\n");
     printf("\tSet the display cell width to <cellWidth>. Default is 12.\n");
     printf("\n");
     printf("\t-v prec=<precision>\n");
     printf("\tSet the display precision to <precision>. Default is 4.\n");
     printf("\n");
     printf("EXAMPLES\n");
     printf("\n");
     printf("\tTo process a file, say 'lh_calc.log' that contains a 'matrix'\n");
     printf("\tsimply do a\n");
     printf("\n");
     printf("\t\t$>col_weigh.awk lh_calc.log\n");
     printf("\n");
     printf("\tor even\n");
     printf("\n");
     printf("\t\t$>cat lh_calc.log | col_weigh.awk\n");
     printf("\n");
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
    # Populate each matrix entry 't' with '100*(1 - t)'
    for(col=1; col<=NF; col++) {
	f_result	= $col * (1+(col-1)/10);
	printf("%*.*f", width, precision, f_result);
    }
    printf("\n");
}

END {
}


