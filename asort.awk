#!/usr/bin/awk -f

function synopsis_show() {
     printf("\n");
     printf("NAME\n");
     printf("\n");
     printf("\tasort.awk\n");
     printf("\n");
     printf("SYNOPSIS\n");
     printf("\n");
     printf("\tawk -f asort.awk\t\t\t\t\\\n");
     printf("\t\t\t [-v b_descend=1\t\t\\\n""");
     printf("\t\t\t  -v b_int=1\t\t\t\\\n");
     printf("\t\t\t  -v b_indexOrder=1\t\t\\\n");
     printf("\t\t\t  -v b_colOutput=1\t\t\\\n");
     printf("\t\t\t  -v precision=<precision>\t\\\n");
     printf("\t\t\t  -v width=<cellWidth>]\t\t\\\n");
     printf("\t\t\t <fileToProcess>\n");
     printf("\n");
     printf("DESCRIPTION\n");
     printf("\n");
     printf("\t'asort.awk' is a simple awk script that accepts as input\n");
     printf("\ta single column dominant array of numbers, and returns a sorted\n");
     printf("\tcolumn. If <b_indexSort> is true, return not the sorted\n");
     printf("\tvalues, but the sorted indices.\n");
     printf("\n");
     printf("ARGUMENTS\n");
     printf("\n");
     printf("\tThe following variables passed with --assign <var>=<val>\n");
     printf("\tprogram behaviour:\n");
     printf("\n");
     printf("\tb_descend=1\n");
     printf("\tIf specified, sort in descending order.\n");
     printf("\n");
     printf("\tb_int=1\n");
     printf("\tIf specified, print outputs as ints (default is float).\n");
     printf("\n");
     printf("\tb_indexOrder=1\n");
     printf("\tIf specified, print the index ordering of the sorted input array.\n");
     printf("\n");
     printf("\tb_colOutput=1\n");
     printf("\tIf specified, print output as column (default is row).\n");
     printf("\n");
     printf("\t-v width=<cellWidth>\n");
     printf("\tSet the display cell width to <cellWidth>. Default is 12.\n");
     printf("\n");
     printf("\t-v precision=<precision>\n");
     printf("\tSet the display precision to <precision>. Default is 4.\n");
     printf("\n");
     printf("EXAMPLES\n");
     printf("\n");
     printf("\tTo process a file, say 'lh_calc.log'\n");
     printf("\tsimply do a\n");
     printf("\n");
     printf("\t\t$>asort.awk lh_calc.log\n");
     printf("\n");
     printf("\tor even\n");
     printf("\n");
     printf("\t\t$>cat lh_calc.log | asort.awk\n");
     printf("\n");
}
     
function qsort(A, left, right,   i, last) {
	if (left >= right)
		return
	swap(A, left, left+int((right-left+1)*rand()))
	last = left
	for (i = left+1; i <= right; i++)
		if (A[i] < A[left])
			swap(A, ++last, i)
	swap(A, left, last)
	qsort(A, left, last-1)
	qsort(A, last+1, right)
}

function swap(A, i, j,   t) {
    t = A[i]; A[i] = A[j]; A[j] = t
}     
 
function array_copy(source, target) {
    for(i=1; i<=NR; i++)
        target[i] = source[i];
} 
     
function farray_print(a) {
    for(i=1; i<=NR; i++) {
	f_val = b_descend ? a[NR-i+1] : a[i];
	printf("%*.*f ", width, precision, f_val);
	if(b_colOutput) printf("\n");
    }
    if(!b_colOutput) printf("\n");
}

function darray_print(a) {
    for(i=1; i<=NR; i++) {
	val = b_descend ? a[NR-i+1] : a[i];
	printf("%*d ", width, val);
	if(b_colOutput) printf("\n");
    }
    if(!b_colOutput) printf("\n");
}

BEGIN {
    if(!width)		width		= 12;
    if(!precision)	precision	= 4;
    if(!start)          start           = 1;
    if(!b_descend)	b_descend	= 0;
    if(!b_int)          b_int           = 0;
    if(!b_indexOrder)   b_indexOrder    = 0;
    if(!b_colOutput)    b_colOutput     = 0;
    if(help) {
	synopsis_show();
	exit(0);
    }
}

#
# Main function 
#
{
    # Populate some internal structures with input stream
    a_input[NR]	                = $1;
    a_inputSorted[NR]           = $1;
    a_inputSortedCopy[NR]       = $1
    a_indexSorted[NR]           = $1;
}

END {
    if(!help) {
        qsort(a_inputSorted, 1, NR);
        array_copy(a_inputSorted, a_inputSortedCopy);
        if(!b_indexOrder) {
            if (b_int) darray_print(a_inputSorted);
            else       farray_print(a_inputSorted);
        } else {
          # Index re-order:
          for(i=1; i<=NR; i++) {
            for(j=1; j<=NR; j++) {
                if(a_inputSortedCopy[i] == a_input[j]) {
                    a_indexSorted[i] = j;
                    a_input[j] = "-1";
                    break;
                }
            }
          }
          darray_print(a_indexSorted);
        }
    }
}


