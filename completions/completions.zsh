#compdef wikiman

_arguments -s \
		'-h[display help and exit]' \
		'-R[print raw output]' \
		'-S[list available sources and exit]' \
		'-p[disable quick result preview]' \
		'-q[enable quick search mod]' \
		'-c[show source column]' \
		'-k[keep open after viewing a result]' \
		'-W[print widget code for specified shell and exit]' \
		'-l[search language(s)]:locale:->locales' \
		'-s[sources to use]:source:->sources' \
		'-f[fuzzy finder to use]:fuzzy_finder:->fuzzy_finders' \
		'-H[viewer for HTML pages]:browser:->browsers'

case $state in
	locales)
		local -a _locales
		locales=($(
			ls /usr/share/i18n/locales |\
			awk -F'_' '/^[a-z]{2}_[^@]{2}$/ && !seen[$1] {print $1; seen[$1]++}' |\
			tr '\n' ' '
		))
		_describe 'locale' _locales
		;;
	sources)
		local -a _sources
		_sources=(
			'arch:Arch Wiki'
			'fbsd:FreeBSD Documentation'
			'gentoo:Gentoo Wiki'
			'man:manual pages'
			'tldr:TLDR pages'
		)
		_describe 'source' _sources
		;;
	fuzzy_finders)
		local -a _fuzzy_finders
		_fuzzy_finders=(
			'fzf:fuzzy finder'
			'sk:skim'
		)
		_describe 'fuzzy finder' _fuzzy_finders
		;;
	browsers)
		local -a _browsers
		_browsers=($(
			grep 'html\|http' /usr/share/applications/mimeinfo.cache |\
			cut -d'=' -f2 | tr ';' ' ' | cut -d'.' -f1 | sort | uniq
		))

		local -a txtbrw
		txtbrw=('w3m' 'links' 'links2' 'elinks' 'lynx' 'browsh')
		for browser in "${txtbrw[@]}"; do
			which "$browser" 1>/dev/null 2>/dev/null && _browsers+=("$browser")
		done

		_describe 'browser' _browsers
		;;
esac
