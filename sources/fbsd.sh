#!/bin/sh

name='fbsd'
path="$conf_sys_usr/share/doc/freebsd-docs"

available() {

	[ -d "$path" ]

}

info() {

	if available; then
		state="$(echo "$conf_sources" | grep -q "$name" && echo "+")"
		count="$("$conf_find" "$path" -type f | wc -l | sed 's| ||g')"
		printf '%-10s %3s %8i  %s\n' "$name" "$state" "$count" "$path"
	else
		state="$(echo "$conf_sources" | grep -q "$name" && echo "x")"
		printf '%-12s %-11s (not installed)\n' "$name" "$state"
	fi

}

setup() {

	results_title=''
	results_text=''

	if ! available; then
		echo "warning: FreeBSD documentation does not exist" 1>&2
		return 1
	fi

	langs="$(echo "$conf_wiki_lang" | awk -F ' ' '{
		for(i=1;i<=NF;i++) {
			lang=tolower($i);
			gsub(/[-_].*$/,"",lang);
			locale=toupper($i);
			gsub(/^.*[-_]/,"",locale);
			printf("%s_%s%s",lang,(length($i)==2)?"*":locale,(i==NF)?"":"|");
		}
	}')"
		
	search_paths="$(
		"$conf_find" "$path" -maxdepth 1 -mindepth 1 -type d -printf '%p\n' | \
		awk "/$langs/"
	)"

	for rg_l in $(echo "$langs" | sed 's|*|.*|g; s|\||\n|g'); do
		p="$(echo "$search_paths" | awk "/$rg_l/ {printf(\"%s/* \",\$0)}")"
		if [ "$p" != '' ]; then
			paths="$paths $p"
		else
			l="$(echo "$rg_l" | sed 's|_\.\*||g')"
			echo "warning: FreeBSD documentation for '$l' does not exist" 1>&2
		fi
	done

	if [ "$(echo "$paths" | wc -w | sed 's| ||g')" = '0' ]; then
		return 1
	fi

	nf="$(echo "$path" | awk -F '/' '{print NF+1}')"

}

list() {

	setup || return 1

	eval "$conf_find $paths -type f -name '*.html'" 2>/dev/null | \
	awk -F '/' \
		"BEGIN {
			IGNORECASE=1;
			OFS=\"\t\"
		};
		{
			title = \"\";
			for (i=$nf+3; i<=NF; i++) {
				fragment = toupper(substr(\$i,0,1))substr(\$i,2);
				title = title ((i==$nf+3) ? \"\" : \"/\") fragment;
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
				title = \"\";
				for (i=$nf+3; i<=NF; i++) {
				 	fragment = toupper(substr(\$i,0,1))substr(\$i,2);
					title = title ((i==$nf+3) ? \"\" : \"/\") fragment;
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

					title = \"\"
					for (i=$nf+3; i<=NF; i++) {
						fragment = toupper(substr(\$i,0,1))substr(\$i,2);
						title = title ((i==$nf+3) ? \"\" : \"/\") fragment;
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
