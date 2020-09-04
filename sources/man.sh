#!/bin/sh

name='man'
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

info() {

	if available; then
		state="$(echo "$conf_sources" | grep -q "$name" && echo "+")"
		count="$(eval "$conf_find $path -type f" | wc -l | sed 's| ||g')"
		printf '%-10s %3s %8i  %s\n' "$name" "$state" "$count" "$path"
	else
		state="$(echo "$conf_sources" | grep -q "$name" && echo "x")"
		printf '%-12s %-11s (not installed)\n' "$name" "$state"
	fi

}

get_man_path() {

	man_default_paths="$(
		manpath 2>/dev/null | awk -F':' "{
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
				eval "$conf_find $man_search_paths -maxdepth 1 -name 'man*' -printf '%p '"
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
				};
				\$NF ~ /$rg_query/ {
					title = \$NF;
					gsub(/\.\w+$/,\"\",title);

					section = title;
					gsub(/^.*\./,\"\",section);

					gsub(/\.\w+$/,\"\",title);

					matched = title;
					gsub(/$rg_query/,\"\",matched);
					accuracy = 100-length(matched)*100/length(title);

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
				count=0;
			};
			NF>0 {
				matches[count,0] = \$1+0;
				matches[count,1] = \$2;
				matches[count,2] = \$3;
				matches[count,3] = \$4;
				matches[count,4] = \$5;
				count++;
			};
			END {
				for (i = 0; i < count; i++)
					for (j = i; j < count; j++)
						if (matches[i,0] < matches[j,0]) {
							a = matches[i,0];
							t = matches[i,1];
							s = matches[i,2];
							l = matches[i,3];
							p = matches[i,4];
							matches[i,0] = matches[j,0];
							matches[i,1] = matches[j,1];
							matches[i,2] = matches[j,2];
							matches[i,3] = matches[j,3];
							matches[i,4] = matches[j,4];
							matches[j,0] = a;
							matches[j,1] = t;
							matches[j,2] = s;
							matches[j,3] = l;
							matches[j,4] = p;
						};
				for (i = 0; i < count; i++)
					printf(\"%s (%s)\t%s\t$name\t%s\n\",matches[i,1],matches[i,2],matches[i,3],matches[i,4]);
			};"
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
				"$conf_awk" "{ 
					gsub(/ *\(|\)/,\"\",\$2);
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
