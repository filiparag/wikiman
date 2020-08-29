#! /bin/dash

config_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}/wikiman"

init() {

	mkdir -p "$config_dir"

	config_file="$config_dir/wikiman.conf"

	if [ -f "$config_file" ] && [ -r "$config_file" ]; then
		conf_man_lang="$(
			awk -F '=' '/^[ ,\t]*man_lang/ {
				gsub(","," ",$2);
				gsub(/#.*/,"",$2);
				print $2;
				exit
			}' "$config_file"
		)"
		conf_wiki_lang="$(
			awk -F '=' '/^[ ,\t]*wiki_lang/ {
				gsub(","," ",$2);
				gsub(/#.*/,"",$2);
				print $2;
				exit
			}' "$config_file"
		)"
	else
		echo "warning: configuration file missing, using defaults" 1>&2
	fi

	conf_man_lang="${conf_man_lang:-en}"
	conf_wiki_lang="${conf_wiki_lang:-en}"

}

search_man() {
	
	query="$(echo "$@" | sed 's/ /\|/g')"

	# Search by name

	for lang in $conf_man_lang; do
		if [ "$lang" = 'en' ]; then
			man_search_path='/usr/share/man/man'
		else
			man_search_path="/usr/share/man/$lang/man"
		fi
		results="${results:+$results\n}$(
			find "$man_search_path"* -type f | \
			awk -F'/' \
				"BEGIN {
					IGNORECASE=1;
				};
				/$query/ {
					title = \$NF
					gsub(/\..*/,\"\",title);

					section = \$(NF-1)
					gsub(/[a-z]*/,\"\",section);

					printf(\"%s (%s)\t$lang\tman\n\",title,section);
				};"
		)"
	done

	# Search by description

	for lang in $conf_man_lang; do
		results="${results:+$results\n}$(
			apropos -L "$lang" $@ | \
			awk "{ 
				gsub(/\(|\)/,\"\",\$2);
				printf(\"%s (%s)\t$lang\tman\n\",\$1,\$2);
			};"
		)"
	done

	# Remove duplicates

	results="$(
		echo "$results" | awk '!seen[$0] && NF>0 {print} {++seen[$0]};'
	)"

}

search_wiki() {

	query="$(echo "$@" | sed 's/ /\|/g')"

	results="$(
		rg -U -S -c "$query" /usr/share/doc/arch-wiki/html/en/ | \
		awk -F'/' \
		"BEGIN {
			count = 0
		};
		{
			hits = \$NF
			gsub(/^.*:/,\"\",hits);

			title = \$NF
			gsub(/\.html.*/,\"\",title);
			gsub(\"_\",\" \",title);

			path = \$0
			gsub(/:[0-9]+$/,\"\",path);

			if (title~/^Category:/) {
				gsub(/^Category:/,\"\",title);
				title = title \" (Category)\"
			}

			matches[count,0] = hits + 0;
			matches[count,1] = title;
			matches[count,2] = path;

			count++;
		};
		END {
			for (i = 0; i < count; i++)
				for (j = i; j < count; j++)
					if (matches[i,0] < matches[j,0]) {
						h = matches[i,0];
						t = matches[i,1];
						p = matches[i,2];
						matches[i,0] = matches[j,0];
						matches[i,1] = matches[j,1];
						matches[i,2] = matches[j,2];
						matches[j,0] = h;
						matches[j,1] = t;
						matches[j,2] = p;
					};
					
			for (i = 0; i < count; i++)
				printf(\"%s\ten\tarchwiki\t%s\n\",matches[i,1],matches[i,2]);
		};"
	)"

}

picker_tui() {

	command="$(
	echo "$all_results" | fzf --with-nth 2,1 --delimiter '\t' | \
		awk -F '\t' \
		"{
			if (NF==3) {
				gsub(/ .*$/,\"\",\$1);
				printf(\"man -L %s %s\n\",\$2,\$1);
			} else {
				printf(\"xdg-open %s\n\",\$4);
			}
		};"
	)"

}

init

search_man $@

all_results="$results"

search_wiki $@

all_results="${all_results:+$all_results\n}$results"

picker_tui

eval "$command"