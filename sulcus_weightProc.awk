#!/bin/awk -f

function synopsis_show() {
     printf("\n");
     printf("NAME\n");
     printf("\n");
     printf("\tsulcus_weightProc.awk\n");
     printf("\n");
     printf("SYNOPSIS\n");
     printf("\n");
     printf("\tawk -f sulcus_weightProc.awk --assign Gf_cutoff=<val> ... \\\n");
     printf("\t\t\t [--assign <var2>=<val2> ... \\\n");
     printf("\t\t\t  --assign <varN>=<valN>] ... \\\n");
     printf("\t\t\t <fileToProcess>\n");
     printf("\n");
     printf("DESCRIPTION\n");
     printf("\n");
     printf("\t'sulcus_weightProc.awk' is a simple awk script that performs\n");
     printf("\tsome postprocessing on a log file of per-experiment sulcal\n");
     printf("\tweight vectors.\n");
     printf("\n");
     printf("\tIt's primary purpose is to generate a candidate weight vector\n");
     printf("\twhich is based on the value of a cut off passed to the script.\n");
     printf("\tEssentially, the individual vectors are summed, and normalised.\n");
     printf("\tThe candidate weight vector is simply a binary mask where each\n");
     printf("\t'bit' denotes whether that particular normalised value was greater\n");
     printf("\tthan or equal to the cut off value.\n");
     printf("\n");
     printf("\tThe script can also generate a given amount of candidate vectors\n"); 
     printf("\tbased on the probability distribution of the original normalisation.\n");
     printf("\tand various output data options are available.\n");
     printf("\n");
     printf("ARGUMENTS\n");
     printf("\n");
     printf("\tThe following variables passed with --assign <var>=<val>\n");
     printf("\tprogram behaviour:\n");
     printf("\n");
     printf("    Gf_cutoff=<f_val>\n\n");
     printf("\tSpecifies the cut-off probability threshold in generating\n");
     printf("\ta candidate representative weight vector. Essentially, all\n");
     printf("\tnormalised probabilities greater than or equal to <f_val>\n");
     printf("\twill be assigned a '1', else '0'.\n");
     printf("\n");
     printf("\tThis parameter *must* be specified!\n");
     printf("\n");
     printf("    G_probGenerate=<val> (optional - int)\n\n");
     printf("\tThis toggles the number of candidate probability vectors to\n");
     printf("\tgenerate.\n");
     printf("\n");
     printf("    Gb_arraySumPrint=1 (optional - bool)\n\n");
     printf("\tIf set, will print the raw sum vector generated from the\n");
     printf("\tinput matrix.\n");
     printf("\n");
     printf("    Gb_arrayNormalisedPrint=1 (optional - bool)\n\n");
     printf("\tIf set, will print the weight vector generated from the\n");
     printf("\tnormalised sum of the input matrix.\n");
     printf("\n");
     printf("    Gb_arrayRandPrint=1 (optional - bool)\n\n");
     printf("\tIf set, will toggle the print of the float-valued random\n");
     printf("\tarray used to construct the candidate weight vector.\n");
     printf("\n");
     printf("EXAMPLES\n");
     printf("\n");
     printf("\tTo process a file, say 'lh_calc.log' that contains a log\n");
     printf("\tsummary generated by 'sapex_postsulc.bash', do a\n");
     printf("\n");
     printf("\tawk -f sulcus_weightProc.awk --assign Gf_cutoff=0.5 lh_calc.log\n");
     printf("\n");
     printf("\tor even\n");
     printf("\n");
     printf("\tcat lh_calc.log | awk -f sulcus_weightProc.awk --assign Gf_cutoff=0.5\n");
     printf("\n");
}

BEGIN {
    if(help) {
	synopsis_show();
	exit(0);
    }
    if(!Gf_cutoff) {
	synopsis_show();
	exit(1);
    }
    # Zero each column array
    for(col=0; col<9; col++) {
    	a_sum[col] = 0;
    }
    # Column indices in the default log file that contain the
    #	weight vector
    if(!G_startCol)
    	G_startCol	= 4;
    if(!G_endCol)
    	G_endCol	= 12;
}
     
function array_print(a) {
    for(i=0; i<9; i++) {
	printf("%d\t", a[i]);
    }
    printf("\n");
}

function farray_print(a) {
    for(i=0; i<9; i++) {
	printf("%f\t", a[i]);
    }
    printf("\n");
}

function afprob_generate(a, Gb_arrayRandPrint) {
    for(i=0; i<9; i++) {
	af_r[i] = rand();
	if(af_r[i] <= a[i])
	    a_prob[i] = 1;
	else
	    a_prob[i] = 0;
    }
    if(Gb_arrayRandPrint)
    	farray_print(af_r);
    array_print(a_prob);
}

function afprob_cutoff(a, f_cutoff) {
    for(i=0; i<9; i++) {
	if(a[i] >= f_cutoff)
	    a_candidate[i] = 1;
	else
	    a_candidate[i] = 0;
    }
    array_print(a_candidate);
}

#
# Main function 
#
{
    # Populate each column array with a running sum
    i = 0;
    for(col=G_startCol; col<=G_endCol; col++) {
    	a_sum[i++] += $(col);
    }
}

END {
    if(!Gf_cutoff) {
	exit(1);
    }
    len		= 9;
    max 	= -1;
    i 		= 1;
    if(Gb_arraySumPrint)
	array_print(a_sum);
    asort(a_sum, a_sumSorted);
    max = a_sumSorted[len];
    max = NR;
    for(i=0; i<len; i++) {
	a_sumNormalised[i] = a_sum[i] / max;
    }
    afprob_cutoff(a_sumNormalised, Gf_cutoff);
    if(Gb_arrayNormalisedPrint) {
	farray_print(a_sumNormalised);
	printf("\n");
    }
    if(G_probGenerate>0)
    	for(j=0; j<G_probGenerate; j++)
            afprob_generate(a_sumNormalised, Gb_arrayRandPrint);
}

