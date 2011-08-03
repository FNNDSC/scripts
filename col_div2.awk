#!/usr/bin/awk -f

function synopsis_show() {
     printf("\n");
     printf("NAME\n");
     printf("\n");
     printf("\tcol_div2.awk\n");
     printf("\n");
     printf("SYNOPSIS\n");
     printf("\n");
     printf("\tawk -f col_div2.awk\t\t\t\t\\\n");
     printf("\t\t\t [-v width=<width>\t\t\\\n");
     printf("\t\t\t  -v precision=<precision>]\t\\\n");
     printf("\t\t\t  -v width=<cellWidth>]\t\t\\\n");
     printf("\t\t\t  -v start=<colStart>]\t\t\\\n");
     printf("\t\t\t  -v preserve=<colPreserve>]\t\\\n");
     printf("\t\t\t  -v flip=<1>]\t\t\t\\\n");
     printf("\t\t\t <fileToProcess>\n");
     printf("\n");
     printf("DESCRIPTION\n");
     printf("\n");
     printf("\t'col_div2.awk' is a simple awk script that accepts as input\n");
     printf("\ta multi-column array of numbers, and returns col[n]/col[n+m/2]\n");
     printf("\twhere 'm' is the total number of columns in the original input.\n");
     printf("\tObvioulsy, 'm' must be even.\n");
     printf("\n");
     printf("\tThe <colStart> specifies the start value of col[n], and the\n");
     printf("\t<colPreserve> indicates a col index to 'preserve' and print first.\n");
     printf("\tThis is usually to preserve the very first column which often contains\n");
     printf("\trow header strings.\n");
     printf("\n");
     printf("\tThe '-v flip=1' setting will change the order of division, returning\n");
     printf("\tcol[n+m/2]/col[n].\n");
     printf("\n");
     printf("ARGUMENTS\n");
     printf("\n");
     printf("\tThe following variables passed with -v <var>=<val>\n");
     printf("\tprogram behaviour:\n");
     printf("\n");
     printf("\t-v width=<cellWidth>\n");
     printf("\tSet the display cell width to <cellWidth>. Default is 12.\n");
     printf("\n");
     printf("\t-v precision=<precision>\n");
     printf("\tSet the display precision to <precision>. Default is 4.\n");
     printf("\n");
     printf("\t-v flip=1\n");
     printf("\tChange the order of division from the default col1/col2 to col2/col1.\n");
     printf("\n");
     printf("EXAMPLES\n");
     printf("\n");
     printf("\tTo process two output files, say 'l1.txt' and 'l2.txt' that contain\n");
     printf("\tmatrixes, with first column containing header strings and first\n");
     printf("\tcontaining the text string SUBJECT,\n");
     printf("\n");
     printf("  vcat l1.txt l2.txt | grep -v SUBJECT | col_div2.awk -v start=2 -v preserve=1\n");
     printf("\n");
}

BEGIN {
    if(!width)		width		= 12;
    if(!precision)	precision	= 4;
    if(!start)          start           = 1;
    if(help) {
	synopsis_show();
	exit(0);
    }
}
     

#
# Main function 
#
{
    # Populate each out matrix entry 'o' with 'c[n]/c[n+m/2]'

    if(preserve)
        printf("%*s", width, $preserve);
    for(colIndex = start; colIndex <= NF/2; colIndex++) {
            f_first     = $colIndex;
            f_second    = $(colIndex + NF/2);
            f_result    = f_first / f_second;
            if(flip)
                f_result = f_second / f_first;
            printf("%*.*f", width, precision, f_result);
    }
    printf("\n");
}

END {
}


