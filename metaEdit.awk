{
	# Scan for line containing "orientation"
	if($1 == "orientation") {
		printf("\torientation\t\t= %d\n", 4);
	} else print;
}