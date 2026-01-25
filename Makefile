NAME=			wikiman
VERSION=		2.14.1
RELEASE=		1
UPSTREAM=		https://github.com/filiparag/wikiman
UPSTREAM_API=	https://api.github.com/repos/filiparag/wikiman/releases/latest

prefix=			/usr/local

BUILDDIR=		./pkgbuild
SOURCESDIR=		./srcbuild
PLISTFILE=		./pkg-plist
PLATFORM=		`uname -s`
TARGET_SUFFIX=	`case "$(PLATFORM)" in \
					"Linux"|"linux") \
						echo linux ;; \
					"XDG"|"xdg") \
						echo xdg ;; \
					*) \
						echo default ;; \
				esac`
FS_ROOT=		/

.PHONY: all core widgets completions config docs core-default core-linux core-xdg \
		widgets-default widgets-linux widgets-xdg completions-default completions-linux completions-xdg \
		config-default config-linux config-xdg docs-default docs-linux docs-xdg \
		plist reinstall install deinstall uninstall

all: core widgets completions config docs

core:
	"$(MAKE)" "core-$(TARGET_SUFFIX)"

widgets:
	"$(MAKE)" "widgets-$(TARGET_SUFFIX)"

completions:
	"$(MAKE)" "completions-$(TARGET_SUFFIX)"

config:
	"$(MAKE)" "config-$(TARGET_SUFFIX)"

docs:
	"$(MAKE)" "docs-$(TARGET_SUFFIX)"

core-default:
	install -d -m 755 "$(BUILDDIR)/$(prefix)/bin"
	install -d -m 755 "$(BUILDDIR)/$(prefix)/share/licenses/$(NAME)"
	install -d -m 755 "$(BUILDDIR)/$(prefix)/share/man/man1"
	install -d -m 755 "$(BUILDDIR)/$(prefix)/share/$(NAME)/sources"

	install -m 755 "$(NAME).sh" "$(BUILDDIR)/$(prefix)/bin/$(NAME)"
	install -m 644 "LICENSE" "$(BUILDDIR)/$(prefix)/share/licenses/$(NAME)"
	gzip -c "$(NAME).1.man" > "$(BUILDDIR)/$(prefix)/share/man/man1/$(NAME).1.gz"

	for source in arch devdocs fbsd gentoo man tldr; do \
		install -m 755 "sources/$$source.sh" \
						"$(BUILDDIR)/$(prefix)/share/$(NAME)/sources/$$source.sh"; \
	done

core-linux:
	"$(MAKE)" prefix=/usr core-default

core-xdg:
	install -d -m 755 "$(BUILDDIR)/$(HOME)/.local/bin"
	install -d -m 755 "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/licenses/$(NAME)"
	install -d -m 755 "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/man/man1"
	install -d -m 755 "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/$(NAME)/sources"

	install -m 755 "$(NAME).sh" "$(BUILDDIR)/$(HOME)/.local/bin/$(NAME)"
	install -m 644 "LICENSE" "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/licenses/$(NAME)"
	gzip -c "$(NAME).1.man" > "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/man/man1/$(NAME).1.gz"

	for source in arch devdocs fbsd gentoo man tldr; do \
		install -m 755 "sources/$$source.sh" \
						"$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/$(NAME)/sources/$$source.sh"; \
	done

widgets-default:
	install -d -m 755 "$(BUILDDIR)/$(prefix)/share/$(NAME)/widgets"

	for ext in bash fish zsh; do \
		install -m 755 "widgets/widget.$$ext" \
						"$(BUILDDIR)/$(prefix)/share/$(NAME)/widgets/widget.$$ext"; \
	done

widgets-linux:
	"$(MAKE)" prefix=/usr widgets-default

widgets-xdg:
	install -d -m 755 "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/$(NAME)/widgets"

	for ext in bash fish zsh; do \
		install -m 755 "widgets/widget.$$ext" \
						"$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/$(NAME)/widgets/widget.$$ext"; \
	done

completions-default:
	install -d -m 755 "$(BUILDDIR)/$(prefix)/etc/bash_completion.d"
	install -d -m 755 "$(BUILDDIR)/$(prefix)/share/fish/vendor_completions.d"
	install -d -m 755 "$(BUILDDIR)/$(prefix)/share/zsh/vendor-completions"

	install -m 755 "completions/completions.bash" "$(BUILDDIR)/$(prefix)/etc/bash_completion.d/$(NAME)-completion.bash"
	install -m 755 "completions/completions.fish" "$(BUILDDIR)/$(prefix)/share/fish/vendor_completions.d/$(NAME).fish"
	install -m 755 "completions/completions.zsh" "$(BUILDDIR)/$(prefix)/share/zsh/vendor-completions/_$(NAME)"

completions-linux:
	"$(MAKE)" prefix=/usr completions-default

completions-xdg:
	install -d -m 755 "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/bash_completion"
	install -d -m 755 "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/fish/vendor_completions.d"
	install -d -m 755 "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/zsh/vendor-completions"

	install -m 755 "completions/completions.bash" "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/bash_completion/$(NAME)-completion.bash"
	install -m 755 "completions/completions.fish" "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/fish/vendor_completions.d/$(NAME).fish"
	install -m 755 "completions/completions.zsh" "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/zsh/vendor-completions/_$(NAME)"

config-default:
	install -d -m 755 "$(BUILDDIR)/$(prefix)/etc"

	install -m 644 "$(NAME).conf" "$(BUILDDIR)/$(prefix)/etc/$(NAME).conf"

config-linux:
	"$(MAKE)" prefix=/ config-default

config-xdg:
	install -d -m 755 "$(BUILDDIR)/$${XDG_CONFIG_HOME:-$$HOME/.config}"

	install -m 644 "$(NAME).conf" "$(BUILDDIR)/$${XDG_CONFIG_HOME:-$$HOME/.config}/$(NAME).conf"

docs-default:
	install -d -m 755 "$(BUILDDIR)/$(prefix)/share/doc/$(NAME)"

	install -m 644 "README.md" "$(BUILDDIR)/$(prefix)/share/doc/$(NAME)/README.md"

docs-linux:
	"$(MAKE)" prefix=/usr docs-default

docs-xdg:
	install -d -m 755 "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/doc/$(NAME)"

	install -m 644 "README.md" "$(BUILDDIR)/$${XDG_DATA_HOME:-$$HOME/.local/share}/doc/$(NAME)/README.md"

plist: all
	curdir=`pwd`; \
	cd "$(BUILDDIR)" && \
	find . -mindepth 1 -type f | sed 's|^\./||' | sort > "$$curdir/$(PLISTFILE)"

reinstall: install
install: all
	cd "$(BUILDDIR)" && find . -mindepth 1 -type d -exec sh -c 'install -d -m 755 "$(DESTDIR)$${1#.}"' _ {} \;

	cd "$(BUILDDIR)" && find . -mindepth 1 -type f -perm -100 -exec sh -c 'install -m 755 "$$1" "$(DESTDIR)$${1#.}"' _ {} \;

	cd "$(BUILDDIR)" && find . -mindepth 1 -type f ! -perm -100 -exec sh -c 'install -m 644 "$$1" "$(DESTDIR)$${1#.}"' _ {} \;

deinstall: uninstall
uninstall:
	@while read -r file; do \
		echo "Removing $(DESTDIR)/$$file"; \
		rm -f "$(DESTDIR)/$$file"; \
	done < "$(PLISTFILE)"
