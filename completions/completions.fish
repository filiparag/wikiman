#!/usr/bin/env fish

function __fish_complete_wikiman

    complete -c wikiman -f
    complete -c wikiman -s h -x -d 'display help and exit'
    complete -c wikiman -s R -x -d 'print raw output'
    complete -c wikiman -s S -x -d 'list available sources and exit'
    complete -c wikiman -s p -x -d 'disable quick result preview'
    complete -c wikiman -s q -x -d 'enable quick search mode'
    complete -c wikiman -s a -x -d 'enable AND operator mode'
    complete -c wikiman -s c -x -d 'show source column'
    complete -c wikiman -s k -x -d 'keep open after viewing a result'
    complete -c wikiman -s v -x -d 'print version and exit'

    complete -c wikiman -o W -x -d 'print widget code for specified shell and exit' -a '
		fish\t""
		bash\t""
		zsh\t""
	'

    set sources (WIKIMAN_INTERNAL=1 wikiman -C sources_fish)
    complete -c wikiman -o s -r -x -d 'comma separated sources' -a "$sources"

    for fzff in fzf sk
        command -v $fzff 1>/dev/null 2>/dev/null && set fuzzy_finders "$fuzzy_finders $fzff\t\"\""
    end

    complete -c wikiman -o f -r -x -a "$fuzzy_finders" -d 'fuzzy finder to use'

    set locales (
		test -d /usr/share/i18n/locales && \
		ls /usr/share/i18n/locales |\
		awk -F'_' '/^[a-z]{2}_[^@]{2}$/ && !seen[$1] {printf("%s\\\t\"\" ", $1); seen[$1]++}' \
		|| echo 'en'
	)

    complete -c wikiman -o l -r -x -d 'comma separated search languages' -a "$locales"

    set browsers (
		test -f /usr/share/applications/mimeinfo.cache && \
		gawk -F '=' '/html|http/ {
			gsub(".desktop;"," ",$2);
			split($2, sbrw, " ");
			for (b in sbrw) {
				if (!seen[sbrw[b]])
					brw = brw sprintf("%s\\\t\"\" ", sbrw[b]);
				seen[sbrw[b]]++
			}
		} END {print brw}' /usr/share/applications/mimeinfo.cache || echo ''
	)

    for txtbrw in w3m links links2 elinks lynx browsh
        command -v $txtbrw 1>/dev/null 2>/dev/null && set browsers "$browsers $txtbrw\t\"\""
    end

    complete -c wikiman -o H -r -x -a "$browsers" -d 'viewer for HTML pages'

end

__fish_complete_wikiman
