NAME=		wikiman
VERSION=	2.13.1
RELEASE=	1
UPSTREAM=	https://github.com/filiparag/wikiman
SOURCES= 	${UPSTREAM}/releases/download/

MKFILEREL!=	echo ${.MAKE.MAKEFILES} | sed 's/.* //'
MKFILEABS!=	readlink -f ${MKFILEREL} 2>/dev/null
MKFILEABS+= $(shell readlink -f ${MAKEFILE_LIST})
WORKDIR!=	dirname ${MKFILEABS} 2>/dev/null

BUILDDIR:=	${WORKDIR}/pkgbuild
SOURCESDIR:=${WORKDIR}/srcbuild
PLISTFILE:=	${WORKDIR}/pkg-plist

all: core widgets completions config docs

core:

	@mkdir -p	${BUILDDIR}/usr/bin \
	 			${BUILDDIR}/usr/share/${NAME} \
				${BUILDDIR}/usr/share/licenses/${NAME} \
				${BUILDDIR}/usr/share/man/man1
	@install 	-Dm755 	${WORKDIR}/${NAME}.sh 	${BUILDDIR}/usr/bin/${NAME}
	@cp 		-fr 	${WORKDIR}/sources 		${BUILDDIR}/usr/share/${NAME}
	@install 	-Dm644 	${WORKDIR}/LICENSE 		${BUILDDIR}/usr/share/licenses/${NAME}
	@gzip 		-k		${WORKDIR}/${NAME}.1.man
	@mv 		${WORKDIR}/${NAME}.1.man.gz		${BUILDDIR}/usr/share/man/man1/${NAME}.1.gz

widgets: core

	@mkdir -p 	${BUILDDIR}/usr/share/${NAME}
	@cp 		-fr 	${WORKDIR}/widgets 		${BUILDDIR}/usr/share/${NAME}

completions: core

	@mkdir -p 	${BUILDDIR}/etc/bash_completion.d \
				${BUILDDIR}/usr/share/fish/completions \
				${BUILDDIR}/usr/share/zsh/site-functions
	@install 	-Dm644 	${WORKDIR}/completions/completions.bash	${BUILDDIR}/etc/bash_completion.d/${NAME}-completion.bash
	@install 	-Dm644 	${WORKDIR}/completions/completions.fish	${BUILDDIR}/usr/share/fish/completions/${NAME}.fish
	@install 	-Dm644 	${WORKDIR}/completions/completions.zsh	${BUILDDIR}/usr/share/zsh/site-functions/_${NAME}

config:

	@mkdir -p 	${BUILDDIR}/etc
	@install 	-Dm644 	${WORKDIR}/${NAME}.conf ${BUILDDIR}/etc

docs:

	@mkdir -p 	${BUILDDIR}/usr/share/doc/${NAME}
	@install 	-Dm644 	${WORKDIR}/README.md 	${BUILDDIR}/usr/share/doc/${NAME}

reinstall: install
install: all

	@mkdir -p 	$(prefix)/
	@cp -fr 	${BUILDDIR}/* $(prefix)/

plist: all

	@find 		${BUILDDIR} -type f > ${PLISTFILE}
	@sed -i 	's|${BUILDDIR}/||' ${PLISTFILE}

dist: package
package: all

	@tar czf ${WORKDIR}/${NAME}-${VERSION}-${RELEASE}.tar.gz ${BUILDDIR}

distclean: clean
clean:

	@rm -f 	${PLISTFILE} \
			${WORKDIR}/${NAME}-${VERSION}-${RELEASE}.tar.gz
	@rm -rf ${BUILDDIR} \
			${SOURCESDIR}

deinstall: uninstall
uninstall:

	@rm -f	$(prefix)/etc/${NAME}.conf \
			$(prefix)/usr/bin/${NAME} \
			$(prefix)/usr/share/man/man1/${NAME}.1.gz \
			$(prefix)/etc/bash_completion.d/${NAME}-completion.bash \
			$(prefix)/usr/share/fish/completions/${NAME}.fish \
			$(prefix)/usr/share/zsh/site-functions/_${NAME}
	@rm -rf $(prefix)/usr/share/${NAME} \
			$(prefix)/usr/share/licenses/${NAME} \
			$(prefix)/usr/share/doc/${NAME}

	@rm -f	$(prefix)/usr/local/etc/${NAME}.conf \
			$(prefix)/usr/local/bin/${NAME} \
			$(prefix)/usr/local/share/man/man1/${NAME}.1.gz \
			$(prefix)/etc/bash_completion.d/${NAME}-completion.bash \
			$(prefix)/usr/share/fish/completions/${NAME}.fish \
			$(prefix)/usr/share/zsh/site-functions/_${NAME}
	@rm -rf $(prefix)/usr/local/share/${NAME} \
			$(prefix)/usr/local/share/licenses/${NAME} \
			$(prefix)/usr/local/share/doc/${NAME}

local:

	@test ! -d	${BUILDDIR}/usr/local

	@mkdir -p	${BUILDDIR}/tmp ${BUILDDIR}/usr ${BUILDDIR}/etc
	@mv			${BUILDDIR}/usr ${BUILDDIR}/etc ${BUILDDIR}/tmp
	@mkdir -p	${BUILDDIR}/usr/local/usr ${BUILDDIR}/usr/local/etc
	@mv			${BUILDDIR}/tmp/* ${BUILDDIR}/usr/local
	@rm -rf		${BUILDDIR}/tmp ${BUILDDIR}/etc

	@mkdir -p	${SOURCESDIR}/usr/local/share ${SOURCESDIR}/usr/share/doc
	@mv			${SOURCESDIR}/usr/share/doc ${SOURCESDIR}/usr/local/share/doc
	@rm -rf		${SOURCESDIR}/usr/share

.PHONY: help
help:

	@sed -n '/^[-a-z]\+:/p;' ${MKFILEABS}

source:

	@mkdir -p 	${SOURCESDIR}/usr/share/doc \
				${SOURCESDIR}/tmp

source-all: source-arch source-gentoo source-fbsd source-tldr

source-reinstall: source-install
source-install:

	@[ -d ${SOURCESDIR}/usr/share/doc ] && \
				mkdir -p $(prefix)/usr/share/doc && \
				cp -rf 	 ${SOURCESDIR}/usr/share/doc $(prefix)/usr/share || true

	@[ -d ${SOURCESDIR}/usr/local/share/doc ] && \
				mkdir -p $(prefix)/usr/local/share/doc && \
				cp -rf 	 ${SOURCESDIR}/usr/local/share/doc $(prefix)/usr/local/share || true

source-clean:

	@rm -rf 	${SOURCESDIR}

source-deinstall: source-uninstall
source-uninstall:

	@rm -rf		$(prefix)/usr/share/doc/arch-wiki/html \
				$(prefix)/usr/share/doc/gentoo-wiki \
				$(prefix)/usr/share/doc/freebsd-docs \
				$(prefix)/usr/share/doc/tldr-pages

	@rm -rf		$(prefix)/usr/local/share/doc/arch-wiki/html \
				$(prefix)/usr/local/share/doc/gentoo-wiki \
				$(prefix)/usr/local/share/doc/freebsd-docs \
				$(prefix)/usr/local/share/doc/tldr-pages

source-arch: source

	@curl -L 	'${SOURCES}/2.13.1/arch-wiki_20220922.tar.xz' -o ${SOURCESDIR}/tmp/arch.tar.xz
	@sha1sum 	${SOURCESDIR}/tmp/arch.tar.xz | grep -q '42efd791f7df39a1d4ad3434518e278152f5a00d'
	@tar xf 	${SOURCESDIR}/tmp/arch.tar.xz -C ${SOURCESDIR}
	@rm -rf 	${SOURCESDIR}/tmp

source-gentoo: source

	@curl -L 	'${SOURCES}/2.7/gentoo-wiki_20200831-1.tar.xz' -o ${SOURCESDIR}/tmp/gentoo.tar.xz
	@sha1sum 	${SOURCESDIR}/tmp/gentoo.tar.xz | grep -q '5abbba5ca440865a766bbb939a3cbb5194096dfb'
	@tar xf 	${SOURCESDIR}/tmp/gentoo.tar.xz -C ${SOURCESDIR}
	@rm -rf 	${SOURCESDIR}/tmp
	
source-fbsd: source

	@curl -L 	'${SOURCES}/2.13/freebsd-docs_20211009.tar.xz' -o ${SOURCESDIR}/tmp/fbsd.tar.xz
	@sha1sum 	${SOURCESDIR}/tmp/fbsd.tar.xz | grep -q '96c00949613fd21f107d3bf8f1df59ebd61cc40a'
	@tar xf 	${SOURCESDIR}/tmp/fbsd.tar.xz -C ${SOURCESDIR}
	@rm -rf 	${SOURCESDIR}/tmp

source-tldr: source

	@curl -L 	'${SOURCES}/2.13.1/tldr-pages_20220922.tar.xz' -o ${SOURCESDIR}/tmp/tldr.tar.xz
	@sha1sum 	${SOURCESDIR}/tmp/tldr.tar.xz | grep -q '6b3a0452e3bdbbc27e37198eb2602ce7e887e2f5'
	@tar xf 	${SOURCESDIR}/tmp/tldr.tar.xz -C ${SOURCESDIR}
	@rm -rf 	${SOURCESDIR}/tmp
