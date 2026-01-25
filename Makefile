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
				esac`
FS_ROOT=		/

.PHONY: core widgets completions config docs \
		all clean plist reinstall install deinstall uninstall
		config-default config-linux config-xdg docs-default docs-linux docs-xdg \
		plist reinstall install deinstall uninstall

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

