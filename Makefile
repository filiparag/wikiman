NAME=		wikiman
VERSION=	2.14.1
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
	source-arch source-devdocs source-fbsd source-gentoo source-tldr

all: core widgets completions config docs

core:
	test		! -f	${BUILDDIR}/.local
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
	test		! -f	${BUILDDIR}/.local
	mkdir		-p 	${BUILDDIR}/usr/share/${NAME}
	cp 		-fr 	${WORKDIR}/widgets \
				${BUILDDIR}/usr/share/${NAME}

completions: core
	test		! -f	${BUILDDIR}/.local
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
	test		! -f	${BUILDDIR}/.local
	mkdir -p 		${BUILDDIR}/etc
	install 	-Dm644 	${WORKDIR}/${NAME}.conf \
				${BUILDDIR}/etc

docs:
	test		! -f	${BUILDDIR}/.local
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
	test		! -d	${BUILDDIR}/usr/local/share/${NAME}
	test		! -f	${BUILDDIR}/.local
	touch			${BUILDDIR}/.local
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

source-all: source-arch source-devdocs source-fbsd source-gentoo source-tldr

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
				$(prefix)/usr/share/doc/devdocs \
				$(prefix)/usr/share/doc/freebsd-docs \
				$(prefix)/usr/share/doc/gentoo-wiki \
				$(prefix)/usr/share/doc/tldr-pages
	rm		-rf	$(prefix)/usr/local/share/doc/arch-wiki/html \
				$(prefix)/usr/local/share/doc/devdocs \
				$(prefix)/usr/local/share/doc/freebsd-docs \
				$(prefix)/usr/local/share/doc/gentoo-wiki \
				$(prefix)/usr/local/share/doc/tldr-pages

source-local:
	test		! -d	${SOURCESDIR}/usr/local/share/doc
	test		! -f	${SOURCESDIR}/.local
	touch			${SOURCESDIR}/.local
	mkdir		-p	${SOURCESDIR}/usr/local/share \
				${SOURCESDIR}/usr/share/doc
	mv			${SOURCESDIR}/usr/share/doc \
				${SOURCESDIR}/usr/local/share/doc
	rm		-rf	${SOURCESDIR}/usr/share
	test		-d	${SOURCESDIR}/usr/local/share/doc/gentoo-wiki && \
	find			${SOURCESDIR}/usr/local/share/doc/gentoo-wiki/wiki \
				-name '*.html' \
				-exec sed -i 's/href="\/usr\/share\/doc\/gentoo-wiki\/wiki\/\([^"]*\)"/href="\/usr\/local\/share\/doc\/gentoo-wiki\/wiki\/\1.html"/g; ' {} \; || \
	true

source-arch: ${SOURCESDIR}/dl/arch-wiki.tar.xz
source-devdocs: ${SOURCESDIR}/dl/devdocs.tar.xz
source-fbsd: ${SOURCESDIR}/dl/freebsd-docs.tar.xz
source-gentoo: ${SOURCESDIR}/dl/gentoo-wiki.tar.xz
source-tldr: ${SOURCESDIR}/dl/tldr-pages.tar.xz

${SOURCESDIR}/:
	test		! -f	${SOURCESDIR}/.local
	mkdir		-p 	${SOURCESDIR}/usr/share/doc \
				${SOURCESDIR}/dl

${SOURCESDIR}/dl/sources.awk: ${SOURCESDIR}/
	test -f ${SOURCESDIR}/dl/sources.awk || \
	echo '/Td6WFoAAATm1rRGBMCsAfwBIQEWAAAAAAAAANJru4jgAPsApF0AF4iKRqIWnygmbeoKf/N6TNj2uMRXuJKAP8hO22uy2e8OIzyFihWG/hyEgGi3XQbla/dFWkXc6q4MF/M2CS9vMVFkDP9IUCKI00LzJPixq8UnJ/xpGxTfUwpv6kLAnfJ/FyeE4WK5HiNZVHs/8AWCy+ixAy8A2fg6JwItYxLEKtU1sdVPlo0fxBXo3TRiqLdcZAu5WQD5GbDk8wQB10zENpvrqh8AEZf9obj6SqIAAcgB/AEAAJyi/M6xxGf7AgAAAAAEWVo=' | \
	base64 -d | xz -d > ${SOURCESDIR}/dl/sources.awk

${SOURCESDIR}/dl/sources.txt: ${SOURCESDIR}/dl/sources.awk
	curl -s '${UPSTREAM_API}' | awk -f ${SOURCESDIR}/dl/sources.awk | sort > ${SOURCESDIR}/dl/sources.txt

${SOURCESDIR}/dl/arch-wiki.txt: ${SOURCESDIR}/dl/sources.txt
	grep '^arch-wiki_' ${SOURCESDIR}/dl/sources.txt | tail -n1 | cut -f2 > ${SOURCESDIR}/dl/arch-wiki.txt

${SOURCESDIR}/dl/devdocs.txt: ${SOURCESDIR}/dl/sources.txt
	grep '^devdocs_' ${SOURCESDIR}/dl/sources.txt | tail -n1 | cut -f2 > ${SOURCESDIR}/dl/devdocs.txt


${SOURCESDIR}/dl/freebsd-docs.txt: ${SOURCESDIR}/dl/sources.txt
	grep '^freebsd-docs_' ${SOURCESDIR}/dl/sources.txt | tail -n1 | cut -f2 > ${SOURCESDIR}/dl/freebsd-docs.txt

${SOURCESDIR}/dl/gentoo-wiki.txt: ${SOURCESDIR}/dl/sources.txt
	grep '^gentoo-wiki_' ${SOURCESDIR}/dl/sources.txt | tail -n1 | cut -f2 > ${SOURCESDIR}/dl/gentoo-wiki.txt

${SOURCESDIR}/dl/tldr-pages.txt: ${SOURCESDIR}/dl/sources.txt
	grep '^tldr-pages_' ${SOURCESDIR}/dl/sources.txt | tail -n1 | cut -f2 > ${SOURCESDIR}/dl/tldr-pages.txt

${SOURCESDIR}/dl/arch-wiki.tar.xz: ${SOURCESDIR}/dl/arch-wiki.txt
	test ! -f ${SOURCESDIR}/.local
	xargs curl -L < ${SOURCESDIR}/dl/arch-wiki.txt -o ${SOURCESDIR}/dl/arch-wiki.tar.xz
	tar xf ${SOURCESDIR}/dl/arch-wiki.tar.xz -C ${SOURCESDIR}

${SOURCESDIR}/dl/devdocs.tar.xz: ${SOURCESDIR}/dl/devdocs.txt
	test ! -f ${SOURCESDIR}/.local
	xargs curl -L < ${SOURCESDIR}/dl/devdocs.txt -o ${SOURCESDIR}/dl/devdocs.tar.xz
	tar xf ${SOURCESDIR}/dl/devdocs.tar.xz -C ${SOURCESDIR}

${SOURCESDIR}/dl/freebsd-docs.tar.xz: ${SOURCESDIR}/dl/freebsd-docs.txt
	test ! -f ${SOURCESDIR}/.local
	xargs curl -L < ${SOURCESDIR}/dl/freebsd-docs.txt -o ${SOURCESDIR}/dl/freebsd-docs.tar.xz
	tar xf ${SOURCESDIR}/dl/freebsd-docs.tar.xz -C ${SOURCESDIR}

${SOURCESDIR}/dl/gentoo-wiki.tar.xz: ${SOURCESDIR}/dl/gentoo-wiki.txt
	test ! -f ${SOURCESDIR}/.local
	xargs curl -L < ${SOURCESDIR}/dl/gentoo-wiki.txt -o ${SOURCESDIR}/dl/gentoo-wiki.tar.xz
	tar xf ${SOURCESDIR}/dl/gentoo-wiki.tar.xz -C ${SOURCESDIR}

${SOURCESDIR}/dl/tldr-pages.tar.xz: ${SOURCESDIR}/dl/tldr-pages.txt
	test ! -f ${SOURCESDIR}/.local
	xargs curl -L < ${SOURCESDIR}/dl/tldr-pages.txt -o ${SOURCESDIR}/dl/tldr-pages.tar.xz
	tar xf ${SOURCESDIR}/dl/tldr-pages.tar.xz -C ${SOURCESDIR}
