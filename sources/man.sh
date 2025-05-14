#!/bin/sh

name='man'
description='Local system'\''s manual pages'
path="$(manpath | tr ':' ' ')"

available() {

	[ -d "$path" ]
	command="$(
		echo "$path" | "$conf_awk" -F ' ' \
		"{
			for(i=1;i<=NF;i++)
				out = out ((i>1)?\" || \":\"\") \"[ -d '\" \$i \"' ]\";
		}; END { print out; }"
	)"

	eval "$command"

}

describe() {

	printf "%s\t%s\n" "$name" "$description"

}

info() {

	if available; then
		state="$(echo "$conf_sources" | grep -q "$name" && echo "+")"
		count="$(eval "$conf_find $path -type f" | wc -l | sed 's| ||g')"
		printf '%-10s %-28s %3s %8i  %s\n' "$name" "$description" "$state" "$count" "$path"
	else
		state="$(echo "$conf_sources" | grep -q "$name" && echo "x")"
		printf '%-10s %-30s %-11s (not installed)\n' "$name" "$description" "$state"
	fi

}

get_man_path() {

	man_default_paths="$(
		manpath 2>/dev/null | "$conf_awk" -F':' "{
			OFS=\" \";
			for(i=1; i<=NF; i++)
				if(\"$lang\"!=\"en\")
					\$i = \$i \"/$lang*\";
				else
					\$i = \$i \"\";
			print \$0;
		}"
	)"

	man_search_paths="$(
		eval "$conf_find $man_default_paths -maxdepth 0 -printf '%p '" 2>/dev/null
	)"

	[ "$(echo "$man_search_paths" | wc -w | sed 's| ||g')" -gt 0 ]

}

list() {

	for lang in $conf_man_lang; do

		if ! get_man_path; then
			echo "warning: man pages for '$lang' do not exist" 1>&2
			continue
		else
			man_search_dirs="$(
				eval "$conf_find $man_search_paths -maxdepth 1 -regextype sed -regex '.*man[0-9]\+$' -printf '%p '"
			)"
		fi

		eval "$conf_find $man_search_dirs -maxdepth 1 -type f" | \
		"$conf_awk" -F'/' \
			"BEGIN {
				IGNORECASE=1;
				OFS=\"\t\"
			};
			\$NF ~ /$rg_query/ {
				title = \$NF;
				gsub(/\.\w+$/,\"\",title);

				section = title;
				gsub(/^.*\./,\"\",section);

				gsub(/\.\w+$/,\"\",title);

				lang=\"en\"
				if (\$(NF-2)!=\"man\")
					lang=\$(NF-2);

				print title \" (\" section \")\", lang, \"$name\", \$0;
			};"
	done

}

search() {

	results_name=''
	results_desc=''

	# Search by name

	for lang in $conf_man_lang; do
		if ! get_man_path; then
			echo "warning: man pages for '$lang' do not exist" 1>&2
			continue
		else
			man_search_dirs="$(
				eval "$conf_find $man_search_paths -maxdepth 1 -name 'man*' -printf '%p '"
			)"
		fi
		res="$(
			eval "$conf_find $man_search_dirs -maxdepth 1 -type f" | \
			"$conf_awk" -F'/' \
				"BEGIN {
					IGNORECASE=1;
					count=0;
					and_op = \"$conf_and_operator\" == \"true\";
					split(\"$query\",kwds,\" \");
				};
				{
					title = \$NF;
					gsub(/\.\w+$/,\"\",title);

					section = title;
					gsub(/^.*\./,\"\",section);

					gsub(/\.\w+$/,\"\",title);

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
						gsub(/$rg_query/,\"\",matched);
						accuracy = 100-length(matched)*100/length(title);
					}

					if (accuracy>0)
						printf(\"%f\t%s\t%s\t$lang\t%s\n\", accuracy, title, section, \$0);
				};"
		)"
		results_name="$(
			printf '%s\n%s' "$results_name" "$res"
		)"
	done

	# Sort name results

	results_name="$(
		echo "$results_name" | "$conf_awk" -F '\t' \
			"BEGIN {
				IGNORECASE=1;
			};
			NF>0 {
				printf(\"%s\t%s (%s)\t%s\t$name\t%s\n\",\$1+0,\$2,\$3,\$4,\$5);
			};" | \
		"$conf_sort" -rV -k1 | cut -d'	' -f2-
	)"

	# Search by description

	apropos -L en >/dev/null 2>/dev/null
	apropos_lang_mode="$?"

	if [ "$conf_quick_search" != 'true' ] && [ "$apropos_lang_mode" != '5' ]; then

		for lang in $conf_man_lang; do
			if ! get_man_path; then
				continue
			else
				man_search_dirs="$(
					echo "$man_search_paths" | sed 's/ $//g; s| |:|g'
				)"
			fi
			res="$(
				eval "apropos -M $man_search_dirs $query" 2>/dev/null | \
				"$conf_awk" "BEGIN {
					IGNORECASE=1;
					and_op = \"$conf_and_operator\" == \"true\";
					split(\"$query\",kwds,\" \");
				}; {
					accuracy = !and_op;
					if (and_op) {
						kwdmatches = 0;
						description = \"\";

						for (i=4;i<=NF;i++)
							description = description \$i;

						for (k in kwds) {
							subs = gsub(kwds[k],\"\",description);
							if (subs>0) {
								kwdmatches++;
								accuracy = accuracy + subs;
							}
						}

						if (kwdmatches<length(kwds))
							accuracy = 0;

					}
					gsub(/ *\(|\)/,\"\",\$2);
					if (accuracy>0)
						printf(\"%s (%s)\t$lang\t$name\n\",\$1,\$2);
				}; END { print \"\n\"};"
			)"
			results_desc="$(
				printf '%s\n%s\n' "$results_desc" "$res"
			)"
		done

	fi

	# Remove duplicates

	printf '%s\n%s' "$results_name" "$results_desc" | "$conf_awk" "!seen[\$1\$2\$3]++ && NF>0"

}

eval "$1"
