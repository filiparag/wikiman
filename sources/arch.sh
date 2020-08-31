#!/bin/sh

search() {

	results=''
	results_title=''
	results_text=''

	for lang in $conf_wiki_lang; do
		if [ -d "/usr/share/doc/arch-wiki/html/$lang" ]; then
			paths="$paths /usr/share/doc/arch-wiki/html/$lang"
		else
			echo "warning: Arch Wiki documentation for '$lang' does not exist" 1>&2
		fi
	done
	
	if [ "$(echo "$paths" | wc -w)" = '0' ]; then
		return
	fi

	results_title="$(
		eval "find $paths -type f -name '*.html'" | \
		awk -F'/' \
			"BEGIN {
				IGNORECASE=1;
				count=0;
			};
			{
				title = \$NF
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
					printf(\"%s\t%s\tarch\t%s\n\",matches[i,1],matches[i,3],matches[i,2]);
			};"
	)"

	if [ "$conf_quick_search" != 'true' ]; then

		results_text="$(
			eval "rg -U -S -c '$rg_query' $paths" | \
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
						printf(\"%s\t%s\tarch\t%s\n\",matches[i,1],matches[i,3],matches[i,2]);
				};"
		)"

	fi

	results="$(
		printf '%s\n%s' "$results_title" "$results_text" | awk '!seen[$0] && NF>0 {print} {++seen[$0]};'
	)"

}