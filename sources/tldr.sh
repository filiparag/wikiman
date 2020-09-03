#!/bin/sh

name='tldr'
path='/usr/share/doc/tldr-pages'

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

setup() {


	if ! available; then
		echo "warning: tldr pages do not exist" 1>&2
		return 1
	fi

	langs="$(echo "$conf_wiki_lang" | awk -F ' ' '{
		for(i=1;i<=NF;i++) {
			lang=tolower($i);
			gsub(/[-_].*$/,"",lang);
			locale=toupper($i);
			gsub(/^.*[-_]/,"",locale);
			printf("%s%s%s",lang,(length($i)==2)?"*":"_"locale,(i==NF)?"":"|");
		}
	}')"
		
	search_paths="$(
		find "$path" -maxdepth 1 -mindepth 1 -type d -printf '%p\n' | \
		grep -P "$langs"
	)"

	for rg_l in $(echo "$langs" | sed 's|*|.*|g; s|\|| |g'); do
		p="$(echo "$search_paths" | awk "/$rg_l/ {printf(\"%s \",\$0)}")"
		if [ "$?" = '0' ]; then
			paths="$paths $p"
		else
			l="$(echo "$rg_l" | sed 's|_\.\*||g')"
			echo "warning: tldr pages for '$l' do not exist" 1>&2
		fi
	done

	if [ "$(echo "$paths" | wc -w)" = '0' ]; then
		return 1
	fi

	nf="$(echo "$path" | awk -F '/' '{print NF+1}')"

}

list() {

    setup || return 1

    eval "find $paths -type f -name '*.html'" 2>/dev/null | \
	awk -F '/' \
		"BEGIN {
			IGNORECASE=1;
			OFS=\"\t\"
		};
		{
			title = \"\";
			for (i=$nf+2; i<=NF; i++) {
				fragment = toupper(substr(\$i,0,1))substr(\$i,2);
				title = title ((i==$nf+2) ? \"\" : \"/\") fragment;
			}

			gsub(/\.html$/,\"\",title);
			gsub(\"_\",\" \",title);

            title = title \" (\" \$($nf+1) \")\"

			lang=\$$nf;
			path=\$0;

			print title, lang, \"$name\", path;
		};"

}

eval "$1"
