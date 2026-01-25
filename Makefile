NAME=			wikiman
VERSION=		2.14.1
RELEASE=		1
UPSTREAM=		https://github.com/filiparag/wikiman
UPSTREAM_API=	https://api.github.com/repos/filiparag/wikiman/releases/latest

prefix=
target=

BUILDDIR=		./pkgbuild
SOURCESDIR=		./srcbuild
PLISTFILE=		./pkg-plist
FS_ROOT=		/

BIN_I_PATH=		`case "$${target:-$$(uname -s)}" in \
					Linux|linux|GNU|gnu) \
						echo "$(prefix)/usr/bin" ;; \
					XDG|xdg|user) \
						echo "$(prefix)/$(HOME)/.local/bin" ;; \
					*) \
						echo "$(prefix)/usr/local/bin" ;; \
				esac`
LICENSE_I_PATH=	`case "$${target:-$$(uname -s)}" in \
					Linux|linux|GNU|gnu) \
						echo "$(prefix)/usr/share/licenses" ;; \
					XDG|xdg|user) \
						echo "$(prefix)/$${XDG_DATA_HOME:-$(HOME)/.local/share}/licenses" ;; \
					*) \
						echo "$(prefix)/usr/local/share/licenses" ;; \
				esac`
MAN_I_PATH=		`case "$${target:-$$(uname -s)}" in \
					Linux|linux|GNU|gnu) \
						echo "$(prefix)/usr/share/man" ;; \
					XDG|xdg|user) \
						echo "$(prefix)/$${XDG_DATA_HOME:-$(HOME)/.local/share}/man" ;; \
					*) \
						echo "$(prefix)/usr/local/share/man" ;; \
				esac`
SHARE_I_PATH=		`case "$${target:-$$(uname -s)}" in \
					Linux|linux|GNU|gnu) \
						echo "$(prefix)/usr/share" ;; \
					XDG|xdg|user) \
						echo "$(prefix)/$${XDG_DATA_HOME:-$(HOME)/.local/share}" ;; \
					*) \
						echo "$(prefix)/usr/local/share" ;; \
				esac`
CONF_I_PATH=	`case "$${target:-$$(uname -s)}" in \
					Linux|linux|GNU|gnu) \
						echo "$(prefix)/etc" ;; \
					XDG|xdg|user) \
						echo "$(prefix)/$${XDG_CONFIG_HOME:-$(HOME)/.config}" ;; \
					*) \
						echo "$(prefix)/usr/local/etc" ;; \
				esac`
DOC_I_PATH=		`case "$${target:-$$(uname -s)}" in \
					Linux|linux|GNU|gnu) \
						echo "$(prefix)/usr/share/doc" ;; \
					XDG|xdg|user) \
						echo "$(prefix)/$${XDG_DATA_HOME:-$(HOME)/.local/share}/doc" ;; \
					*) \
						echo "$(prefix)/usr/local/share/doc" ;; \
				esac`
BASH_C_I_PATH=	`case "$${target:-$$(uname -s)}" in \
					Linux|linux|GNU|gnu) \
						echo "$(prefix)/etc/bash_completion.d" ;; \
					XDG|xdg|user) \
						echo "$(prefix)/$${XDG_DATA_HOME:-$(HOME)/.local/share}/bash_completion" ;; \
					*) \
						echo "$(prefix)/usr/local/etc/bash_completion.d" ;; \
				esac`
FISH_C_I_PATH=	`case "$${target:-$$(uname -s)}" in \
					Linux|linux|GNU|gnu) \
						echo "$(prefix)/usr/share/fish/vendor_completions.d" ;; \
					XDG|xdg|user) \
						echo "$(prefix)/$${XDG_DATA_HOME:-$(HOME)/.local/share}/fish/vendor_completions.d" ;; \
					*) \
						echo "$(prefix)/usr/local/share/fish/vendor_completions.d" ;; \
				esac`
ZSH_C_I_PATH=	`case "$${target:-$$(uname -s)}" in \
					Linux|linux|GNU|gnu) \
						echo "$(prefix)/usr/share/zsh/vendor-completions" ;; \
					XDG|xdg|user) \
						echo "$(prefix)/$${XDG_DATA_HOME:-$(HOME)/.local/share}/zsh/vendor-completions" ;; \
					*) \
						echo "$(prefix)/usr/local/share/zsh/vendor-completions" ;; \
				esac`
SOURCES_I_PATH=	`case "$${target:-$$(uname -s)}" in \
					Linux|linux|GNU|gnu) \
						echo "$(prefix)/usr/share/doc" ;; \
					XDG|xdg|user) \
						echo "$(prefix)/$${XDG_DATA_HOME:-$(HOME)/.local/share}/doc" ;; \
					*) \
						echo "$(prefix)/usr/local/share/doc" ;; \
				esac`


.PHONY: core widgets completions config docs \
		all clean plist reinstall install deinstall uninstall \
		source-arch source-devdocs source-fbsd source-gentoo source-tldr \
		source-all source-clean source-install source-reinstall source-uninstall source-deinstall

all: core widgets completions config docs

core:
	install -d -m 755 "$(BUILDDIR)/$(BIN_I_PATH)"
	install -d -m 755 "$(BUILDDIR)/$(LICENSE_I_PATH)/$(NAME)"
	install -d -m 755 "$(BUILDDIR)/$(MAN_I_PATH)/man1"
	install -d -m 755 "$(BUILDDIR)/$(SHARE_I_PATH)/$(NAME)/sources"

	install -m 755 "$(NAME).sh" "$(BUILDDIR)/$(BIN_I_PATH)/$(NAME)"
	install -m 644 "LICENSE" "$(BUILDDIR)/$(LICENSE_I_PATH)/$(NAME)/LICENSE"
	gzip -c "$(NAME).1.man" > "$(BUILDDIR)/$(MAN_I_PATH)/man1/$(NAME).1.gz"

	for source in arch devdocs fbsd gentoo man tldr; do \
		install -m 755 "sources/$$source.sh" \
						"$(BUILDDIR)/$(SHARE_I_PATH)/$(NAME)/sources/$$source.sh"; \
	done

widgets:
	install -d -m 755 "$(BUILDDIR)/$(SHARE_I_PATH)/$(NAME)/widgets"

	for ext in bash fish zsh; do \
		install -m 755 "widgets/widget.$$ext" \
						"$(BUILDDIR)/$(SHARE_I_PATH)/$(NAME)/widgets/widget.$$ext"; \
	done

completions:
	install -d -m 755 "$(BUILDDIR)/$(BASH_C_I_PATH)"
	install -d -m 755 "$(BUILDDIR)/$(FISH_C_I_PATH)"
	install -d -m 755 "$(BUILDDIR)/$(ZSH_C_I_PATH)"

	install -m 755 "completions/completions.bash" "$(BUILDDIR)/$(BASH_C_I_PATH)/$(NAME)-completion.bash"
	install -m 755 "completions/completions.fish" "$(BUILDDIR)/$(FISH_C_I_PATH)/$(NAME).fish"
	install -m 755 "completions/completions.zsh" "$(BUILDDIR)/$(ZSH_C_I_PATH)/_$(NAME)"

config:
	install -d -m 755 "$(BUILDDIR)/$(CONF_I_PATH)"

	install -m 644 "$(NAME).conf" "$(BUILDDIR)/$(CONF_I_PATH)/$(NAME).conf"

docs:
	install -d -m 755 "$(BUILDDIR)/$(DOC_I_PATH)/$(NAME)"

	install -m 644 "README.md" "$(BUILDDIR)/$(DOC_I_PATH)/$(NAME)/README.md"

plist: all
	curdir=`pwd`; \
	cd "$(BUILDDIR)" && \
	find . -mindepth 1 -type f | sed 's|^\./||' | sort > "$$curdir/$(PLISTFILE)"

clean:
	rm -rf "$(BUILDDIR)"

reinstall: install
install: all
	cd "$(BUILDDIR)" && find . -mindepth 1 -type d -exec sh -c 'install -d -m 755 "$(FS_ROOT)$${1#.}"' _ {} \;

	cd "$(BUILDDIR)" && find . -mindepth 1 -type f -perm -100 -exec sh -c 'install -m 755 "$$1" "$(FS_ROOT)$${1#.}"' _ {} \;

	cd "$(BUILDDIR)" && find . -mindepth 1 -type f ! -perm -100 -exec sh -c 'install -m 644 "$$1" "$(FS_ROOT)$${1#.}"' _ {} \;

deinstall: uninstall
uninstall:
	rm -rf "$(FS_ROOT)/$(LICENSE_I_PATH)/$(NAME)"
	rm -rf "$(FS_ROOT)/$(SHARE_I_PATH)/$(NAME)"
	rm -f "$(FS_ROOT)/$(BIN_I_PATH)/$(NAME)"
	rm -f "$(FS_ROOT)/$(MAN_I_PATH)/man1/$(NAME).1.gz"
	rm -f "$(FS_ROOT)/$(BASH_C_I_PATH)/$(NAME)-completion.bash"
	rm -f "$(FS_ROOT)/$(FISH_C_I_PATH)/$(NAME).fish"
	rm -f "$(FS_ROOT)/$(ZSH_C_I_PATH)/_$(NAME)"
	rm -rf "$(FS_ROOT)/$(DOC_I_PATH)/$(NAME)"

$(SOURCESDIR)/.dl/sources.awk:
	install -d -m 755 "$(SOURCESDIR)/.dl"
	@printf '%s\n' '/"name":/ {' \
	'    name = $$2' \
	'    sub(/^[ \t]*"name": "[^"]*/, "", name)' \
	'    gsub(/[" ,]/, "", name)' \
	'}' \
	'/"browser_download_url":/ {' \
	'    url = $$2' \
	'    gsub(/[" ,]/, "", url)' \
	'    if (name ~ /_[0-9]+\.[sS]ource\.tar\.xz$$/) {' \
	'        print name "\t" url' \
	'    }' \
	'}' > $@

$(SOURCESDIR)/.dl/sources.txt: $(SOURCESDIR)/.dl/sources.awk
	curl -s '$(UPSTREAM_API)' | awk -f "$(SOURCESDIR)/.dl/sources.awk" | sort > "$(SOURCESDIR)/.dl/sources.txt"

$(SOURCESDIR)/.dl/%.txt: $(SOURCESDIR)/.dl/sources.txt
	grep '^$*_' "$(SOURCESDIR)/.dl/sources.txt" | tail -n1 | cut -f2 > "$@"

$(SOURCESDIR)/.dl/%.tar.xz: $(SOURCESDIR)/.dl/%.txt
	xargs curl -L < "$<" -o "$@"
	tar xf "$@" -C "$(SOURCESDIR)"

source-all: source-arch source-devdocs source-fbsd source-gentoo source-tldr

source-arch: $(SOURCESDIR)/.dl/arch-wiki.tar.xz
	install -d -m 755 "$(SOURCESDIR)/$(SOURCES_I_PATH)"

	tar xf "$(SOURCESDIR)/.dl/arch-wiki.tar.xz" -C "$(SOURCESDIR)/$(SOURCES_I_PATH)"

source-devdocs: $(SOURCESDIR)/.dl/devdocs.tar.xz
	install -d -m 755 "$(SOURCESDIR)/$(SOURCES_I_PATH)"

	tar xf "$(SOURCESDIR)/.dl/devdocs.tar.xz" -C "$(SOURCESDIR)/$(SOURCES_I_PATH)"

source-fbsd: $(SOURCESDIR)/.dl/freebsd-docs.tar.xz
	install -d -m 755 "$(SOURCESDIR)/$(SOURCES_I_PATH)"

	tar xf "$(SOURCESDIR)/.dl/freebsd-docs.tar.xz" -C "$(SOURCESDIR)/$(SOURCES_I_PATH)"

source-gentoo: $(SOURCESDIR)/.dl/gentoo-wiki.tar.xz
	install -d -m 755 "$(SOURCESDIR)/$(SOURCES_I_PATH)"

	tar xf "$(SOURCESDIR)/.dl/gentoo-wiki.tar.xz" -C "$(SOURCESDIR)/$(SOURCES_I_PATH)"

source-tldr: $(SOURCESDIR)/.dl/tldr-pages.tar.xz
	install -d -m 755 "$(SOURCESDIR)/$(SOURCES_I_PATH)"

	tar xf "$(SOURCESDIR)/.dl/tldr-pages.tar.xz" -C "$(SOURCESDIR)/$(SOURCES_I_PATH)"

source-clean:
	rm -rf "$(SOURCESDIR)"

source-reinstall: source-install
source-install:
	install -d -m 755 "$(FS_ROOT)/$(SOURCES_I_PATH)"

	cp -fR "$(SOURCESDIR)/"* "$(FS_ROOT)"

source-deinstall: source-uninstall
source-uninstall:
	rm -rf "$(FS_ROOT)/$(SOURCES_I_PATH)/arch-wiki"
	rm -rf "$(FS_ROOT)/$(SOURCES_I_PATH)/devdocs"
	rm -rf "$(FS_ROOT)/$(SOURCES_I_PATH)/freebsd-docs"
	rm -rf "$(FS_ROOT)/$(SOURCES_I_PATH)/gentoo-wiki"
	rm -rf "$(FS_ROOT)/$(SOURCES_I_PATH)/tldr-pages"
