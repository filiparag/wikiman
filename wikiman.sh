#! /bin/dash

search_man() {
	
	query=$(echo "$@" | sed 's/ /\|/g')

	# Search by name
	
	results="$(
		find "/usr/share/man/man"* -type f | \
		awk -F'/' \
			"BEGIN {
				IGNORECASE=1;
			};
			/$query/ { 
				gsub(/[a-z]*/,\"\",\$(NF-1));
				gsub(/\..*/,\"\",\$NF);
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
	
}

search_wiki() {

	query=$(echo "$@" | sed 's/ /\|/g')

	results="$(
		rg -U -S -c "$query" /usr/share/doc/arch-wiki/html/en/ | \
		awk -F'/' \
		"BEGIN {
			count = 0
		};
		{
			hits = \$NF
			gsub(/^.*:/,\"\",hits);

			title = \$NF
			gsub(/\.html.*/,\"\",title);
			gsub(\"_\",\" \",title);

			if (title~/^Category:/) {
				gsub(/^Category:/,\"\",title);
				title = title \" (Category)\"
			}

			matches[count,0] = hits + 0;
			matches[count,1] = title;

			count++;
		};
		END {
			for (i = 0; i < count; i++)
				for (j = i; j < count; j++)
					if (matches[i,0] < matches[j,0]) {
						h = matches[i,0];
						t = matches[i,1];
						matches[i,0] = matches[j,0];
						matches[i,1] = matches[j,1];
						matches[j,0] = h;
						matches[j,1] = t;
					};

			for (i = 0; i < count; i++)
				print matches[i,1];
		};"
	)"

}