#!/bin/sh

name='gentoo'
path='/usr/share/doc/gentoo-wiki/wiki'

available() {

	[ -d "$path" ]

}

info() {

	if available; then
		state="$(echo "$conf_sources" | grep -q "$name" && echo "+")"
		count="$($conf_find "$path" -type f | wc -l)"
		printf '%-10s %3s %8i  %s\n' "$name" "$state" "$count" "$path"
	else
		state="$(echo "$conf_sources" | grep -q "$name" && echo "x")"
		printf '%-12s %-11s (not installed)\n' "$name" "$state"
	fi

}

setup() {

	results_title=''
	results_text=''

	if ! [ -d "$path" ]; then
		echo "warning: Gentoo Wiki documentation does not exist" 1>&2
		return 1
	fi

	rg_ignore="/^(File|Talk|Handbook Talk|Template|Template talk|Project|Project talk|Help|Help talk|User|User talk|Translations|Translations talk|Special|Special talk|Foundation|Foundation talk):/"
	langs="/$(
		echo "$conf_wiki_lang" | \
		"$conf_awk" "{ l=tolower(\$0); gsub(/ +/,\"|\",l); gsub(/(^\|)|(\|$)/,\"\",l); gsub(\"_\",\"-\",l); print l}"
	)/"
	nf="$(echo "$path" | "$conf_awk" -F '/' "{print NF+1}")"

}

list() {

	setup || return 1

	eval "$conf_find $path -type f -name '*.html'" | "$conf_awk" -F '/' \
			"BEGIN {
				IGNORECASE=1;
				OFS=\"\t\";
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

				if (lang ~ $langs)
					print title, lang, \"$name\", path;
			};"

}

search() {

	setup || return 1

	results_title="$(
		eval "$conf_find $path -type f -name '*.html'" | "$conf_awk" -F '/' \
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
					printf(\"%s\t%s\t$name\t%s\n\",matches[i,1],matches[i,3],matches[i,2]);
			};"
		)"

	if [ "$conf_quick_search" != 'true' ]; then

		results_text="$(
			eval "rg -U -S -c '$rg_query' $path" | \
			"$conf_awk" -F'/' \
				"BEGIN {
					IGNORECASE=1;
					count=0;
				};
				ND>0 {
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
							
					for (i = 0; i<count; i++)
						printf(\"%s\t%s\t$name\t%s\n\",matches[i,1],matches[i,3],matches[i,2]);
				};"
			)"

	fi

	printf '%s\n%s\n' "$results_title" "$results_text" | "$conf_awk" "!seen[\$0] && NF>0 {print} {++seen[\$0]};"

}

eval "$1"
