DEPS = man fzf rg awk w3m
UPSTREAM = 'https://github.com/filiparag/wikiman'

make:

	@echo 'Checking dependencies...'
	@which ${DEPS} >/dev/null || { echo 'Error: Missing dependency!'; exit 1; }

	@echo 'Checking documentation sources...'
	@test -d '$(prefix)/usr/share/man' -a -r '$(prefix)/usr/share/man' >/dev/null || \
		echo 'Warning: Man pages are not available!'
	@test -d '$(prefix)/usr/share/doc/arch-wiki/html' -a -r '$(prefix)/usr/share/doc/arch-wiki/html' >/dev/null || \
		echo 'Warning: Arch Wiki is not available! Run make source-arch to install.'
	@test -d '$(prefix)/usr/share/doc/gentoo-wiki/wiki/' -a -r '$(prefix)/usr/share/doc/gentoo-wiki/wiki/' >/dev/null || \
		echo 'Warning: Gentoo Wiki is not available! Run make source-gentoo to install.'
	@test -d '$(prefix)/usr/share/doc/freebsd-docs' -a -r '$(prefix)//usr/share/doc/freebsd-docs' >/dev/null || \
		echo 'Warning: FreeBSD Documentation is not available! Run make source-fbsd to install.'

source-arch:
	
	@echo 'Downoading latest Arch Wiki snapshot...'
	@curl -L -O '${UPSTREAM}/releases/download/2.4/arch-linux-docs_20200527-1.tar.xz'
	@echo 'Installing Arch Wiki...'
	@tar zxf './arch-linux-docs_20200527-1.tar.xz' -C '$(prefix)/'
	@rm './arch-linux-docs_20200527-1.tar.xz'

source-gentoo:

	@echo 'Downoading latest Gentoo Wiki snapshot...'
	@curl -L -O '${UPSTREAM}/releases/download/2.7/gentoo-wiki_20200831-1.tar.xz'
	@echo 'Installing Gentoo Wiki...'
	@tar zxf './gentoo-wiki_20200831-1.tar.xz' -C '$(prefix)/'
	@rm './gentoo-wiki_20200831-1.tar.xz'

source-fbsd:

	@echo 'Downoading latest FreeBSD Documentation snapshot...'
	@curl -L -O '${UPSTREAM}/releases/download/2.8/freebsd-docs_20200901-1.tar.xz'
	@echo 'Installing FreeBSD Documentation...'
	@tar zxf './freebsd-docs_20200901-1.tar.xz' -C '$(prefix)/'
	@rm './freebsd-docs_20200901-1.tar.xz'

install:

	@install -Dm 755 'wikiman.sh' '$(prefix)/usr/bin/wikiman'

	@mkdir -p '$(prefix)/usr/share/wikiman'
	@cp -r --preserve=mode 'sources' '$(prefix)/usr/share/wikiman/'

	@install -Dm 644 'wikiman.1.man' '$(prefix)/usr/share/man/man1/wikiman.1.gz'
	@install -Dm 644 -t '$(prefix)/usr/share/licenses/wikiman' 'LICENSE'
	@install -Dm 644 -t '$(prefix)/usr/share/doc/wikiman' 'README.md'
	@install -Dm 644 -t '$(prefix)/etc' 'wikiman.conf'

clean:

	@rm -f './arch-linux-docs_20200527-1.tar.xz'
	@rm -f './gentoo-wiki_20200831-1.tar.xz'
	@rm -f './freebsd-docs_20200901-1.tar.xz'

uninstall:

	@rm -f '$(prefix)/usr/bin/wikiman'

	@rm -rf '$(prefix)/usr/share/wikiman'

	@rm -f '$(prefix)/usr/share/man/man1/wikiman.1.gz'
	@rm -rf '$(prefix)/usr/share/licenses/wikiman'
	@rm -rf '$(prefix)/usr/share/doc/wikiman'
	@rm -i '$(prefix)/etc/wikiman.conf'

	@rm -rfi '$(prefix)/usr/share/doc/arch-wiki'
	@rm -rfi '$(prefix)/usr/share/doc/gentoo-wiki'
	@rm -rfi '$(prefix)/usr/share/doc/freebsd-docs'
