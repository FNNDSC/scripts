#!/usr/bin/awk -f

function synopsis_show() {
     printf("\n");
     printf("NAME\n");
     printf("\n");
     printf("\tcol_prod.awk\n");
     printf("\n");
     printf("SYNOPSIS\n");
     printf("\n");
     printf("\tawk -f col_prod.awk\t\t\t\t\\\n");
     printf("\t\t\t [-v <var2>=<val2>\t\t\\\n");
     printf("\t\t\t  -v <varN>=<valN>]\t\t\\\n");
     printf("\t\t\t <fileToProcess>\n");
     printf("\n");
     printf("DESCRIPTION\n");
     printf("\n");
     printf("\t'col_prod.awk' is a simple awk script that accepts as input\n");
     printf("\ta two-column array of numbers, and returns col1*col2.\n");
     printf("\n");
     printf("\tNo data-error checking is performed -- only the 1st two columns\n");
     printf("\tof input matrix are considered, and it is assumed that the columns\n");
     printf("\thave the same amount of rows.\n");
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
     printf("\t\t$>col_prod.awk lh_calc.log\n");
     printf("\n");
     printf("\tor even\n");
     printf("\n");
     printf("\t\t$>cat lh_calc.log | col_prod.awk\n");
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
    # Populate each out matrix entry 'o' with 'c1/c2'
	
    f_result	= $1 * $2;
    printf("%*.*f\n", width, precision, f_result);
}

END {
}


