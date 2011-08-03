#!/usr/bin/awk -f

function synopsis_show() {
     printf("\n");
     printf("NAME\n");
     printf("\n");
     printf("\tmatrix_scale.awk\n");
     printf("\n");
     printf("SYNOPSIS\n");
     printf("\n");
     printf("\tawk -f matrix_scale.awk\t\t\t\t\\\n");
     printf("\t\t\t [-v width=<cellWidth>\t\t\\\n");
     printf("\t\t\t  -v preserve=<colPreserve>]\t\\\n");
     printf("\t\t\t  -v precision=<precision>]\t\\\n");
     printf("\t\t\t  -v start=<colStart>]\t\\\n");
     printf("\t\t\t  -v scale=<f_scale>]\t\\\n");
     printf("\t\t\t <fileToProcess>\n");
     printf("\n");
     printf("DESCRIPTION\n");
     printf("\n");
     printf("\t'matrix_scale.awk' is a simple awk script that accepts as input\n");
     printf("\ta matrix of numbers and scales each entry with <f_scale>, ie\n");
     printf("\tcol[n]*<f_scale>.\n");
     printf("\n");
     printf("\tThe '-v flip=1' setting will INVERT the scaling, returning\n");
     printf("\tcol[n]/<f_scale>.\n");
     printf("\n");
     printf("ARGUMENTS\n");
     printf("\n");
     printf("\tThe following variables passed with -v <var>=<val>\n");
     printf("\tprogram behaviour:\n");
     printf("\n");
     printf("\t-v width=<cellWidth>\n");
     printf("\tSet the display cell width to <cellWidth>. Default is 12.\n");
     printf("\n");
     printf("\t-v scale=<f_scale>\n");
     printf("\tScale each entry with <f_scale>.\n");
     printf("\n");
     printf("\t-v start=<colStart>\n");
     printf("\tAfter echo'ing the <preserve> col, start echo'ing output from <colStart>.\n");
     printf("\n");
     printf("\t-v precision=<precision>\n");
     printf("\tSet the display precision to <precision>. Default is 4.\n");
     printf("\n");
     printf("\t-v preserve=<colPreserve>\n");
     printf("\tDo not scale this column, but simply echo out. This is typically\n");
     printf("\tthe first column containing row headers.\n");
     printf("\n");
     printf("EXAMPLES\n");
     printf("\n");
     printf("  cat l1.txt | matrix_scale.awk -v scale=10\n");
     printf("\n");
}

BEGIN {
    if(!width)		width		= 12;
    if(!precision)	precision	= 4;
    if(!start)          start           = 1;
    if(!scale)          scale		= 1.0;
    if(help) {
	synopsis_show();
	exit(0);
    }
}
     

#
# Main function 
#
{
    if(preserve)
        printf("%*s", width, $preserve);
    for(colIndex = start; colIndex <= NF; colIndex++) {
            f_val	= $colIndex;
            f_result    = f_val * scale;
	    if(flip) f_result = f_val / scale;
            printf("%*.*f", width, precision, f_result);
    }
    printf("\n");
}

END {
}


