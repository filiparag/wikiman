#!/bin/sh

name='fbsd'
description='FreeBSD Documentation'
path="$conf_sys_usr/share/doc/freebsd-docs"

available() {

	[ -d "$path" ]

}

describe() {

	printf "%s\t%s\n" "$name" "$description"

}

info() {

	if available; then
		state="$(echo "$conf_sources" | grep -q "$name" && echo "+")"
		count="$("$conf_find" "$path" -type f -name '*.html' | wc -l | sed 's| ||g')"
		printf '%-10s %-28s %3s %8i  %s\n' "$name" "$description" "$state" "$count" "$path"
	else
		state="$(echo "$conf_sources" | grep -q "$name" && echo "x")"
		printf '%-10s %-30s %-11s (not installed)\n' "$name" "$description" "$state"
	fi

}

setup() {

	results_title=''
	results_text=''

	if ! available; then
		echo "warning: FreeBSD documentation does not exist" 1>&2
		return 1
	fi

	langs="$(echo "$conf_wiki_lang" | "$conf_awk" -F ' ' '{
		for(i=1;i<=NF;i++) {
			lang=tolower($i);
			gsub(/[-_].*$/,"",lang);
			locale=tolower($i);
			gsub(/^.*[-_]/,"",locale);
			if (length($i)==2) {
				printf("%s%s",lang,(i==NF)?"":"|");
			} else {
				printf("%s-%s%s",lang,(length($i)==2)?"*":locale,(i==NF)?"":"|");
			}
		}
	}')"

	search_paths="$(
		"$conf_find" "$path" -maxdepth 1 -mindepth 1 -type d -printf '%p\n' | \
		"$conf_awk" "/$langs/"
	)"

	paths=''
	for rg_l in $(echo "$langs" | sed 's|*|.*|g; s|\||\n|g'); do
		p="$(echo "$search_paths" | "$conf_awk" "/$rg_l/ {printf(\"%s/* \",\$0)}")"
		if [ "$p" != '' ]; then
			paths="$paths${paths:+$newline}$p"
		else
			l="$(echo "$rg_l" | sed 's|_\.\*||g')"
			echo "warning: FreeBSD documentation for '$l' does not exist" 1>&2
		fi
	done
	paths="$(
		echo "$paths" | "$conf_sort" | uniq | tr '\n' ' '
	)"

	if [ "$(echo "$paths" | wc -w | sed 's| ||g')" = '0' ]; then
		return 1
	fi

	nf="$(echo "$path" | "$conf_awk" -F '/' '{print NF+1}')"

}

list() {

	setup || return 1

	eval "$conf_find $paths -type f -name '*.html'" 2>/dev/null | \
	"$conf_awk" -F '/' \
		"BEGIN {
			IGNORECASE=1;
			OFS=\"\t\"
		};
		{
			for (i=$nf; i<=NF; i++) {
				if (\$i == \"public\") {
					if (\$(i+2)==\"books\") {
						type=\"Book\";
						start=i+4;
					} else {
						type=\"Article\";
						start=i+3;
					}
				}
			}

			title = \"\";
			for (i=start; i<=NF-1; i++) {
				fragment = toupper(substr(\$i,0,1))substr(\$i,2);
				title = sprintf(\"%s%s%s\",title,title==\"\"?\"\":\" \",fragment);
			}
			if (title==\"\") {
				next;
			}

			gsub(/\.html$/,\"\",title);
			gsub(\"-\",\" \",title);

			lang=\$$nf;
			path=\$0;

			book = \$($nf+1) \"/\" \$($nf+2);
			title = sprintf(\"%s (%s)\",title,book);

			print title, lang, \"$name\", path;
		};"

}

search() {

	setup || return 1

	results_title="$(
		eval "$conf_find $paths -type f -name '*.html'" 2>/dev/null | \
		"$conf_awk" -F '/' \
			"BEGIN {
				IGNORECASE=1;
				and_op = \"$conf_and_operator\" == \"true\";
				split(\"$query\",kwds,\" \");
			};
			{
				for (i=$nf; i<=NF; i++) {
					if (\$i == \"public\") {
						if (\$(i+2)==\"books\") {
							type=\"Book\";
							start=i+4;
						} else {
							type=\"Article\";
							start=i+3;
						}
					}
				}

				title = \"\";
				for (i=start; i<=NF-1; i++) {
					fragment = toupper(substr(\$i,0,1))substr(\$i,2);
					title = sprintf(\"%s%s%s\",title,title==\"\"?\"\":\" \",fragment);
				}
				if (title==\"\") {
					next;
				}

				gsub(/\.html$/,\"\",title);
				gsub(\"-\",\" \",title);

				lang=\$$nf;
				path=\$0;

				book = \$($nf+1) \"/\" \$($nf+2);
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

				if ((and_op && accuracy>0) || (!and_op && (accuracy > 0 || book ~ /$rg_query/))) {
					title = sprintf(\"%s (%s)\",title,book);
					printf(\"%s\t%s\t%s\t$name\t%s\n\",accuracy,title,lang,path);
				}
			};" | \
			"$conf_sort" -rV -k1 | cut -d'	' -f2-
	)"

	if [ "$conf_quick_search" != 'true' ]; then

		results_text="$(
			eval "rg -U -i -c '$rg_query' $paths" | \
			"$conf_awk" -F '/' \
				"BEGIN {
					IGNORECASE=1;
				};
				\$0 !~ /.*:0$/ {

					hits = \$NF;
					gsub(/^.*:/,\"\",hits);

					gsub(/:[0-9]+$/,\"\",\$0);

					for (i=$nf; i<=NF; i++) {
						if (\$i == \"public\") {
							if (\$(i+2)==\"books\") {
								type=\"Book\";
								start=i+4;
							} else {
								type=\"Article\";
								start=i+3;
							}
						}
					}

					title = \"\";
					for (i=start; i<=NF-1; i++) {
						fragment = toupper(substr(\$i,0,1))substr(\$i,2);
						title = sprintf(\"%s%s%s\",title,title==\"\"?\"\":\" \",fragment);
					}
					if (title==\"\") {
						next;
					}

					gsub(/\.html$/,\"\",title);
					gsub(\"-\",\" \",title);

					lang=\$$nf;
					path=\$0;

					book = \$($nf+1) \"/\" \$($nf+2);

					title = sprintf(\"%s (%s)\",title,book);

					printf(\"%s\t%s\t%s\t$name\t%s\n\",hits,title,lang,path);
				};" | \
			"$conf_sort" -rV -k1 | cut -d'	' -f2-
			)"

	fi

	printf '%s\n%s\n' "$results_title" "$results_text" | "$conf_awk" "!seen[\$0] && NF>0 {print} {++seen[\$0]};"

}

eval "$1"
