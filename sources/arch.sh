#!/bin/sh

name='arch'
path='/usr/share/doc/arch-wiki/html'

available() {

	[ -d "$path" ]

}

info() {

	if available; then
		state="$(echo "$conf_sources" | grep -qP "$name" && echo "+")"
		count="$(find "$path" -type f | wc -l)"
		printf '%-10s %3s %8i  %s\n' "$name" "$state" "$count" "$path"
	else
		state="$(echo "$conf_sources" | grep -qP "$name" && echo "x")"
		printf '%-12s %-11s (not installed)\n' "$name" "$state"
	fi

}

search() {

	results=''
	results_title=''
	results_text=''

	for lang in $conf_wiki_lang; do
		if [ -d "$path/$lang" ]; then
			paths="$paths $path/$lang"
		else
			echo "warning: Arch Wiki documentation for '$lang' does not exist" 1>&2
		fi
	done
	
	if [ "$(echo "$paths" | wc -w)" = '0' ]; then
		return
	fi

	nf="$(echo "$path" | awk -F '/' '{print NF+2}')"

	results_title="$(
		eval "find $paths -type f -name '*.html'" | \
		awk -F'/' \
			"BEGIN {
				IGNORECASE=1;
				count=0;
				OFS=\"\t\";
			};
			{
				if (NF-$nf) {
					title = \"\"
					for (i=$nf; i<=NF; i++)
						title = title ((i==$nf) ? \"\" : \"/\") \$i
				} else
					title = \$NF;
				gsub(/\.html.*/,\"\",title);
				gsub(\"_\",\" \",title);

				path = \$0
				gsub(/:[0-9]+$/,\"\",path);

				lang = \$7;

				if (title~/^Category:/) {
					gsub(/^Category:/,\"\",title);
					title = title \" (Category)\";
				}

				matched = title;
				gsub(/$greedy_query/,\"\",matched);

				lm = length(matched)
				gsub(\" \",\"\",matched);
				
				if (length(matched)==0)
					accuracy = length(title)*100;
				else
					accuracy = 100-lm*100/length(title);

				if (accuracy>0) {
					matches[count,0] = accuracy;
					matches[count,1] = title;
					matches[count,2] = path;
					matches[count,3] = lang;
					count++;
				}

			};
			END {
				for (i = 0; i < count; i++)
					for (j = i; j < count; j++)
						if (matches[i,0] < matches[j,0]) {
							h = matches[i,0];
							t = matches[i,1];
							p = matches[i,2];
							l = matches[i,3];
							matches[i,0] = matches[j,0];
							matches[i,1] = matches[j,1];
							matches[i,2] = matches[j,2];
							matches[i,3] = matches[j,3];
							matches[j,0] = h;
							matches[j,1] = t;
							matches[j,2] = p;
							matches[j,3] = l;
						};
						
				for (i = 0; i < count; i++)
					print matches[i,1], matches[i,3], \"arch\", matches[i,2];
			};"
	)"

	if [ "$conf_quick_search" != 'true' ]; then

		results_text="$(
			eval "rg -U -S -c '$rg_query' $paths" | \
			awk -F'/' \
				"BEGIN {
					count = 0;
					OFS=\"\t\";
				};
				{
					hits = \$NF
					gsub(/^.*:/,\"\",hits);

					if (NF-$nf) {
						title = \"\"
						for (i=$nf; i<=NF; i++)
							title = title ((i==$nf) ? \"\" : \"/\") \$i
					} else
						title = \$NF;
					gsub(/\.html.*/,\"\",title);
					gsub(\"_\",\" \",title);

					path = \$0
					gsub(/:[0-9]+$/,\"\",path);

					lang = \$7;

					if (title~/^Category:/) {
						gsub(/^Category:/,\"\",title);
						title = title \" (Category)\";
					}

					matches[count,0] = hits + 0;
					matches[count,1] = title;
					matches[count,2] = path;
					matches[count,3] = lang;

					count++;
				};
				END {
					for (i = 0; i < count; i++)
						for (j = i; j < count; j++)
							if (matches[i,0] < matches[j,0]) {
								h = matches[i,0];
								t = matches[i,1];
								p = matches[i,2];
								l = matches[i,3];
								matches[i,0] = matches[j,0];
								matches[i,1] = matches[j,1];
								matches[i,2] = matches[j,2];
								matches[i,3] = matches[j,3];
								matches[j,0] = h;
								matches[j,1] = t;
								matches[j,2] = p;
								matches[j,3] = l;
							};
							
					for (i = 0; i < count; i++)
						print matches[i,1], matches[i,3], \"arch\", matches[i,2];
				};"
		)"

	fi

	results="$(
		printf '%s\n%s' "$results_title" "$results_text" | awk '!seen[$0] && NF>0 {print} {++seen[$0]};'
	)"

	printf '%s\n' "$results"

}

eval "$1"
