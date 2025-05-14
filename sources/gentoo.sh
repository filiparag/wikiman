#!/bin/sh

name='gentoo'
description='Gentoo Wiki'
path="$conf_sys_usr/share/doc/gentoo-wiki/wiki"

available() {

	[ -d "$path" ]

}

describe() {

	printf "%s\t%s\n" "$name" "$description"

}

info() {

	if available; then
		state="$(echo "$conf_sources" | grep -q "$name" && echo "+")"
		count="$($conf_find "$path" -type f | wc -l | sed 's| ||g')"
		printf '%-10s %-28s %3s %8i  %s\n' "$name" "$description" "$state" "$count" "$path"
	else
		state="$(echo "$conf_sources" | grep -q "$name" && echo "x")"
		printf '%-10s %-30s %-11s (not installed)\n' "$name" "$description" "$state"
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
				and_op = \"$conf_and_operator\" == \"true\";
				split(\"$query\",kwds,\" \");
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
					accuracy = 0;

					if (and_op) {
						kwdmatches = 0;

						for (k in kwds) {
							subs = gsub(kwds[k],\"\",matched);
							if (subs>0) {
								kwdmatches++;
								accuracy = accuracy + subs;
							}
						}

						if (kwdmatches<length(kwds))
							accuracy = 0;
					} else {
						gsub(/$greedy_query/,\"\",matched);

						lm = length(matched)
						gsub(\" \",\"\",matched);
						gsub(\"_\",\"\",matched);

						if (length(matched)==0)
							accuracy = length(title)*100;
						else
							accuracy = 100-lm*100/length(title);
					}

					if (accuracy>0) {
						printf(\"%s\t%s\t%s\t$name\t%s\n\",accuracy,title,lang,path);
					}
				}
			};" | \
			"$conf_sort" -rV -k1 | cut -d'	' -f2-
		)"

	if [ "$conf_quick_search" != 'true' ]; then

		results_text="$(
			eval "rg -U -i -c '$rg_query' $path" | \
			"$conf_awk" -F'/' \
				"BEGIN {
					IGNORECASE=1;
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
						printf(\"%s\t%s\t%s\t$name\t%s\n\",hits,title,lang,path);
					}
				};" | \
			"$conf_sort" -rV -k1 | cut -d'	' -f2-
		)"

	fi

	printf '%s\n%s\n' "$results_title" "$results_text" | "$conf_awk" "!seen[\$0] && NF>0 {print} {++seen[\$0]};"

}

eval "$1"
