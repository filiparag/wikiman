#! /bin/sh

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

search_man() {

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

	results_man="$(
		printf '%s\n%s' "$results_name" "$results_desc" | awk '!seen[$0] && NF>0 {print} {++seen[$0]};'
	)"

}

search_wiki() {

	for lang in $conf_wiki_lang; do
		if [ -d "/usr/share/doc/arch-wiki/html/$lang" ]; then
			paths="$paths /usr/share/doc/arch-wiki/html/$lang"
		else
			echo "warning: ArchWiki documentation for '$lang' does not exist" 1>&2
		fi
	done
	
	if [ "$(echo "$paths" | wc -w)" = '0' ]; then
		return
	fi

	results_title="$(
		eval "find $paths -type f -name '*.html'" | \
		awk -F'/' \
			"BEGIN {
				IGNORECASE=1;
				count=0;
			};
			{
				title = \$NF
				gsub(/\.html.*/,\"\",title);
				gsub(\"_\",\" \",title);

				path = \$0
				gsub(/:[0-9]+$/,\"\",path);

				lang = \$7;

				if (title~/^Category:/) {
					gsub(/^Category:/,\"\",title);
					title = title \" (Category)\";
				}

				matched = title;
				gsub(/$greedy_query/,\"\",matched);

				lm = length(matched)
				gsub(\" \",\"\",matched);
				
				if (length(matched)==0)
					accuracy = length(title)*100;
				else
					accuracy = 100-lm*100/length(title);

				if (accuracy>0) {
					matches[count,0] = accuracy;
					matches[count,1] = title;
					matches[count,2] = path;
					matches[count,3] = lang;
					count++;
				}

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

	if [ "$conf_quick_search" != 'true' ]; then

		results_text="$(
			eval "rg -U -S -c '$rg_query' $paths" | \
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

					lang = \$7;

					if (title~/^Category:/) {
						gsub(/^Category:/,\"\",title);
						title = title \" (Category)\";
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

	fi

	results_wiki="$(
		printf '%s\n%s' "$results_title" "$results_text" | awk '!seen[$0] && NF>0 {print} {++seen[$0]};'
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

	if [ "$(echo "$conf_man_lang" | wc -w)" = '1' ] && [ "$(echo "$conf_wiki_lang" | wc -w)" = '1' ]; then
		columns='1'
	else
		columns='2,1'
	fi

	command="$(
		echo "$all_results" | \
		eval "fzf --with-nth $columns --delimiter '\t' $preview --reverse --prompt 'wikiman > '" | \
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

  -h  display this help and exit"

}

init

while getopts l:s:H:pqhR o; do
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
	(h) help;
		exit;;
    (*) exit 1;;
  esac
done
shift "$((OPTIND - 1))"

if [ $# = 0 ]; then
	echo "error: empty search query" 1>&2
	exit 254
else
	query="$*"
	rg_query="$(echo "$*" | sed 's/ /\|/g')"
	greedy_query="\w*$(echo "$*" | sed 's/ /\\\w\*|\\w\*/g')\w*"
fi

if echo "$conf_sources" | grep -q '\<man\>'; then
	search_man
	all_results="$results_man"
fi

if echo "$conf_sources" | grep -q '\<archwiki\>'; then
	search_wiki "$@"
	all_results="$(
		printf '%s\n%s' "$all_results" "$results_wiki"
	)"
fi

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