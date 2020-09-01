#!/bin/sh

path='/usr/share/doc/freebsd-doc'

search() {

	results=''
	results_title=''
	results_text=''

	if ! [ -d "$path" ]; then
		echo "warning: FreeBSD documentation does not exist" 1>&2
		return
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
		find "$path" -maxdepth 1 -mindepth 1 -type d -printf '%p\n' | \
		grep -P "$langs"
	)"

	for rg_l in $(echo "$langs" | sed 's|*|.*|g; s|\||\n|g'); do
		p="$(echo "$search_paths" | grep -P "$rg_l")"
		if [ "$?" = '0' ]; then
			paths="$paths $p/books"
		else
			l="$(echo "$rg_l" | sed 's|_\.\*||g')"
			echo "warning: FreeBSD documentation for '$l' does not exist" 1>&2
		fi
	done

	if [ "$(echo "$paths" | wc -w)" = '0' ]; then
		return 1
	fi

	nf="$(echo "$path" | awk -F '/' '{print NF+1}')"

	results_title="$(
		eval "find $paths -type f -name '*.html'" 2>/dev/null | \
		awk -F '/' \
			"BEGIN {
				IGNORECASE=1;
				count=0;
			};
			{
				title = \"\"
				for (i=$nf+3; i<=NF; i++) {
				 	fragment = toupper(substr(\$i,0,1))substr(\$i,2);
					title = title ((i==$nf+3) ? \"\" : \"/\") fragment;
				}

				gsub(/\.html$/,\"\",title);
				gsub(\"-\",\" \",title);

				lang=\$$nf
				path=\$0

				matched = title;
				gsub(/$greedy_query/,\"\",matched);

				lm = length(matched)
				gsub(\" \",\"\",matched);
				
				if (length(matched)==0)
					accuracy = length(title)*100;
				else
					accuracy = 100-lm*100/length(title);

				book = \$($nf+2);

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
					printf(\"%s\t%s\tgentoo\t%s\n\",matches[i,1],matches[i,3],matches[i,2]);
			};"
	)"

	results="$results_title"

}