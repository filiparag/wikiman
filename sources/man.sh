#!/bin/sh

results=''

search() {

	# Search by name

	for lang in $conf_man_lang; do
		if [ "$lang" = 'en' ]; then
			man_search_path='/usr/share/man/man'
		else
			if [ -d "/usr/share/man/$lang" ]; then
				man_search_path="/usr/share/man/$lang/"
			else
				echo "warning: man pages for '$lang' do not exist" 1>&2
				continue
			fi
		fi
		res="$(
			find "$man_search_path"* -type f | \
			awk -F'/' \
				"BEGIN {
					IGNORECASE=1;
					count=0;
				};
				\$NF ~ /$rg_query/ {
					title = \$NF
					gsub(/\.\w+$/,\"\",title);

					section = title
					gsub(/^.*\./,\"\",section);

					gsub(/\.\w+$/,\"\",title);

					matched = title
					gsub(/$rg_query/,\"\",matched)
					accuracy = 100-length(matched)*100/length(title)

					matches[count,0] = accuracy;
					matches[count,1] = title;
					matches[count,2] = section;
					count++;
				};
				END {
					for (i = 0; i < count; i++)
						for (j = i; j < count; j++)
							if (matches[i,0] < matches[j,0]) {
								a = matches[i,0];
								t = matches[i,1];
								s = matches[i,2];
								matches[i,0] = matches[j,0];
								matches[i,1] = matches[j,1];
								matches[i,2] = matches[j,2];
								matches[j,0] = a;
								matches[j,1] = t;
								matches[j,2] = s;
							};
					for (i = 0; i < count; i++)
						printf(\"%s (%s)\t$lang\tman\n\",matches[i,1],matches[i,2]);
				};"
		)"
		results_name="$(
			printf '%s\n%s' "$results_name" "$res"
		)"
	done

	# Search by description

	if [ "$conf_quick_search" != 'true' ]; then
	
		for lang in $conf_man_lang; do
			if [ "$lang" = 'en' ]; then
				man_search_flag='-L en'
			else
				if [ -d "/usr/share/man/$lang" ]; then
					man_search_flag="-M /usr/share/man/$lang/"
				else
					continue
				fi
			fi
			res="$(
				eval "apropos $man_search_flag $query" 2>/dev/null | \
				awk "{ 
					gsub(/ *\(|\)/,\"\",\$2);
					printf(\"%s (%s)\t$lang\tman\n\",\$1,\$2);
				}; END { print \"\n\"};"
			)"
			results_desc="$(
				printf '%s\n%s' "$results_desc" "$res"
			)"
		done

	fi

	# Remove duplicates

	results="$(
		printf '%s\n%s' "$results_name" "$results_desc" | awk '!seen[$0] && NF>0 {print} {++seen[$0]};'
	)"

}