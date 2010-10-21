BEGIN {
   OFS = "\t";
}

{
   # Determine the various output filenames - ;
   # these are simply the names of variables appended with ".eos";
   # Execuate a bi-pass stripping of extra white spaces;  
   split(vars, outname);
   for(j = 1; j <= 2; j++) 
      for(i = 1; i <= numvars; i++) 
	 sub(" ", "", outname[i]);
   
   # now redirect each set of field information to;
   # appropriate file;
   for(i = 1; i <= fields; i++) {
      for(j = 1; j <= numvars; j++) {
	 col=i+((j-1)*fields)+start-1;
	 printf("%s\t", $(col)) >> outname[j] ".eos"; 
      }
   }

   # and finally newline to each file
   for(j = 1; j <= numvars; j++)
     printf("\n") >> outname[j] ".eos";

   if( NR == numlines-3 ) 
     print i+((j-2)*fields)+1;
}
     

