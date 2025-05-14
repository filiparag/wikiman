#!/bin/sh

name='arch'
description='ArchWiki'
path="$conf_sys_usr/share/doc/arch-wiki/html"

available() {

	[ -d "$path" ]

}

describe() {

	printf "%s\t%s\n" "$name" "$description"

}

info() {

	if available; then
		state="$(echo "$conf_sources" | grep -q "$name" && echo "+")"
		count="$("$conf_find" "$path" -type f | wc -l | sed 's| ||g')"
		printf '%-10s %-28s %3s %8i  %s\n' "$name" "$description" "$state" "$count" "$path"
	else
		state="$(echo "$conf_sources" | grep -q "$name" && echo "x")"
		printf '%-10s %-30s %-11s (not installed)\n' "$name" "$description" "$state"
	fi

}

setup() {

	results_title=''
	results_text=''

	langs="$(echo "$conf_wiki_lang" | "$conf_awk" -F ' ' '{
		for (i = 1; i <= NF; i++) {
			lang = $i;
			gsub(/[_-].*$/,"",lang);
			lang = tolower(lang);
			loc = $i;
			locale = gsub(/^.*[_-]/,"",loc);
			loc = toupper(loc);
			if (locale)
				printf("%s-%s%s", lang, loc, (i == NF) ? "" : "|");
			else {
				printf("%s|", lang);
				printf("%s*%s", lang, (i == NF) ? "" : "|");
			}
		}
	}')"

	search_paths="$(
		"$conf_find" "$path" -maxdepth 1 -mindepth 1 -type d -printf '%p\n' | \
		"$conf_awk" "/$langs/"
	)"

	paths=''
	for rg_l in $(echo "$langs" | sed 's|*|.*|g; s|\||\n|g'); do
		p="$(echo "$search_paths" | "$conf_awk" "/$rg_l/ {printf(\"%s \",\$0)}")"
		if [ "$p" != '' ]; then
			paths="$paths${paths:+$newline}$p"
		else
			l="$(echo "$rg_l" | sed 's|_\.\*||g')"
			echo "warning: Arch Wiki for '$l' does not exist" 1>&2
		fi
	done
	paths="$(
		echo "$paths" | "$conf_sort" | uniq | tr '\n' ' '
	)"

	if [ "$(echo "$paths" | wc -w | sed 's| ||g')" = '0' ]; then
		return 1
	fi

	nf="$(echo "$path" | "$conf_awk" -F '/' '{print NF+2}')"

}

list() {

	setup || return 1

	eval "$conf_find $paths -type f -name '*.html'" | \
	"$conf_awk" -F'/' \
		"BEGIN {
			IGNORECASE=1;
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

			lang = \$($nf-1);

			if (title~/^Category:/) {
				gsub(/^Category:/,\"\",title);
				title = title \" (Category)\";
			}

			print title, lang, \"$name\", path;

		};"

}

search() {

	setup || return 1

	results_title="$(
		eval "$conf_find $paths -type f -name '*.html'" | \
		"$conf_awk" -F'/' \
			"BEGIN {
				IGNORECASE=1;
				OFS=\"\t\";
				and_op = \"$conf_and_operator\" == \"true\";
				split(\"$query\",kwds,\" \");
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

				lang = \$($nf-1);

				if (title~/^Category:/) {
					gsub(/^Category:/,\"\",title);
					title = title \" (Category)\";
				}

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
					print accuracy, title, lang, \"$name\", path;
				}

			};" | \
		"$conf_sort" -rV -k1 | cut -d'	' -f2-
	)"

	if [ "$conf_quick_search" != 'true' ]; then

		results_text="$(
			eval "rg -U -i -c '$rg_query' $paths" | \
			"$conf_awk" -F'/' \
				"BEGIN {
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

					lang = \$($nf-1);

					if (title~/^Category:/) {
						gsub(/^Category:/,\"\",title);
						title = title \" (Category)\";
					}

					print hits+0, title, lang, \"$name\", path;
				};" | \
			"$conf_sort" -rV -k1 | cut -d'	' -f2-
		)"

	fi

	printf '%s\n%s\n' "$results_title" "$results_text" | "$conf_awk" "!seen[\$0] && NF>0 {print} {++seen[\$0]};"

}

eval "$1"
