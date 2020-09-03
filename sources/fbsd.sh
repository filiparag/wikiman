#!/bin/sh

name='fbsd'
path='/usr/share/doc/freebsd-docs'

available() {

	[ -d "$path" ]

}

info() {

	if available; then
		state="$(echo "$conf_sources" | grep -q "$name" && echo "+")"
		count="$("$conf_find" "$path" -type f | wc -l)"
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

	if [ "$(echo "$paths" | wc -w)" = '0' ]; then
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
				count=0;
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

				matched = title;
				gsub(/$greedy_query/,\"\",matched);

				lm = length(matched)
				gsub(\" \",\"\",matched);
				
				if (length(matched)==0)
					accuracy = length(title)*100;
				else
					accuracy = 100-lm*100/length(title);

				book = \$($nf+1) \"/\" \$($nf+2);

				if (accuracy > 0 || book ~ /$rg_query/) {
					title = sprintf(\"%s (%s)\",title,book);
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
					printf(\"%s\t%s\t$name\t%s\n\",matches[i,1],matches[i,3],matches[i,2]);
			};"
	)"

	if [ "$conf_quick_search" != 'true' ]; then

		results_text="$(
			eval "rg -U -S -c '$rg_query' $paths" | \
			"$conf_awk" -F '/' \
				"BEGIN {
					IGNORECASE=1;
					count=0;
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
					matches[count,0] = hits;
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
						printf(\"%s\t%s\t$name\t%s\n\",matches[i,1],matches[i,3],matches[i,2]);
				};"
			)"

	fi

	printf '%s\n%s\n' "$results_title" "$results_text" | "$conf_awk" "!seen[\$0] && NF>0 {print} {++seen[\$0]};"

}

eval "$1"
