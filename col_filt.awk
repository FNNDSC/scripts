#!/usr/bin/awk -f

function synopsis_show() {
     printf("\n");
     printf("NAME\n");
     printf("\n");
     printf("\tcol_filt.awk\n");
     printf("\n");
     printf("SYNOPSIS\n");
     printf("\n");
     printf("\tawk -f col_filt.awk\t\t\t\t\\\n");
     printf("\t\t\t  -v f_cutoff=<filter>\t\t\\\n");
     printf("\t\t\t [-v filtCol=<index>\t\t\\\n");
     printf("\t\t\t  -v filtExpr=<filterExpr>\t\\\n");
     printf("\t\t\t  -v width=<width>]\t\t\\\n");
     printf("\t\t\t  -v prec=<precision>]\t\t\\\n");
     printf("\t\t\t <fileToProcess>\n");
     printf("\n");
     printf("DESCRIPTION\n");
     printf("\n");
     printf("\t'col_filt.awk' is a simple awk script that accepts as input\n");
     printf("\ta column dominant array of numbers, and filters according to\n");
     printf("\t<filterExpression> on column <index>.\n");
     printf("\n");
     printf("ARGUMENTS\n");
     printf("\n");
     printf("\tThe following variables passed with -v <var>=<val>\n");
     printf("\tprogram behaviour:\n");
     printf("\n");
     printf("\t-v f_cutoff=<filter>\n");
     printf("\tThe value to filter. Default is 0.0.\n");
     printf("\n");
     printf("\t-v filtCol=<index>\n");
     printf("\tThe column index on which to filter. Default is 1.\n");
     printf("\n");
     printf("\t-v filtExpr=<filtExpr>\n");
     printf("\tThe filter expression. Default is \"gte\" -- one of \"gte\", \"ge\", \"lte\", \"le\".\n");
     printf("\t\t\"gte\" -- greater than or equal to.\n");
     printf("\t\t\"gt\"  -- greater than.\n");
     printf("\t\t\"lte\" -- less than or equal to.\n");
     printf("\t\t\"lt\"  -- less than.\n");
     printf("\t\t\"uhl\" -- upper hard limit: values larger than this are hard limited.\n");
     printf("\t\t\"lhl\" -- lower hard limit: values lower than this are hard limited.\n");
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
     printf("\tand filter on the 1st column all values greater than equal to\n");
     printf("\t90.0, do:\n");
     printf("\n");
     printf("\t\t$>col_filt.awk -v filtCol=1 -v filtExpr=gte -v f_cutoff=90.0 lh_calc.log\n");
     printf("\n");
     printf("\tor even\n");
     printf("\n");
     printf("\t\t$>cat lh_calc.log | col_filt.awk -v filtCol=1 -v filtExpr=gte -v f_cutoff=90.0\n");
     printf("\n");
     printf("\n");
}

BEGIN {
    if(!width)		width		= 12;
    if(!precision)	precision	= 4;
    if(!filtCol)	filtCol		= 1;
    if(!filtExpr)	filtExpr	= "gte";
    if(!f_cutoff)	f_cutoff	= 0.0;
    if(help) {
	synopsis_show();
	exit(0);
    }
}


function colPrint() {
    for(col=1; col<=NF; col++) {
        if(col==$filtCol) {
            printf("%*.*f", width, precision, $col);
        }
        else {
	    printf("%*s", width, $col);
        }
    }
    printf("\n");
}

#
# Main function
#
{
    switch(filtExpr) {
	case "gte": 
            if($filtCol+0.0 >= f_cutoff) colPrint();
	    break;
	case "gt": 
            if($filtCol+0.0 >  f_cutoff) colPrint();
	    break;
	case "lte": 
            if($filtCol+0.0 <= f_cutoff) colPrint();
	    break;
	case "lt": 
            if($filtCol+0.0 <= f_cutoff) colPrint();
	    break;
	case "uhl":
            if($filtCol+0.0 >= f_cutoff) 
		$filtCol = f_cutoff;
	    colPrint();
	    break;
	case "lhl": 
            if($filtCol+0.0 <= f_cutoff) 
		$filtCol = f_cutoff;
	    colPrint();
	    break;
    }
}

END {
}
