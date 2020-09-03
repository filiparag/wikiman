#!/bin/sh

# BSD compatibility: Use GNU find and awk

conf_find='find'
"$conf_find" -name . >/dev/null 2>/dev/null || \
	conf_find='gfind'

conf_awk='awk'
[ "$(echo 'test_string' | "$conf_awk" '/\w/' 2>/dev/null)" = 'test_string' ] || \
	conf_awk='gawk'

tui_preview() {
	command="$(echo "$@" | "$conf_awk" -F '\t' \
		"{
			if (\$3==\"man\") {
				if (NF==4) {
					printf(\"man %s\",\$4);
				} else {
					sec=\$1
					gsub(/.*\(/,\"\",sec);
					gsub(/\).*$/,\"\",sec);
					gsub(/ .*$/,\"\",\$1);
					printf(\"man -S %s -L %s %s\n\",sec,\$2,\$1);
				}
			} else {
				printf(\"w3m '%s'\n\",\$NF);
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

	# Configuration variables

	config_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}/wikiman"
	config_file="/etc/wikiman.conf"
	config_file_usr="$config_dir/wikiman.conf"

	[ -f "$config_file" ] && [ -r "$config_file" ] || \
		config_file=''
	[ -f "$config_file_usr" ] && [ -r "$config_file_usr" ] || \
		config_file_usr=''

	if [ -z "$config_file" ] && [ -z "$config_file_usr" ]; then
		echo "warning: configuration file missing, using defaults" 1>&2
	else
		conf_sources="$(
			"$conf_awk" -F '=' "/^[ ,\t]*sources/ {
				gsub(\",\",\" \",\$2);
				gsub(/#.*/,\"\",\$2);
				gsub(/ +/,\" \",\$2);
				gsub(\" \",\"\",\$2);
				value = \$2;
			}; END { print value }" "$config_file" "$config_file_usr"
		)"
		conf_fuzzy_finder="$(
			"$conf_awk" -F '=' "/^[ ,\t]*fuzzy_finder/ {
				gsub(/#.*/,\"\",\$2);
				gsub(/[ \t]+/,\"\",\$2);
				value = \$2;
			}; END { print value }" "$config_file" "$config_file_usr"
		)"
		conf_quick_search="$(
			"$conf_awk" -F '=' "/^[ ,\t]*quick_search/ {
				gsub(/#.*/,\"\",\$2);
				gsub(/[ \t]+/,\"\",\$2);
				value = \$2;
			}; END { print value }" "$config_file" "$config_file_usr"
		)"
		conf_raw_output="$(
			"$conf_awk" -F '=' "/^[ ,\t]*raw_output/ {
				gsub(/#.*/,\"\",\$2);
				gsub(/[ \t]+/,\"\",\$2);
				value = \$2;
			}; END { print value }" "$config_file" "$config_file_usr"
		)"
		conf_man_lang="$(
			"$conf_awk" -F '=' "/^[ ,\t]*man_lang/ {
				gsub(\",\",\" \",\$2);
				gsub(/#.*/,\"\",\$2);
				value = \$2;
			}; END { print value }" "$config_file" "$config_file_usr"
		)"
		conf_wiki_lang="$(
			"$conf_awk" -F '=' "/^[ ,\t]*wiki_lang/ {
				gsub(\",\",\" \",\$2);
				gsub(/#.*/,\"\",\$2);
				value = \$2;
			}; END { print value }" "$config_file" "$config_file_usr"
		)"
		conf_tui_preview="$(
			"$conf_awk" -F '=' "/^[ ,\t]*tui_preview/ {
				gsub(/#.*/,\"\",\$2);
				gsub(/[ \t]+/,\"\",\$2);
				value = \$2;
			}; END { print value }" "$config_file" "$config_file_usr"
		)"
		conf_tui_keep_open="$(
			"$conf_awk" -F '=' "/^[ ,\t]*tui_keep_open/ {
				gsub(/#.*/,\"\",\$2);
				gsub(/[ \t]+/,\"\",\$2);
				value = \$2;
			}; END { print value }" "$config_file" "$config_file_usr"
		)"
		conf_tui_source_column="$(
			"$conf_awk" -F '=' "/^[ ,\t]*tui_source_column/ {
				gsub(/#.*/,\"\",\$2);
				gsub(/[ \t]+/,\"\",\$2);
				value = \$2;
			}; END { print value }" "$config_file" "$config_file_usr"
		)"
		conf_tui_html="$(
			"$conf_awk" -F '=' "/^[ ,\t]*tui_html/ {
				gsub(/#.*/,\"\",\$2);
				gsub(/[ \t]+/,\"\",\$2);
				value = \$2;
			}; END { print value }" "$config_file" "$config_file_usr"
		)"
	fi

	# Sources

	sources_dir="/usr/share/wikiman/sources"
	sources_dir_usr="$config_dir/sources"

	# Detect source modules

	sources="$(
		eval "$conf_find $sources_dir_usr $sources_dir -type f 2>/dev/null" | \
		"$conf_awk" -F '/' \
			"BEGIN {OFS=\"\t\"} {
				path = \$0;
				name = \$NF;
				gsub(/\..*$/,\"\",name);
				if (sources[name]==0)
					print name, path;
				sources[name]++;

			};"
	)"

	if [ -z "$sources" ]; then
		echo "error: no sources available" 1>&2
		exit 3
	fi

	modules="$(echo "$sources" | "$conf_awk" -F '\t' "{print \$1}")"
	available_sources=""

	for mod in $modules; do
		module_path="$(echo "$sources" | "$conf_awk" -F '\t' "\$1==\"$mod\" {print \$2}")"
		if "$module_path" available; then
			available_sources="$available_sources $(basename "$module_path" | cut -d'.' -f1)"
		fi
	done

	# Set configuration variables

	conf_sources="${conf_sources:-$available_sources}"
	conf_fuzzy_finder="${conf_fuzzy_finder:-fzf}"
	conf_quick_search="${conf_quick_search:-false}"
	conf_raw_output="${conf_raw_output:-false}"
	conf_man_lang="${conf_man_lang:-en}"
	conf_wiki_lang="${conf_wiki_lang:-en}"
	conf_tui_preview="${conf_tui_preview:-true}"
	conf_tui_keep_open="${conf_tui_keep_open:-false}"
	conf_tui_source_column="${conf_tui_source_column:-false}"
	conf_tui_html="${conf_tui_html:-w3m}"

	export conf_sources
	export conf_fuzzy_finder
	export conf_quick_search
	export conf_raw_output
	export conf_man_lang
	export conf_wiki_lang
	export conf_tui_preview
	export conf_tui_keep_open
	export conf_tui_source_column
	export conf_tui_html
	export conf_find
	export conf_awk

}

combine_results() {

	all_results="$(
		printf '%s' "$all_results" | \
		"$conf_awk" -F '\t' \
			"BEGIN {
				OFS=\"\t\"
				count = 0;
			};
			NF>0 {
				source = \$3;
				srcc[source]++;
				src[source,srcc[source]] = \$0;
				count++;
			};
			END {
				for (s in srcc)
					srco[s] = srcc[s];
				i = 0;
				while (i<count)
					for (s in srcc) {
						if (srcc[s]>0) {
							ind = srco[s]-srcc[s]+1;
							print src[s,ind];
							srcc[s]--;
							i++;
						}
					}
			};"
	)"

}

picker_tui() {

	if [ "$conf_tui_preview" != 'false' ]; then
		preview="--preview 'WIKIMAN_TUI_PREVIEW=1 wikiman {}'"
	fi

	if [ "$conf_tui_source_column" = 'true' ]; then
		source_column='3,'
	fi

	if [ "$(echo "$conf_man_lang" | wc -w | sed 's| ||g')" = '1' ] && \
		[ "$(echo "$conf_wiki_lang" | wc -w | sed 's| ||g')" = '1' ]; then
		columns="${source_column}1"
	else
		columns="${source_column},2,1"
	fi

	choice="$(
		echo "$all_results" | \
		eval "$conf_fuzzy_finder --with-nth $columns --delimiter '\t' \
			$preview --reverse --prompt 'wikiman > '"
	)"

	[ $? -ne 0 ] && return 1

	command="$(
		echo "$choice" | \
			"$conf_awk" -F '\t' "{
				if (\$3==\"man\") {
					if (NF==4) {
						printf(\"man %s\",\$4);
					} else {
						sec=\$1
						gsub(/.*\(/,\"\",sec);
						gsub(/\).*$/,\"\",sec);
						gsub(/ .*$/,\"\",\$1);
						printf(\"man -S %s -L %s %s\n\",sec,\$2,\$1);
					}
				} else {
					printf(\"$conf_tui_html '%s'\n\",\$NF);
				}
			};"
	)"

}

help() {

	echo "Usage: wikiman [OPTION]... [KEYWORD]...
Offline search engine for manual pages and distro wikis combined

If no keywords are provided, show all pages.

Options:

  -l  search language(s)

  -s  sources to use

  -f  fuzzy finder to use

  -q  enable quick search mode

  -p  disable quick result preview

  -k  keep open after viewing a result

  -c  show source column

  -H  viewer for HTML pages

  -R  print raw output

  -S  list available sources and exit

  -h  display this help and exit
"

}

sources() {

	modules="$(echo "$sources" | "$conf_awk" -F '\t' "{print \$1}")"

	if [ "$modules" != '' ]; then
		printf '%-10s %5s %6s  %s\n' 'NAME' 'STATE' 'PAGES' 'PATH'
	fi

	for mod in $modules; do
		module_path="$(echo "$sources" | "$conf_awk" -F '\t' "\$1==\"$mod\" {print \$2}")"
		"$module_path" info
	done

}

init

while getopts l:s:H:f:pqhRSkc o; do
  case $o in
	(p) conf_tui_preview='false';;
	(H) conf_tui_html="$OPTARG";;
	(k) conf_tui_keep_open='true';;
	(l) conf_man_lang="$(
			echo "$OPTARG" | sed 's/,/ /g; s/-/_/g'
		)";
		conf_wiki_lang="$(
			echo "$OPTARG" | sed 's/,/ /g; s/_/-/g'
		)";;
	(s) conf_sources="$(
			echo "$OPTARG" | sed 's/,/ /g; s/-/_/g'
		)";;
	(f) conf_fuzzy_finder="$OPTARG";;
	(q) conf_quick_search='true';;
	(R) conf_raw_output='true';;
	(c) conf_tui_source_column='true';;
	(S) sources;
		exit;;
	(h) help;
		exit;;
    (*) exit 1;;
  esac
done
shift "$((OPTIND - 1))"

# Dependency check
dependencies="man rg $conf_awk $conf_tui_html $conf_fuzzy_finder $conf_find"

for dep in $dependencies; do
	which "$dep" >/dev/null 2>/dev/null || {
		echo "error: missing dependency: cannot find '$dep' executable" 1>&2
		exit 127
	}
done

# Check if fuzzy finder compatible with used fzf's parameters

case $conf_fuzzy_finder in
	'fzf'|'sk');;
	*)
		echo "error: $conf_fuzzy_finder is not compatible with the paramters used in this script" 1>&2
		exit 4;;
esac

if [ $# = 0 ]; then
	# echo 'error: empty search query' 1>&2
	# exit 254
	user_action='list'
else
	user_action='search'
	query="$*"
	rg_query="$(echo "$*" | sed 's/ /\|/g')"
	greedy_query="\w*$(echo "$*" | sed 's/ /\\\w\*|\\w\*/g')\w*"
	export query
	export rg_query
	export greedy_query
fi

for src in $conf_sources; do

	module_path="$(echo "$sources" | "$conf_awk" -F '\t' "\$1==\"$src\" {print \$2}")"

	if [ -z "$module_path" ]; then
		echo "error: source '$src' does not exist" 1>&2
		exit 2
	fi
	
	results="$($module_path $user_action)"

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
		if [ "$conf_tui_keep_open" = 'true' ]; then
			while picker_tui; do
				eval "$command"
			done
		else
			picker_tui && eval "$command"
		fi
	fi
else
	echo "search: no results for '$*'" 1>&2
	exit 255
fi
