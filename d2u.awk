{
	str = sprintf("%s", $0);
	for(i=1; i<=length(str); i++) {
		if(substr(str, i, 1) != "\xd") {
			printf("%c", substr(str, i, 1));
		}
	}
	printf("\n");
}
     

