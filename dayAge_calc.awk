{
	printf("%55s%55s\t\t", $1, $2); 
	system("dayAge_calc.py -n -N -1 -i" $3);
}
