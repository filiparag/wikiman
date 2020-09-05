#!/usr/bin/env fish

complete -c wikiman -f
complete -c wikiman -s h -x -d 'display help and exit'
complete -c wikiman -s R -x -d 'print raw output'
complete -c wikiman -s S -x -d 'list available sources and exit'
complete -c wikiman -s p -x -d 'disable quick result preview'
complete -c wikiman -s q -x -d 'enable quick search mode'
complete -c wikiman -s c -x -d 'show source column'
complete -c wikiman -s k -x -d 'keep open after viewing a result'
complete -c wikiman -s W -x -d 'print widget code for specified shell and exit'

complete -c wikiman -s l -r -x -d 'comma separated search languages'
complete -c wikiman -s s -r -x -d 'comma separated sources'
complete -c wikiman -s f -r -x -d 'fuzzy finder to use'
complete -c wikiman -s H -r -x -d 'viewer for HTML pages'

complete -c wikiman -s s -a 'man'       -d 'manual pages'
complete -c wikiman -s s -a 'arch'      -d 'Arch Wiki'
complete -c wikiman -s s -a 'gentoo'    -d 'Gentoo Wiki'
complete -c wikiman -s s -a 'fbsd'      -d 'FreeBSD Documentation'
complete -c wikiman -s s -a 'tldr'      -d 'TLDR pages'

complete -c wikiman -s f -a 'fzf'   -d 'fuzzy finder'
complete -c wikiman -s f -a 'sk'    -d 'skim'

set locales (
    ls /usr/share/i18n/locales/ |\
    awk -F'_' '/^[a-z]{2}_[^@]{2}$/ && !seen[$1] {print $1; seen[$1]++}' |\
    tr '\n' ' '
)

set browsers (
    grep 'html\|http' /usr/share/applications/mimeinfo.cache |\
    cut -d'=' -f2 | tr ';' ' ' | cut -d'.' -f1 | sort | uniq
)

for txtbrw in w3m links links2 elinks lynx browsh
    which $txtbrw 1>/dev/null 2>/dev/null && set browsers "$browsers $txtbrw"
end

complete -c wikiman -s l -a "$locales"
complete -c wikiman -s H -a "$browsers"