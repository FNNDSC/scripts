#!/usr/bin/awk -f

function synopsis_show() {
     printf("\n");
     printf("NAME\n");
     printf("\n");
     printf("\tstats_print.awk\n");
     printf("\n");
     printf("SYNOPSIS\n");
     printf("\n");
     printf("\tawk -f stats_print.awk\t\t\t\t\\\n");
     printf("\t\t\t [-v <var2>=<val2>\t\t\\\n");
     printf("\t\t\t  -v <varN>=<valN>]\t\t\\\n");
     printf("\t\t\t <fileToProcess>\n");
     printf("\n");
     printf("DESCRIPTION\n");
     printf("\n");
     printf("\t'stats_print.awk' is a simple awk script that accepts as input\n");
     printf("\ta column dominant array of numbers, and returns some statistics\n");
     printf("\ton each column, specifically the sum, prod, mean, std, and the\n");
     printf("\tminimum and maxmimum values.\n");
     printf("\n");
     printf("ARGUMENTS\n");
     printf("\n");
     printf("\tThe following variables passed with --assign <var>=<val>\n");
     printf("\tprogram behaviour:\n");
     printf("\n");
     printf("EXAMPLES\n");
     printf("\n");
     printf("\tTo process a file, say 'lh_calc.log' that contains a 'matrix'\n");
     printf("\tsimply do a\n");
     printf("\n");
     printf("\t\t$>stats_print.awk lh_calc.log\n");
     printf("\n");
     printf("\tor even\n");
     printf("\n");
     printf("\t\t$>cat lh_calc.log | stats_print.awk\n");
     printf("\n");
     printf("\tThe following statistics are available:\n");
     printf("\n");
     printf("\t\tSum:  Sum of all column elements\n");
     printf("\t\tProd: Product of all column elements\n");
     printf("\t\tMean: Mean of all product elements\n");
     printf("\t\tStd:  Standard Deviation of all product elements\n");
     printf("\t\tMin:  Minimum element in column\n");
     printf("\t\tMax:  Maximum element in column\n");
     printf("\n");
}

BEGIN {
    if(help) {
	synopsis_show();
	exit(0);
    }
    # Zero each column array
    for(col=0; col<100; col++) {
    	a_sum[col] 	= 0.0;
    	a_sum2[col] 	= 0.0;
	a_prod[col]	= 1.0;
	a_mean[col]	= 0.0;
	a_std[col]	= 0.0;
	a_input[col]	= 0.0;
	a_min[col]	= 0.0;
	a_max[col]	= 0.0;
    }
}
     
function array_print(a) {
    for(i=0; i<NF; i++) {
	printf("%12d", a[i]);
    }
    printf("\n");
}

function farray_print(a) {
    for(i=0; i<NF; i++) {
	printf("%12.5f", a[i]);
    }
    printf("\n");
}

function earray_print(a) {
    for(i=0; i<NF; i++) {
	printf("%12.3e", a[i]);
    }
    printf("\n");
}

function std_find(a) {
    # <a>	input array containing values
    printf("In std_find!\n");
    printf("NR = %d, NF = %d\n", NR, NF);
    for(i=0; i<NR; i++) {
	for(j=0; j<NF; j++) {
	    printf("%f\t", a[i, j]);
	}
	printf("\n");
    }
}

#
# Main function 
#
{
    # Populate each column array with a running sum, prod, std, min and max
    i = 0;
    for(col=1; col<=NF; col++) {
	a_input[NR-1, col]	= $(col);
	if(NR==1) {
	    a_min[i]	= $(col);
	    a_max[i]	= $(col);
	}
	if(a_min[i] > $(col)) a_min[i] = $(col);
	if(a_max[i] < $(col)) a_max[i] = $(col);
    	a_sum[i] 	+= $(col);
    	a_sum2[i] 	+= $(col) * $(col);
	a_prod[i]	*= $(col);
	a_std[i]	= (NR*a_sum2[i] - a_sum[i]*a_sum[i])/NR;
	i++;
    }
}

END {
    max 	= -1;
    i 		= 1;
    printf("%10s ", "Sum:");
    farray_print(a_sum);
    printf("%10s ", "Prod:");
    earray_print(a_prod);
    rows = NR;
    for(i=0; i<NF; i++)
    	a_mean[i] = a_sum[i] / rows;
    printf("%10s ", "Mean:");
    farray_print(a_mean);
    for(i=0; i<NF; i++)
    	a_std[i] = sqrt(a_std[i]/(NR-1));
    printf("%10s ", "Std:");
    farray_print(a_std);
    printf("%10s ", "Min:");
    farray_print(a_min);
    printf("%10s ", "Max:");
    farray_print(a_max);
   
}


