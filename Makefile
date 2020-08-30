DEPS = man fzf rg awk w3m
UPSTREAM = 'https://github.com/filiparag/wikiman'

make:

	@echo 'Checking dependencies...'
	@which ${DEPS} >/dev/null || { echo 'Error: Missing dependency!'; exit 1; }

	@echo 'Checking documentation sources...'
	@test -d '/usr/share/man' -a -r '/usr/share/man' >/dev/null || \
		echo 'Warning: Man pages are not available!'
	@test -d '/usr/share/doc/arcsh-wiki/html' -a -r '/usr/share/doc/arch-wiki/html' >/dev/null || \
		echo 'Warning: Arch Wiki is not available! Run make archwiki to install.'

archwiki:
	
	@echo 'Downoading latest snapshot...'
	@curl -L -O '${UPSTREAM}/releases/download/2.4/arch-linux-docs_20200527-1.tar.xz'
	@echo 'Installing Arch Wiki...'
	@tar zxf './arch-linux-docs_20200527-1.tar.xz' -C /
	@rm './arch-linux-docs_20200527-1.tar.xz'

install:

	@install -Dm 755 'wikiman.sh' '/usr/bin/wikiman'

	@install -Dm 644 'wikiman.1.man' '/usr/share/man/man1/wikiman.1'
	@install -Dm 644 -t '/usr/share/licenses/wikiman' 'LICENSE'
	@install -Dm 644 -t '/usr/share/doc/wikiman' 'README.md'
	@install -Dm 644 -t '/etc' 'wikiman.conf'

clean:

	@rm './arch-linux-docs_20200527-1.tar.xz'

uninstall:

	@rm -f '/usr/bin/wikiman'

	@rm -f '/usr/share/man/man1/wikiman.1'
	@rm -f '/usr/share/licenses/wikiman'
	@rm -f '/usr/share/doc/wikiman'
	@rm -i '/etc/wikiman.conf'