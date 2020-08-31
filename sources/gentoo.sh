#!/bin/sh

# # Add extension
# find . -type f -exec mv {} {}.html \;

# # Strip header and footer
# find . -type f -print0 | xargs -0  --no-run-if-empty -I{} sh -c "cat \"{}\" | pup 'head, div#content' --pre | sponge \"{}\""

# # Use local CSS
# find . -name '*.html' -exec sed -i 's|https://assets.gentoo.org/tyrian/|../|g; ' {} \;

# # Replace links
# find . -name '*.html' -exec sed -i 's|https://wiki.gentoo.org/index.php?title=|/wiki/|g;' {} \;
# find . -name '*.html' -exec sed -i 's|index.php?title=|/wiki/|g;' {} \;
# find . -name '*.html' -exec sed -i 's/href="\/wiki\/\([^"]*\)"/href=".\/\1.html"/g; ' {} \;

search() {

	results=''
	results_title=''
	results_text=''

	path="/usr/share/doc/gentoo-wiki/wiki"

	if ! [ -d "$path" ]; then
		echo "warning: Gentoo Wiki documentation does not exist" 1>&2
		return
	fi

	rg_ignore="/^(File|Talk|Template|Template talk|Project|Project talk|Help|Help talk|User|User talk|Translations|Translations talk|Special|Special talk|Foundation|Foundation talk):/"
	langs="/$(echo "$conf_wiki_lang" | sed 's/ \+/ /g; s/^ *//g; s/ *$//g; s/ /\|/g')/"
	nf="$(echo "$path" | awk -F '/' '{print NF+1}')"

	results_title="$(
		eval "find $path -type f -name '*.html'" | awk -F '/' \
			"BEGIN {
				IGNORECASE=1;
				count=0;
			};
			{
				lang = \"en\"
				if (NF-$nf) {
					n = \$NF
					gsub(/[a-z]{2}(-[a-z]{2})?\.html/,\"\",n);
					if (n==\"\") {
						lang = \$NF
						gsub(/\.html$/,\"\",lang);
						dec = 1;
					} else {
						dec = 0;
					}
					title = \"\"
					for (i=$nf; i<=NF-dec; i++)
						title = title ((i==$nf) ? \"\" : \"/\") \$i
				} else {
					title = \$NF;
				}

				gsub(/\.html$/,\"\",title);
				gsub(\"_\",\" \",title);

				path = \$0;

				if (lang ~ $langs && title !~ $rg_ignore) {

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
					printf(\"%s\t%s\tgentoo\t%s\n\",matches[i,1],matches[i,3],matches[i,2]);
			};"
		)"

	if [ "$conf_quick_search" != 'true' ]; then

		results_text="$(
			eval "rg -U -S -c '$rg_query' $path" | \
			awk -F'/' \
				"BEGIN {
					IGNORECASE=1;
					count=0;
				};
				{
					hits = \$NF
					gsub(/^.*:/,\"\",hits);

					gsub(/:[0-9]+$/,\"\",\$0);

					lang = \"en\"
					if (NF-$nf) {
						n = \$NF
						gsub(/[a-z]{2}(-[a-z]{2})?\.html/,\"\",n);
						if (n==\"\") {
							lang = \$NF
							gsub(/\.html$/,\"\",lang);
							dec = 1;
						} else {
							dec = 0;
						}
						title = \"\"
						for (i=$nf; i<=NF-dec; i++)
							title = title ((i==$nf) ? \"\" : \"/\") \$i
					} else {
						title = \$NF;
					}

					gsub(/\.html$/,\"\",title);
					gsub(\"_\",\" \",title);

					path = \$0;

					if (lang ~ $langs && title !~ $rg_ignore) {

						matches[count,0] = hits;
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
						printf(\"%s\t%s\tgentoo\t%s\n\",matches[i,1],matches[i,3],matches[i,2]);
				};"
			)"

	fi

	results="$(
		printf '%s\n%s' "$results_title" "$results_text" | awk '!seen[$0] && NF>0 {print} {++seen[$0]};'
	)"

}