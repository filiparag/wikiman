#! /bin/dash

search_man() {
	
	# Search by name

	query=$(echo "$@" | sed 's/ /\|/g')
	
	results="$(
		find "/usr/share/man/man"* -type f | \
		awk -F'/' \
			"BEGIN {
				IGNORECASE=1;
			};
			/$query/ { 
				sub(/[a-z]*/,\"\",\$(NF-1));
				sub(/\..*/,\"\",\$NF);
				print \$NF \" (\"\$(NF-1) \")\"; 
			};"
	)"

	# Search by description

	results="${results:+$results\n}$(
		apropos -l $@ 2>/dev/null | awk '{ print $1 " " $2 };'
	)"

	# Remove duplicates

	results="$(
		echo "$results" | awk '!seen[$0] {print} {++seen[$0]}'
	)"

	echo "$results"
	
}