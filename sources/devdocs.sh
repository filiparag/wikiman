#!/bin/sh

name='devdocs'
description='Collection of all DevDocs'
path="$conf_sys_usr/share/doc/devdocs"

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
		>&2 echo "warning: DevDocs do not exist"
		return 1
	fi

	langs="$(echo "$conf_wiki_lang" | "$conf_awk" -F ' ' \
    "{
        printf(\"|\");
		for(i=1;i<=NF;i++) {
			lang=tolower(\$i);
			gsub(/[-_].*$/,\"\",lang);
            if (!seen[lang]) {
                ++seen[lang];
                printf(\"%s|\",lang);
            };
		}
    }")"

    if ! echo "$langs" | grep -Fq '|en|'; then
		echo "warning: DevDocs are only available in English" 1>&2
		return 1
	fi

    nf="$(echo "$path" | "$conf_awk" -F '/' "{print NF+1}")"

    query_books="$(
        echo "$query" | \
        "$conf_awk" '{print $1}' | \
        "$conf_awk" -F ',' \
        "/^=/ {
            OFS=\"\n\";
            gsub(/^=/,\"\",\$0);
            for(i=1;i<=NF;i++)
                print \$i;
        }" | sort | uniq
    )"

    books="$(
        find "$path" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort
    )"

    query_books_invalid="$(
        printf '%s\n=\n%s' "$books" "$query_books" | "$conf_awk" \
        "
        \$0 ~ \"=\" {
            query = 1;
            next;
        }
        /^\s*$/ {next;}
        {
            if (!query) {
                ++seen[\$0];
            } else if (!seen[\$0]) {
                printf(\"%s \",\$0);
            }
        }"
    )"

    if [ -n  "$query_books_invalid" ]; then
        >&2 echo "warning: invalid DevDocs book: $query_books_invalid"
        return 1
    fi

    paths="$(
        printf '%s\n%s' "$query_books" "$books" | "$conf_awk" \
        "{
            ++count[\$0];
            if (count[\$0]==2) {
                printf(\"$path/%s \", \$0);
            }
        }"
    )"

    if [ -z "$query_books" ]; then
        run_mode='return'
    elif [ "$query" = "$(echo "$query" | cut -d ' ' -f2-)" ]; then
        run_mode='list'
        paths="${paths:-$path}"
    else
        run_mode='search'
        query="$(
            echo "$query" | cut -d ' ' -f2-
        )"
        rg_query="$(
            if [ "$conf_and_operator" = 'true' ]; then
                echo "$rg_query" | cut -d ')' -f2-
            else
                echo "$rg_query" | cut -d '|' -f2-
            fi
        )"
        greedy_query="$(
            echo "$greedy_query" | cut -d '|' -f2-
        )"
    fi

}

list() {

    eval "$conf_find $paths -mindepth 2 -type f -name '*.html'" 2>/dev/null | "$conf_awk" -F '/' \
    "BEGIN {
        IGNORECASE=1;
        OFS=\"\t\"
    };
    {
        book = \$$nf
        title = \"\";
        for (i=$nf+1; i<=NF; i++) {
            title = title ((i==$nf+1) ? \"\" : \" \") \$i;
        }

        gsub(/\.html$/,\"\",title);
        gsub(\"%2f\",\" \",title);

        if (title == \"index\") {
            next;
        }
        if (title ~ /^_/) {
            gsub(/^_/,\"\",title);
            title = title;
        }
        title = sprintf(\"%s [%s]\", title, book);

        lang=\"en\";
        path=\$0;

        print title, lang, \"$name\", path;
    };"

}

search() {

    results_title="$(
        eval "$conf_find $paths -type f -name '*.html'" 2>/dev/null | "$conf_awk" -F '/' \
        "BEGIN {
            IGNORECASE=1;
            OFS=\"\t\"
            and_op = \"$conf_and_operator\" == \"true\";
            split(\"$query\",kwds,\" \");
        };
        {
            book = \$$nf
            title = \"\";
            for (i=$nf+1; i<=NF; i++) {
                title = title ((i==$nf+1) ? \"\" : \" \") \$i;
            }

            gsub(/\.html$/,\"\",title);
            gsub(\"%2f\",\" \",title);

            if (title == \"index\") {
                next;
            }
            if (title ~ /^_/) {
                gsub(/^_/,\"\",title);
                title = title;
            }
            title = sprintf(\"%s [%s]\", title, book);

            lang=\"en\";
            path=\$0;

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

            if (accuracy > 0) {
                printf(\"%s\t%s\t%s\t$name\t%s\n\",accuracy,title,lang,path);
            }
        };" | \
		"$conf_sort" -rV -k1 | cut -d'	' -f2-
	)"

    if [ "$conf_quick_search" != 'true' ]; then

		results_text="$(
			eval "rg -g '*.html' -U -i -c '$rg_query' $paths" | "$conf_awk" -F '/' \
            "BEGIN {
                IGNORECASE=1;
                OFS=\"\t\"
            };
            {
                hits = \$NF;
                gsub(/^.*:/,\"\",hits);

                gsub(/:[0-9]+$/,\"\",\$0);

                book = \$$nf
                title = \"\";
                for (i=$nf+1; i<=NF; i++) {
                    title = title ((i==$nf+1) ? \"\" : \" \") \$i;
                }

                gsub(/\.html$/,\"\",title);
                gsub(\"%2f\",\" \",title);

                if (title == \"index\") {
                    next;
                }
                if (title ~ /^_/) {
                    gsub(/^_/,\"\",title);
                    title = title;
                }
                title = sprintf(\"%s [%s]\", title, book);

                lang=\"en\";
                path=\$0;

                printf(\"%s\t%s\t%s\t$name\t%s\n\",hits,title,lang,path);
            };" | \
			"$conf_sort" -rV -k1 | cut -d'	' -f2-
		)"

	fi

	printf '%s\n%s\n' "$results_title" "$results_text" | "$conf_awk" "!seen[\$0] && NF>0 {print} {++seen[\$0]};"

}

auto_mode() {

    setup || return 1

    if [ -z "$paths" ] && ! echo "$conf_sources" | grep -qv "^$name$"; then
        >&2 echo 'warning: enable DevDocs books by starting a query with =book1,book2'
        return;
    fi

    eval "$run_mode"

}

case "$1" in
    available|describe|info)
        eval "$1";;
    *)
        auto_mode;;
esac
