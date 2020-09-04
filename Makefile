.POSIX:

NAME=		wikiman
VERSION=	2.11
RELEASE=	1
UPSTREAM=	https://github.com/filiparag/wikiman
SOURCES= 	${UPSTREAM}/releases/download/

WORKDIR:= 	$(shell dirname ${MAKEFILE_LIST})
BUILDDIR:=	${WORKDIR}/pkgbuild
SOURCESDIR:=${WORKDIR}/srcbuild
PLISTFILE:=	${WORKDIR}/pkg-plist


all: ${NAME}.sh ${NAME}.1.man ${NAME}.conf LICENSE README.md sources/ widgets/

	@mkdir -p 	${BUILDDIR}/usr/share/${NAME} \
				${BUILDDIR}/usr/share/licenses/${NAME} \
				${BUILDDIR}/usr/share/doc/${NAME} \
				${BUILDDIR}/usr/share/man/man1 \
				${BUILDDIR}/usr/bin \
				${BUILDDIR}/etc
	@install 	-Dm755 	./${NAME}.sh 	$(BUILDDIR)/usr/bin/${NAME}
	@cp 		-fr 	./sources 		${BUILDDIR}/usr/share/${NAME}
	@cp 		-fr 	./widgets 		${BUILDDIR}/usr/share/${NAME}
	@install 	-Dm644 	./${NAME}.conf 	${BUILDDIR}/etc
	@install 	-Dm644 	./LICENSE 		${BUILDDIR}/usr/share/licenses/${NAME} 
	@install 	-Dm644 	./README.md 	${BUILDDIR}/usr/share/doc/wikiman 
	@tar 		-czf 	${BUILDDIR}/usr/share/man/man1/${NAME}.1.gz ./${NAME}.1.man

reinstall: install
install: all

	@mkdir -p $(prefix)/
	@cp -fr ${BUILDDIR}/* $(prefix)/
	
plist: all ${BUILDDIR}

	@find ${BUILDDIR} -type f > ${PLISTFILE}
	@sed -i 's|${BUILDDIR}/||' ${PLISTFILE}

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
			$(prefix)/usr/share/man/man1/${NAME}.1.gz
	@rm -rf $(prefix)/usr/share/${NAME} \
			$(prefix)/usr/share/licenses/${NAME} \
			$(prefix)/usr/share/doc/${NAME}

source-install: ${SOURCESDIR}/usr/share/doc

	@mkdir -p $(prefix)/
	@cp -rf ${SOURCESDIR}/* $(prefix)/

source-arch:

	@mkdir -p ${SOURCESDIR}/tmp ${SOURCESDIR}/usr/share/doc
	@curl -L '${SOURCES}/2.9/arch-wiki_20200903.tar.xz' -o ${SOURCESDIR}/tmp/arch.tar.xz
	@tar xf ${SOURCESDIR}/tmp/arch.tar.xz -C ${SOURCESDIR}
	@rm -f ${SOURCESDIR}/tmp/arch.tar.xz

source-gentoo:

	@mkdir -p ${SOURCESDIR}/tmp ${SOURCESDIR}/usr/share/doc
	@curl -L '${SOURCES}/2.7/gentoo-wiki_20200831-1.tar.xz' -o ${SOURCESDIR}/tmp/gentoo.tar.xz
	@tar xf ${SOURCESDIR}/tmp/gentoo.tar.xz -C ${SOURCESDIR}
	@rm -f ${SOURCESDIR}/tmp/gentoo.tar.xz
	
source-fbsd:

	@mkdir -p ${SOURCESDIR}/tmp ${SOURCESDIR}/usr/share/doc
	@curl -L '${SOURCES}/2.9/freebsd-docs_20200903.tar.xz' -o ${SOURCESDIR}/tmp/fbsd.tar.xz
	@tar xf ${SOURCESDIR}/tmp/fbsd.tar.xz -C ${SOURCESDIR}
	@rm -f ${SOURCESDIR}/tmp/fbsd.tar.xz

source-tldr:

	@mkdir -p ${SOURCESDIR}/tmp ${SOURCESDIR}/usr/share/doc
	@curl -L '${SOURCES}/2.9/tldr-pages_20200903.tar.xz' -o ${SOURCESDIR}/tmp/fbsd.tar.xz
	@tar xf ${SOURCESDIR}/tmp/fbsd.tar.xz -C ${SOURCESDIR}
	@rm -f ${SOURCESDIR}/tmp/fbsd.tar.xz
