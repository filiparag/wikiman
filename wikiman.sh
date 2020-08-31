#!/bin/sh

tui_preview() {
	command="$(echo "$@" | awk -F '\t' \
		"{
			if (NF==3) {
				sec=\$1
				gsub(/.*\(/,\"\",sec);
				gsub(/\).*$/,\"\",sec);
				gsub(/ .*$/,\"\",\$1);
				printf(\"man -S %s -L %s %s\n\",sec,\$2,\$1);
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

init() {

	config_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}/wikiman"
	config_file_etc="/etc/wikiman.conf"
	config_file_usr="$config_dir/wikiman.conf"

	[ -f "$config_file_etc" ] && [ -r "$config_file_etc" ] || \
		config_file_etc=''
	[ -f "$config_file_usr" ] && [ -r "$config_file_usr" ] || \
		config_file_usr=''

	if [ -z "$config_file_etc" ] && [ -z "$config_file_usr" ]; then
		echo "warning: configuration file missing, using defaults" 1>&2
	else
		conf_sources="$(
			awk -F '=' '/^[ ,\t]*sources/ {
				gsub(","," ",$2);
				gsub(/#.*/,"",$2);
				value = $2;
			}; END { print value }' "$config_file_etc" "$config_file_usr"
		)"
		conf_quick_search="$(
			awk -F '=' '/^[ ,\t]*quick_search/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file_etc" "$config_file_usr"
		)"
		conf_raw_output="$(
			awk -F '=' '/^[ ,\t]*raw_output/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file_etc" "$config_file_usr"
		)"
		conf_man_lang="$(
			awk -F '=' '/^[ ,\t]*man_lang/ {
				gsub(","," ",$2);
				gsub(/#.*/,"",$2);
				value = $2;
			}; END { print value }' "$config_file_etc" "$config_file_usr"
		)"
		conf_wiki_lang="$(
			awk -F '=' '/^[ ,\t]*wiki_lang/ {
				gsub(","," ",$2);
				gsub(/#.*/,"",$2);
				value = $2;
			}; END { print value }' "$config_file_etc" "$config_file_usr"
		)"
		conf_tui_preview="$(
			awk -F '=' '/^[ ,\t]*tui_preview/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file_etc" "$config_file_usr"
		)"
		conf_tui_html="$(
			awk -F '=' '/^[ ,\t]*tui_html/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file_etc" "$config_file_usr"
		)"
	fi

	conf_sources="${conf_sources:-man archwiki}"
	conf_quick_search="${conf_quick_search:-false}"
	conf_raw_output="${conf_raw_output:-false}"
	conf_man_lang="${conf_man_lang:-en}"
	conf_wiki_lang="${conf_wiki_lang:-en}"
	conf_tui_preview="${conf_tui_preview:-true}"
	conf_tui_html="${conf_tui_html:-w3m}"

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

	if [ "$(echo "$conf_man_lang" | wc -w)" = '1' ] && \
		[ "$(echo "$conf_wiki_lang" | wc -w)" = '1' ]; then
		columns='1'
	else
		columns='2,1'
	fi

	command="$(
		echo "$all_results" | \
		eval "fzf --with-nth $columns --delimiter '\t' \
			$preview --reverse --prompt 'wikiman > '" | \
		awk -F '\t' \
			"{
				if (NF==3) {
					sec=\$1
					gsub(/.*\(/,\"\",sec);
					gsub(/\).*$/,\"\",sec);
					gsub(/ .*$/,\"\",\$1);
					printf(\"man -S %s -L %s %s\n\",sec,\$2,\$1);
				} else if (NF==4) {
					printf(\"$conf_tui_html '%s'\n\",\$4);
				}
			};"
	)"

}

help() {

	echo "Usage: wikiman [OPTION]... [KEYWORD]...
Offline search engine for ArchWiki and manual pages combined

With no KEYWORD, list all available results.

Options:

  -l  search language(s)
      default: en

  -s  sources to use
      default: man, archwiki

  -q  enable quick search mode

  -p  disable quick result preview

  -H  viewer for HTML pages
      default: w3m

  -R  print raw output

  -S  list available sources and exit

  -h  display this help and exit"

}

init

while getopts l:s:H:pqhRS o; do
  case $o in
	(p) conf_tui_preview='false';;
	(H) conf_tui_html="$OPTARG";;
	(l) conf_man_lang="$(
			echo "$OPTARG" | sed 's/,/ /g; s/-/_/g'
		)";
		conf_wiki_lang="$(
			echo "$OPTARG" | sed 's/,/ /g; s/_/-/g'
		)";;
	(s) conf_sources="$(
			echo "$OPTARG" | sed 's/,/ /g; s/-/_/g'
		)";;
	(q) conf_quick_search='true';;
	(R) conf_raw_output='true';;
	(S) find /usr/share/wikiman/sources/ -type f 2>/dev/null | \
		awk -F '/' '{gsub(/\..*$/,"",$NF); print $NF; }'
		exit;;
	(h) help;
		exit;;
    (*) exit 1;;
  esac
done
shift "$((OPTIND - 1))"

if [ $# = 0 ]; then
	echo 'error: empty search query' 1>&2
	exit 254
else
	query="$*"
	rg_query="$(echo "$*" | sed 's/ /\|/g')"
	greedy_query="\w*$(echo "$*" | sed 's/ /\\\w\*|\\w\*/g')\w*"
fi

for src in $conf_sources; do

	if ! [ -f "/usr/share/wikiman/sources/$src.sh" ] || \
		! [ -r "/usr/share/wikiman/sources/$src.sh" ]; then
		echo "error: source '$src' does not exist" 1>&2
		exit 2
	fi

	. "/usr/share/wikiman/sources/$src.sh"
	search
	all_results="$(
		printf '%s\n%s' "$all_results" "$results"
	)"

done

combine_results

if echo "$all_results" | grep -cve '^\s*$' >/dev/null; then
	if [ "$conf_raw_output" != 'false' ]; then
		printf 'NAME\tLANG\tSOURCE\tPATH\n'
		echo "$all_results"
	else
		picker_tui && eval "$command"
	fi
else
	echo "search: no results for '$*'" 1>&2
	exit 255
fi