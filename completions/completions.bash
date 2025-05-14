#!/usr/bin/env bash

function _wikiman_completions()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="-l -s -f -q -a -p -k -c -H -R -S -W -v -h"

    if [[ ${cur} == -* ]] ; then
        COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
        return 0
    fi

    local fuzzy_finders fzff browsers txtbrw locales

    fuzzy_finders=''
    for fzff in fzf sk; do
		command -v $fzff 1>/dev/null 2>/dev/null && fuzzy_finders="$fuzzy_finders $fzff"
	done

    browsers=" $(
		test -f /usr/share/applications/mimeinfo.cache && \
		gawk -F '=' '/html|http/ {
			gsub(".desktop;"," ",$2);
			split($2, sbrw, " ");
			for (b in sbrw) {
				if (!seen[sbrw[b]])
					brw = brw sprintf("%s ", sbrw[b]);
				seen[sbrw[b]]++
			}
		} END {print brw}' /usr/share/applications/mimeinfo.cache || echo ''
	)"

	for txtbrw in w3m links links2 elinks lynx browsh; do
		command -v $txtbrw 1>/dev/null 2>/dev/null && \
		echo "$browsers" | grep -qv " $txtbrw " && \
		browsers="$browsers $txtbrw "
	done

    locales="$(
		test -d /usr/share/i18n/locales && \
		ls /usr/share/i18n/locales |\
		awk -F'_' '/^[a-z]{2}_[^@]{2}$/ && !seen[$1] {printf("%s ", $1); seen[$1]++}' \
		|| echo 'en'
	)"

    case ${prev} in
        -s)
            COMPREPLY=($(compgen -W "$(WIKIMAN_INTERNAL=1 wikiman -C sources_bash)" -- ${cur}));;
        -W)
            COMPREPLY=($(compgen -W "bash fish zsh" -- ${cur}));;
        -f)
            COMPREPLY=($(compgen -W "$fuzzy_finders" -- ${cur}));;
        -H)
            COMPREPLY=($(compgen -W "$browsers" -- ${cur}));;
        -l)
            COMPREPLY=($(compgen -W "$locales" -- ${cur}));;
        *)
            COMPREPLY=($(compgen -W "${opts}" -- ${cur}));;
    esac

}

complete -F _wikiman_completions wikiman
