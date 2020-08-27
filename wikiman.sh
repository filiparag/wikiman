#! /bin/dash

config_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}/wikiman"
cache_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}/wikiman"

init() {
	mkdir -p "$config_dir" "$cache_dir"
}

search_man() {
	
	query="$(echo "$@" | sed 's/ /\|/g')"

	# Search by name
	
	results="$(
		find "/usr/share/man/man"* -type f | \
		awk -F'/' \
			"BEGIN {
				IGNORECASE=1;
			};
			/$query/ {
				title = \$NF
				gsub(/\..*/,\"\",title);

				section = \$(NF-1)
				gsub(/[a-z]*/,\"\",section);

				printf(\"%s (%s)\n\",title,section);
			};"
	)"

	# Search by description

	results="${results:+$results\n}$(
		apropos -l $@ 2>/dev/null | \
		awk '{ gsub(/\(|\)/,"",$2); printf("%s (%s)\n",$1,$2); };'
	)"

	# Remove duplicates

	results="$(
		echo "$results" | awk '!seen[$0] {print} {++seen[$0]};'
	)"
	
}

search_wiki() {

	query="$(echo "$@" | sed 's/ /\|/g')"

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

			path = \$0
			gsub(/:[0-9]+$/,\"\",path);

			if (title~/^Category:/) {
				gsub(/^Category:/,\"\",title);
				title = title \" (Category)\"
			}

			matches[count,0] = hits + 0;
			matches[count,1] = title;
			matches[count,2] = path;

			count++;
		};
		END {
			for (i = 0; i < count; i++)
				for (j = i; j < count; j++)
					if (matches[i,0] < matches[j,0]) {
						h = matches[i,0];
						t = matches[i,1];
						p = matches[i,2];
						matches[i,0] = matches[j,0];
						matches[i,1] = matches[j,1];
						matches[i,2] = matches[j,2];
						matches[j,0] = h;
						matches[j,1] = t;
						matches[j,2] = p;
					};
					
			for (i = 0; i < count; i++)
				printf(\"%s\t%s\n\",matches[i,1],matches[i,2]);
		};"
	)"

}

picker_tui() {

	command="$(
	echo "$all_results" | fzf --with-nth 1 --delimiter '\t' | \
		awk -F '\t' \
		"{
			if (NF==2)
				printf(\"xdg-open %s\n\",\$2);
			else {
				gsub(/ .*$/,\"\",\$1);
				printf(\"man %s\n\",\$1);
			}
		};"
	)"

}

search_man $@

all_results="$results"

search_wiki $@

all_results="${all_results:+$all_results\n}$results"

picker_tui

eval "$command"