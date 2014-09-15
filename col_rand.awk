#!/usr/bin/awk -f

function synopsis_show() {
     printf("\n");
     printf("NAME\n");
     printf("\n");
     printf("\tcol_rand.awk\n");
     printf("\n");
     printf("SYNOPSIS\n");
     printf("\n");
     printf("\tawk -f col_rand.awk\t\t\t\t\\\n");
     printf("\t\t\t [-v f_scale=<scale>\t\t\\\n");
     printf("\t\t\t  -v b_scale=<b_scale>\t\t\\\n");
     printf("\t\t\t  -v b_int=<int>\t\t\\\n");
     printf("\t\t\t  -v width=<width>]\t\t\\\n");
     printf("\t\t\t  -v prec=<precision>]\t\t\\\n");
     printf("\t\t\t <fileToProcess>\n");
     printf("\n");
     printf("DESCRIPTION\n");
     printf("\n");
     printf("\t'col_rand.awk' is a simple awk script that accepts as input\n");
     printf("\ta column dominant array of numbers, and outputs a similar matrix\n");
     printf("\tbut with each input element replaced (or scaled) by a random value.\n");
     printf("\n");
     printf("\tThis random value is further controlled by a series of command\n");
     printf("\tline flags.\n");
     printf("\n");
     printf("ARGUMENTS\n");
     printf("\n");
     printf("\tThe following variables passed with -v <var>=<val>\n");
     printf("\tprogram behaviour:\n");
     printf("\n");
     printf("\t-v f_scale=<scale>\n");
     printf("\tScale each value by <scale>. Default is 1.0.\n");
     printf("\n");
     printf("\t-v b_scale=<b_scale>\n");
     printf("\tIf true, scale each input value by a random value. Default is 0.\n");
     printf("\n");
     printf("\t-v b_int=<int>\n");
     printf("\tIf true, return integer outputs. Default is 0.\n");
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
     printf("\tand simply output a randomized matrix of the same size with integer\n");
     printf("\tvalues, do:\n");
     printf("\n");
     printf("\t\t$>col_rand.awk -v f_scale=10 -v b_int=1 lh_calc.log\n");
     printf("\n");
     printf("\tor even\n");
     printf("\n");
     printf("\t\t$>cat lh_calc.log | col_rand.awk -v f_scale=10 -v b_int=1 lh_calc.log\n");
     printf("\n");
     printf("\n");
}

BEGIN {
    if(!width)		width		= 12;
    if(!precision)	precision	= 4;
    if(!b_int)		b_int		= 0;
    if(!b_scale)	b_scale		= 0;
    if(!f_scale)	f_scale		= 1.0;
    if(help) {
	synopsis_show();
	exit(0);
    }
    srand();
}


function colPrint() {
    for(col=1; col<=NF; col++) {
	    f_rand = rand() * f_scale;
	    if(b_scale)
		    f_rand *= $col;
	    if(b_int)
		    printf("%*d", width, int(f_rand));
	    else
		    printf("%*.*f", width, precision, f_rand);
    }
    printf("\n");
}

#
# Main function
#
{
	colPrint();
}

END {
}
