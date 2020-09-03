.POSIX:

NAME=wikiman
UPSTREAM=https://github.com/filiparag/wikiman
SOURCES = '${UPSTREAM}/releases/download/'
BUILD=./bin


make: ${NAME}.sh ${NAME}.1.man ${NAME}.conf LICENSE README.md sources/ widgets/

	@mkdir -p ${BUILD}/usr/share/${NAME} \
		${BUILD}/usr/share/licenses/${NAME} \
		${BUILD}/usr/share/doc/${NAME} \
		${BUILD}/usr/share/man/man1 \
		${BUILD}/usr/bin \
		${BUILD}/etc
	@install -Dm755 ./${NAME}.sh $(BUILD)/usr/bin/${NAME}
	@cp -fr ./sources ${BUILD}/usr/share/${NAME}
	@cp -fr ./widgets ${BUILD}/usr/share/${NAME}
	@install -Dm644 ./LICENSE ${BUILD}/usr/share/licenses/${NAME} 
	@install -Dm644 ./README.md ${BUILD}/usr/share/doc/wikiman 
	@install -Dm644 ./${NAME}.conf ${BUILD}/etc
	@tar czf ${BUILD}/usr/share/man/man1/${NAME}.1.gz ./${NAME}.1.man

install: ${BUILD}/usr/share/${NAME} ${BUILD}/etc/${NAME}.conf ${BUILD}/usr/bin/${NAME} ${BUILD}/usr/share/licenses/${NAME}/LICENSE ${BUILD}/usr/share/man/man1/${NAME}.1.gz ${BUILD}/usr/share/doc/${NAME}/README.md

	@mkdir -p $(prefix)/
	@cp -fr ${BUILD}/* $(prefix)/
	

clean:

	@rm -rf ./bin

uninstall: 

	@rm -rf $(prefix)/etc/${NAME}.conf $(prefix)/usr/bin/${NAME} $(prefix)/usr/share/${NAME} $(prefix)/usr/share/licenses/${NAME} $(prefix)/usr/share/man/man1/${NAME}.1.gz $(prefix)/usr/share/doc/${NAME}

source-install: ${BUILD}/usr/share/doc

	@mkdir -p $(prefix)/
	@cp -fr ${BUILD}/* $(prefix)/

source-arch:

	@mkdir -p ${BUILD}/tmp ${BUILD}/usr/share/doc
	@curl -L '${SOURCES}/2.9/arch-wiki_20200903.tar.xz' -o ${BUILD}/tmp/arch.tar.xz
	@tar xf ${BUILD}/tmp/arch.tar.xz -C ${BUILD}
	@rm -f ${BUILD}/tmp/arch.tar.xz

source-gentoo:

	@mkdir -p ${BUILD}/tmp ${BUILD}/usr/share/doc
	@curl -L '${SOURCES}/2.7/gentoo-wiki_20200831-1.tar.xz' -o ${BUILD}/tmp/gentoo.tar.xz
	@tar xf ${BUILD}/tmp/gentoo.tar.xz -C ${BUILD}
	@rm -f ${BUILD}/tmp/gentoo.tar.xz
	
source-fbsd:

	@mkdir -p ${BUILD}/tmp ${BUILD}/usr/share/doc
	@curl -L '${SOURCES}/2.9/freebsd-docs_20200903.tar.xz' -o ${BUILD}/tmp/fbsd.tar.xz
	@tar xf ${BUILD}/tmp/fbsd.tar.xz -C ${BUILD}
	@rm -f ${BUILD}/tmp/fbsd.tar.xz

source-tldr:

	@mkdir -p ${BUILD}/tmp ${BUILD}/usr/share/doc
	@curl -L '${SOURCES}/2.9/tldr-pages_20200903.tar.xz' -o ${BUILD}/tmp/fbsd.tar.xz
	@tar xf ${BUILD}/tmp/fbsd.tar.xz -C ${BUILD}
	@rm -f ${BUILD}/tmp/fbsd.tar.xz
