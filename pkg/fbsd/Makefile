# Created by: Filip Parag <filip@parag.rs>
# $FreeBSD$

PORTNAME=		wikiman
DISTVERSION=	2.11.3
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

OPTIONS_DEFINE=	DOCS CONFIG WDGTS COMPLT
OPTIONS_DEFAULT=DOCS CONFIG WDGTS COMPLT
CONFIG_DESC=	Global configuration file
WDGTS_DESC=		Shell keybind widgets
COMPLT_DESC=	Shell completions for fish and zsh

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

do-install-WDGTS-on:

	${MKDIR} ${STAGEDIR}${PREFIX}/share/wikiman/widgets
	(cd ${WRKSRC}/widgets && ${COPYTREE_BIN} . ${STAGEDIR}${PREFIX}/share/wikiman/widgets)

do-install-COMPLT-on:

	${MKDIR} ${STAGEDIR}${PREFIX}/share/fish/completions ${STAGEDIR}${PREFIX}/share/zsh/site-functions
	${INSTALL_DATA} ${WRKSRC}/completions/completions.fish ${STAGEDIR}${PREFIX}/share/fish/completions/wikiman.fish
	${INSTALL_DATA} ${WRKSRC}/completions/completions.zsh ${STAGEDIR}${PREFIX}/share/zsh/site-functions/_wikiman

.include <bsd.port.mk>