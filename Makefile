NAME=		wikiman
VERSION=	2.11
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

usr?=		usr
etc?=		etc
man?=		usr/share

all: core widgets completions config docs

core:

	@mkdir -p	${BUILDDIR}/${usr}/bin \
	 			${BUILDDIR}/${usr}/share/${NAME} \
				${BUILDDIR}/${usr}/share/licenses/${NAME} \
				${BUILDDIR}/${man}/man/man1
	@install 	-Dm755 	${WORKDIR}/${NAME}.sh 	${BUILDDIR}/${usr}/bin/${NAME}
	@cp 		-fr 	${WORKDIR}/sources 		${BUILDDIR}/${usr}/share/${NAME}
	@install 	-Dm644 	${WORKDIR}/LICENSE 		${BUILDDIR}/${usr}/share/licenses/${NAME}
	@gzip 		-k		${WORKDIR}/${NAME}.1.man
	@mv 		${WORKDIR}/${NAME}.1.man.gz		${BUILDDIR}/${man}/man/man1/${NAME}.1.gz

widgets: core

	@mkdir -p 	${BUILDDIR}/${usr}/share/${NAME}
	@cp 		-fr 	${WORKDIR}/widgets 		${BUILDDIR}/${usr}/share/${NAME}

completions: core

	@mkdir -p 	${BUILDDIR}/${usr}/share/fish/completions \
				${BUILDDIR}/${usr}/share/zsh/site-functions
	@install 	-Dm644 	${WORKDIR}/completions/completions.fish	${BUILDDIR}/${usr}/share/fish/completions/${NAME}.fish
	@install 	-Dm644 	${WORKDIR}/completions/completions.zsh	${BUILDDIR}/${usr}/share/zsh/site-functions/_${NAME}

config:

	@mkdir -p 	${BUILDDIR}/${etc}
	@install 	-Dm644 	${WORKDIR}/${NAME}.conf ${BUILDDIR}/${etc}

docs:

	@mkdir -p 	${BUILDDIR}/${usr}/share/doc/${NAME}
	@install 	-Dm644 	${WORKDIR}/README.md 	${BUILDDIR}/${usr}/share/doc/wikiman

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
			$(prefix)/${usr}/bin/${NAME} \
			$(prefix)/${man}/man/man1/${NAME}.1.gz
	@rm -rf $(prefix)/${usr}/share/${NAME} \
			$(prefix)/${usr}/share/licenses/${NAME} \
			$(prefix)/${usr}/share/doc/${NAME}

.PHONY: help
help:

	@sed -n '/^[-a-z]\+:/p;' ${MKFILEABS}

source:

	@mkdir -p 	${SOURCESDIR}/${usr}/share/doc \
				${SOURCESDIR}/tmp

source-all: source-arch source-gentoo source-fbsd source-tldr

source-reinstall: source-install
source-install: source

	@mkdir -p 	$(prefix)/${usr}/share/doc
	@cp -rf 	${SOURCESDIR}/${usr}/share/doc/* $(prefix)/${usr}/share/doc

source-clean:

	@rm -rf 	${SOURCESDIR}

source-deinstall: source-uninstall
source-uninstall:

	@rm -rf		$(prefix)/${usr}/share/doc/arch-wiki/html \
				$(prefix)/${usr}/share/doc/gentoo-wiki \
				$(prefix)/${usr}/share/doc/freebsd-docs \
				$(prefix)/${usr}/share/doc/tldr-pages

source-arch: source

	@curl -L 	'${SOURCES}/2.9/arch-wiki_20200903.tar.xz' -o ${SOURCESDIR}/tmp/arch.tar.xz
	@tar xf 	${SOURCESDIR}/tmp/arch.tar.xz -C ${SOURCESDIR}
	@rm -f 		${SOURCESDIR}/tmp/arch.tar.xz

source-gentoo: source

	@curl -L 	'${SOURCES}/2.7/gentoo-wiki_20200831-1.tar.xz' -o ${SOURCESDIR}/tmp/gentoo.tar.xz
	@tar xf 	${SOURCESDIR}/tmp/gentoo.tar.xz -C ${SOURCESDIR}
	@rm -f 		${SOURCESDIR}/tmp/gentoo.tar.xz
	
source-fbsd: source

	@curl -L 	'${SOURCES}/2.9/freebsd-docs_20200903.tar.xz' -o ${SOURCESDIR}/tmp/fbsd.tar.xz
	@tar xf 	${SOURCESDIR}/tmp/fbsd.tar.xz -C ${SOURCESDIR}
	@rm -f 		${SOURCESDIR}/tmp/fbsd.tar.xz

source-tldr: source

	@curl -L 	'${SOURCES}/2.9/tldr-pages_20200903.tar.xz' -o ${SOURCESDIR}/tmp/fbsd.tar.xz
	@tar xf 	${SOURCESDIR}/tmp/fbsd.tar.xz -C ${SOURCESDIR}
	@rm -f 		${SOURCESDIR}/tmp/fbsd.tar.xz
