NAME=		wikiman
VERSION=	2.13.2
RELEASE=	1
UPSTREAM=	https://github.com/filiparag/wikiman
UPSTREAM_API=	https://api.github.com/repos/filiparag/wikiman/releases/latest

MKFILEREL!=	echo ${.MAKE.MAKEFILES} | sed 's/.* //'
MKFILEABS!=	readlink -f ${MKFILEREL} 2>/dev/null
MKFILEABS+= 	$(shell readlink -f ${MAKEFILE_LIST})
WORKDIR!=	dirname ${MKFILEABS} 2>/dev/null

BUILDDIR:=	${WORKDIR}/pkgbuild
SOURCESDIR:=	${WORKDIR}/srcbuild
PLISTFILE:=	${WORKDIR}/pkg-plist

.PHONY: all core widgets completions config docs reinstall install plist dist \
	package distclean clean deinstall uninstall local source-all source-reinstall \
	source-install source-clean source-deinstall source-uninstall source-local \
	source-arch source-gentoo source-fbsd source-tldr

all: core widgets completions config docs

core:
	mkdir -p		${BUILDDIR}/usr/bin \
	 			${BUILDDIR}/usr/share/${NAME} \
				${BUILDDIR}/usr/share/licenses/${NAME} \
				${BUILDDIR}/usr/share/man/man1
	install 	-Dm755 	${WORKDIR}/${NAME}.sh \
				${BUILDDIR}/usr/bin/${NAME}
	cp 		-fr 	${WORKDIR}/sources \
				${BUILDDIR}/usr/share/${NAME}
	install 	-Dm644 	${WORKDIR}/LICENSE \
				${BUILDDIR}/usr/share/licenses/${NAME}
	gzip 		-k	${WORKDIR}/${NAME}.1.man
	mv 			${WORKDIR}/${NAME}.1.man.gz \
				${BUILDDIR}/usr/share/man/man1/${NAME}.1.gz

widgets: core
	mkdir		-p 	${BUILDDIR}/usr/share/${NAME}
	cp 		-fr 	${WORKDIR}/widgets \
				${BUILDDIR}/usr/share/${NAME}

completions: core
	mkdir		-p 	${BUILDDIR}/etc/bash_completion.d \
				${BUILDDIR}/usr/share/fish/completions \
				${BUILDDIR}/usr/share/zsh/site-functions
	install 	-Dm644 	${WORKDIR}/completions/completions.bash	\
				${BUILDDIR}/etc/bash_completion.d/${NAME}-completion.bash
	install 	-Dm644 	${WORKDIR}/completions/completions.fish \
				${BUILDDIR}/usr/share/fish/completions/${NAME}.fish
	install 	-Dm644 	${WORKDIR}/completions/completions.zsh \
				${BUILDDIR}/usr/share/zsh/site-functions/_${NAME}

config:
	mkdir -p 		${BUILDDIR}/etc
	install 	-Dm644 	${WORKDIR}/${NAME}.conf \
				${BUILDDIR}/etc

docs:
	mkdir		-p 	${BUILDDIR}/usr/share/doc/${NAME}
	install 	-Dm644 	${WORKDIR}/README.md \
				${BUILDDIR}/usr/share/doc/${NAME}

reinstall: install
install: all
	mkdir		-p 	$(prefix)/
	cp		-fr 	${BUILDDIR}/* \
				$(prefix)/

plist: all
	find 			${BUILDDIR} -type f > ${PLISTFILE}
	sed		-i 	's|${BUILDDIR}/||' ${PLISTFILE}

dist: package
package: all
	tar		czf	${WORKDIR}/${NAME}-${VERSION}-${RELEASE}.tar.gz \
				${BUILDDIR}

distclean: clean
clean:
	rm		-f	${PLISTFILE} \
				${WORKDIR}/${NAME}-${VERSION}-${RELEASE}.tar.gz
	rm		-rf	${BUILDDIR}

deinstall: uninstall
uninstall:
	rm		-f	$(prefix)/etc/${NAME}.conf \
				$(prefix)/usr/bin/${NAME} \
				$(prefix)/usr/share/man/man1/${NAME}.1.gz \
				$(prefix)/etc/bash_completion.d/${NAME}-completion.bash \
				$(prefix)/usr/share/fish/completions/${NAME}.fish \
				$(prefix)/usr/share/zsh/site-functions/_${NAME}
	rm		-rf	$(prefix)/usr/share/${NAME} \
				$(prefix)/usr/share/licenses/${NAME} \
				$(prefix)/usr/share/doc/${NAME}

	rm		-f	$(prefix)/usr/local/etc/${NAME}.conf \
				$(prefix)/usr/local/bin/${NAME} \
				$(prefix)/usr/local/share/man/man1/${NAME}.1.gz \
				$(prefix)/etc/bash_completion.d/${NAME}-completion.bash \
				$(prefix)/usr/share/fish/completions/${NAME}.fish \
				$(prefix)/usr/share/zsh/site-functions/_${NAME}
	rm		-rf 	$(prefix)/usr/local/share/${NAME} \
				$(prefix)/usr/local/share/licenses/${NAME} \
				$(prefix)/usr/local/share/doc/${NAME}

local:
	test		! -d	${BUILDDIR}/usr/local
	mkdir		-p	${BUILDDIR}/tmp \
				${BUILDDIR}/usr \
				${BUILDDIR}/etc
	mv			${BUILDDIR}/usr ${BUILDDIR}/etc \
				${BUILDDIR}/tmp
	mkdir		-p	${BUILDDIR}/usr/local/usr \
				${BUILDDIR}/usr/local/etc
	mv			${BUILDDIR}/tmp/* \
				${BUILDDIR}/usr/local
	rm		-rf	${BUILDDIR}/tmp \
				${BUILDDIR}/etc

source-all: source-arch source-gentoo source-fbsd source-tldr

source-reinstall: source-install
source-install:
	[ -d ${SOURCESDIR}/usr/share/doc ] && \
		mkdir	-p	$(prefix)/usr/share/doc && \
		cp	-rf	${SOURCESDIR}/usr/share/doc \
				$(prefix)/usr/share || true

	[ -d ${SOURCESDIR}/usr/local/share/doc ] && \
		mkdir	-p	$(prefix)/usr/local/share/doc && \
		cp	-rf 	${SOURCESDIR}/usr/local/share/doc \
				$(prefix)/usr/local/share || true

source-clean:
	rm		-rf 	${SOURCESDIR}

source-deinstall: source-uninstall
source-uninstall:
	rm		-rf	$(prefix)/usr/share/doc/arch-wiki/html \
				$(prefix)/usr/share/doc/gentoo-wiki \
				$(prefix)/usr/share/doc/freebsd-docs \
				$(prefix)/usr/share/doc/tldr-pages
	rm		-rf	$(prefix)/usr/local/share/doc/arch-wiki/html \
				$(prefix)/usr/local/share/doc/gentoo-wiki \
				$(prefix)/usr/local/share/doc/freebsd-docs \
				$(prefix)/usr/local/share/doc/tldr-pages

source-local:
	test		! -d	${SOURCESDIR}/usr/local/share/doc
	mkdir		-p	${SOURCESDIR}/usr/local/share \
				${SOURCESDIR}/usr/share/doc
	mv			${SOURCESDIR}/usr/share/doc \
				${SOURCESDIR}/usr/local/share/doc
	rm		-rf	${SOURCESDIR}/usr/share

source-arch: ${SOURCESDIR}/dl/arch-wiki.tar.xz
source-gentoo: ${SOURCESDIR}/dl/gentoo-wiki.tar.xz
source-fbsd: ${SOURCESDIR}/dl/freebsd-docs.tar.xz
source-tldr: ${SOURCESDIR}/dl/tldr-pages.tar.xz

${SOURCESDIR}/:
	mkdir		-p 	${SOURCESDIR}/usr/share/doc \
				${SOURCESDIR}/dl

${SOURCESDIR}/sources.txt: | ${SOURCESDIR}/
	curl -s '${UPSTREAM_API}' | awk \
	'/"name":/ { \
		name = $$2; \
		sub(/^[ \t]*"name": "[^"]*/, "", name); \
		gsub(/[" ,]/, "", name); \
	} \
	/"browser_download_url":/ { \
		url = $$2; \
		gsub(/[" ,]/, "", url); \
		if (name ~ /_[0-9]+\.source\.tar\.xz$$/) { \
			print name "\t" url; \
		} \
	}' | sort > ${SOURCESDIR}/sources.txt

${SOURCESDIR}/dl/arch-wiki.tar.xz: ${SOURCESDIR}/sources.txt
	curl -L '$(shell grep '^arch-wiki_' ${SOURCESDIR}/sources.txt | tail -n1 | cut -f2)' \
		-o ${SOURCESDIR}/dl/arch-wiki.tar.xz
	tar xf 	${SOURCESDIR}/dl/arch-wiki.tar.xz -C ${SOURCESDIR}

${SOURCESDIR}/dl/gentoo-wiki.tar.xz: ${SOURCESDIR}/sources.txt
	@>&2 echo 'Note: Gentoo Wiki source is outdated'
	curl -L '${UPSTREAM}/releases/download/2.7/gentoo-wiki_20200831-1.tar.xz' \
		-o ${SOURCESDIR}/dl/gentoo-wiki.tar.xz
	tar xf 	${SOURCESDIR}/dl/gentoo-wiki.tar.xz -C ${SOURCESDIR}

${SOURCESDIR}/dl/freebsd-docs.tar.xz: ${SOURCESDIR}/sources.txt
	curl -L '$(shell grep '^freebsd-docs_' ${SOURCESDIR}/sources.txt | tail -n1 | cut -f2)' \
		-o ${SOURCESDIR}/dl/freebsd-docs.tar.xz
	tar xf ${SOURCESDIR}/dl/freebsd-docs.tar.xz -C ${SOURCESDIR}

${SOURCESDIR}/dl/tldr-pages.tar.xz: ${SOURCESDIR}/sources.txt
	curl -L '$(shell grep '^tldr-pages_' ${SOURCESDIR}/sources.txt | tail -n1 | cut -f2)' \
		-o ${SOURCESDIR}/dl/tldr-pages.tar.xz
	tar xf	${SOURCESDIR}/dl/tldr-pages.tar.xz -C ${SOURCESDIR}
