#! /usr/bin/env dash

tui_preview() {
	command="$(echo "$@" | awk -F '\t' \
		"{
			if (NF==3) {
				gsub(/ .*$/,\"\",\$1);
				printf(\"man -L %s %s\n\",\$2,\$1);
			} else if (NF==4) {
				printf(\"w3m '%s'\n\",\$4);
			}
		};"
	)"

	eval "$command"
}

if printenv WIKIMAN_TUI_PREVIEW >/dev/null; then
	tui_preview "$@"
	exit
fi

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
		conf_tui_preview="$(
			awk -F '=' '/^[ ,\t]*tui_preview/ {
				gsub(/#.*/,"",$2);
				gsub(/[ ,\t]/,"",$2);
				print $2;
				exit
			}' "$config_file"
		)"
		conf_sources="$(
			awk -F '=' '/^[ ,\t]*sources/ {
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
	conf_tui_preview="${conf_tui_preview:-true}"
	conf_sources="${conf_sources:-man archwiki}"

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
		results_name="${results_name:+$results_name\n}$(
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
		results_desc="${results_desc:+$results_desc\n}$(
			eval "apropos -L $lang $*" 2>/dev/null | \
			awk "{ 
				gsub(/\(|\)/,\"\",\$2);
				printf(\"%s (%s)\t$lang\tman\n\",\$1,\$2);
			};"
		)"
	done

	# Remove duplicates

	results="$(
		echo "$results_name\n$results_desc" | awk '!seen[$0] && NF>0 {print} {++seen[$0]};'
	)"

}

search_wiki() {

	query="$(echo "$*" | sed 's/ /\|/g')"

	for lang in $conf_wiki_lang; do
		paths="$paths /usr/share/doc/arch-wiki/html/$lang"
	done

	results="$(
		eval "rg -U -S -c '$query' $paths" | \
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

			lang = \$7

			if (title~/^Category:/) {
				gsub(/^Category:/,\"\",title);
				title = title \" (Category)\"
			}

			matches[count,0] = hits + 0;
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
				printf(\"%s\t%s\tarchwiki\t%s\n\",matches[i,1],matches[i,3],matches[i,2]);
		};"
	)"

}

combine_results() {

	all_results="$(
		echo "$all_results" | \
		awk -F '\t' \
			'NF>0 {
				count++;
				sc[$3]++;
				sources[$3,sc[$3]+0] = $0
			}
			END {
				for (var in sc) {
					ss[var] = sc[var] + 1;
				}
				for (i = 0; i < count; i++) {
					for (var in ss) {
						if (sc[var]>0) {
							print sources[var,ss[var]-sc[var]];
							sc[var]--;
						}
					}
				}
			}'
	)"

}

picker_tui() {

	if [ "$conf_tui_preview" != 'false' ]; then

		preview="--preview 'WIKIMAN_TUI_PREVIEW=1 wikiman {}'"
	fi

	command="$(
		echo "$all_results" | \
		eval "fzf --with-nth 2,1 --delimiter '\t' $preview --reverse --prompt 'wikiman > '" | \
		awk -F '\t' \
		"{
			if (NF==3) {
				gsub(/ .*$/,\"\",\$1);
				printf(\"man -L %s %s\n\",\$2,\$1);
			} else if (NF==4) {
					printf(\"xdg-open '%s'\n\",\$4);
			}
		};"
	)"

}

init

while getopts p:l:s:h o; do
  case $o in
	(p) conf_tui_preview="$OPTARG";;
	(l) conf_man_lang="$(
			echo "$OPTARG" | sed 's/,/ /g; s/-/_/g'
		)";
		conf_wiki_lang="$(
			echo "$OPTARG" | sed 's/,/ /g; s/_/-/g'
		)";;
	(s) conf_sources="$(
			echo "$OPTARG" | sed 's/,/ /g; s/-/_/g'
		)";;
    (*) exit 1
  esac
done
shift "$((OPTIND - 1))"

if echo "$conf_sources" | grep -q '\<man\>'; then

if [ $# = 0 ]; then 
	search_man "."
else
search_man "$@"
fi
all_results="$results"

fi

if echo "$conf_sources" | grep -q '\<archwiki\>'; then

search_wiki "$@"
all_results="${all_results:+$all_results\n}$results"

fi

combine_results

if echo "$all_results" | grep -cve '^\s*$' >/dev/null; then

	picker_tui && eval "$command"

fi
