# Created by: Filip Parag <filip@parag.rs>
# $FreeBSD$

PORTNAME=		wikiman
DISTVERSION=	2.11.2
PORTREVISION=	1
CATEGORIES=		misc

MAINTAINER=		filip@parag.rs
COMMENT=		Offline interactive documentation search

LICENSE=		MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

LIB_DEPENDS=	
RUN_DEPENDS=	gfind:misc/findutils gawk:lang/gawk

USES=			

USE_GITHUB=		yes
GH_ACCOUNT=		filiparag
GH_TAG=			

OPTIONS_DEFINE=	DOCS CONFIG WIDGETS
OPTIONS_DEFAULT=DOCS CONFIG
CONFIG_DESC=	Global configuration file
WIDGETS_DESC=	Shell keybind widgets

do-install:

	${MKDIR} ${STAGEDIR}${BINDIR} ${STAGEDIR}${PREFIX}/share/wikiman/sources \
			 ${STAGEDIR}${MANPREFIX}/man/man1

	${INSTALL_SCRIPT} ${WRKSRC}/wikiman.sh ${STAGEDIR}${PREFIX}/bin/wikiman
	(cd ${WRKSRC}/sources && ${COPYTREE_BIN} . ${STAGEDIR}${PREFIX}/share/wikiman/sources)
	
	gzip ${WRKSRC}/wikiman.1.man
	${INSTALL_MAN} ${WRKSRC}/wikiman.1.man.gz ${STAGEDIR}${MANPREFIX}/man/man1/wikiman.1.gz

do-install-DOCS-on:

	${MKDIR} ${STAGEDIR}${DOCSDIR}
	${INSTALL_DATA} ${WRKSRC}/README.md ${STAGEDIR}${DOCSDIR}

do-install-CONFIG-on:

	${MKDIR} ${STAGEDIR}${PREFIX}/etc
	${INSTALL_DATA} ${WRKSRC}/wikiman.conf ${STAGEDIR}${PREFIX}/etc

do-install-WIDGETS-on:

	${MKDIR} ${STAGEDIR}${PREFIX}/share/wikiman/widgets
	(cd ${WRKSRC}/widgets && ${COPYTREE_BIN} . ${STAGEDIR}${PREFIX}/share/wikiman/widgets)

.include <bsd.port.mk>