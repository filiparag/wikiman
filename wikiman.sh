#!/usr/bin/env dash
#!/bin/sh

tui_preview() {
	command="$(echo "$@" | awk -F '\t' \
		"{
			if (\$3==\"man\") {
				if (NF==4) {
					printf(\"man -l %s\",\$4);
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
			awk -F '=' '/^[ ,\t]*sources/ {
				gsub(","," ",$2);
				gsub(/#.*/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_fuzzy_finder="$(
			awk -F '=' '/^[ ,\t]*fuzzy_finder/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_quick_search="$(
			awk -F '=' '/^[ ,\t]*quick_search/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_raw_output="$(
			awk -F '=' '/^[ ,\t]*raw_output/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_man_lang="$(
			awk -F '=' '/^[ ,\t]*man_lang/ {
				gsub(","," ",$2);
				gsub(/#.*/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_wiki_lang="$(
			awk -F '=' '/^[ ,\t]*wiki_lang/ {
				gsub(","," ",$2);
				gsub(/#.*/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_tui_preview="$(
			awk -F '=' '/^[ ,\t]*tui_preview/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_tui_keep_open="$(
			awk -F '=' '/^[ ,\t]*tui_keep_open/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_tui_html="$(
			awk -F '=' '/^[ ,\t]*tui_html/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
	fi

	conf_sources="${conf_sources:-man archwiki}"
	conf_fuzzy_finder="${conf_fuzzy_finder:-fzf}"
	conf_quick_search="${conf_quick_search:-false}"
	conf_raw_output="${conf_raw_output:-false}"
	conf_man_lang="${conf_man_lang:-en}"
	conf_wiki_lang="${conf_wiki_lang:-en}"
	conf_tui_preview="${conf_tui_preview:-true}"
	conf_tui_keep_open="${conf_tui_keep_open:-false}"
	conf_tui_html="${conf_tui_html:-w3m}"

	export conf_sources
	export conf_quick_search
	export conf_raw_output
	export conf_man_lang
	export conf_wiki_lang
	export conf_tui_preview
	export conf_tui_keep_open
	export conf_tui_html

	# Sources

	sources_dir="/usr/share/wikiman/sources"
	sources_dir_usr="$config_dir/sources"

	sources="$(
		eval "find $sources_dir_usr $sources_dir -type f 2>/dev/null" | \
		awk -F '/' \
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

}

combine_results() {

	all_results="$(
		printf '%s' "$all_results" | \
		awk -F '\t' \
			'BEGIN {
				OFS="\t"
				count = 0;
			};
			NF>0 {
				if (length(sc[$3])==0)
					sc[$3] = 0;

				sources[$3,sc[$3],0] = $1;
				sources[$3,sc[$3],1] = $2;
				sources[$3,sc[$3],2] = $4;

				sc[$3]++;
				count++;
			};
			END {
				for (s in sc)
					sc2[s] = sc[s];
				for (i=0; i<count; i++)
					for (s in sc)
						if (sc[s]>=0) {
							si = sc2[s]-sc[s];
							print sources[s,si,0], sources[s,si,1], s, sources[s,si,2];
							sc[s]--;
						}
			};'
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

	choice="$(
		echo "$all_results" | \
		eval "$conf_fuzzy_finder --with-nth $columns --delimiter '\t' \
			$preview --reverse --prompt 'wikiman > '"
	)"

	[ $? -ne 0 ] && return 1

	command="$(
		echo "$choice" | \
			awk -F '\t' "{
				if (\$3==\"man\") {
					if (NF==4) {
						printf(\"man -l %s\",\$4);
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

Options:

  -l  search language(s)

  -s  sources to use

  -f  fuzzy finder to use

  -q  enable quick search mode

  -p  disable quick result preview

  -k  keep open after viewing a result

  -H  viewer for HTML pages

  -R  print raw output

  -S  list available sources and exit

  -h  display this help and exit
"

}

sources() {

	modules="$(echo "$sources" | awk -F '\t' '{print $1}')"

	if [ "$modules" != '' ]; then
		printf '%-10s %5s %6s  %s\n' 'NAME' 'STATE' 'PAGES' 'PATH'
	fi

	for mod in $modules; do
		module_path="$(echo "$sources" | awk -F '\t' "\$1==\"$mod\" {print \$2}")"
		"$module_path" info
	done

}

init

while getopts l:s:H:f:pqhRSk o; do
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
	(S) sources;
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
	export query
	export rg_query
	export greedy_query
fi

for src in $conf_sources; do

	module_path="$(echo "$sources" | awk -F '\t' "\$1==\"$src\" {print \$2}")"

	if [ -z "$module_path" ]; then
		echo "error: source '$src' does not exist" 1>&2
		exit 2
	fi
	
	results="$($module_path search)"

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
