# Created by: Filip Parag <filip@parag.rs>
# $FreeBSD$

PORTNAME=	wikiman
DISTVERSION=	2.12
PORTREVISION=	1
CATEGORIES=	textproc

MAINTAINER=	filip@parag.rs
COMMENT=	Offline interactive documentation search

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

RUN_DEPENDS=	findutils>4:misc/findutils gawk>5:lang/gawk \
		ripgrep>12:textproc/ripgrep fzf>0.2:textproc/fzf \
		w3m>0.5:www/w3m

USE_GITHUB=	YES
GH_ACCOUNT=	filiparag

OPTIONS_DEFINE=	DOCS CONFIG WDGTS COMPLT
OPTIONS_DEFAULT=DOCS CONFIG WDGTS COMPLT
OPTIONS_SUB=	YES
CONFIG_DESC=	Global configuration file
WDGTS_DESC=	Shell keybind widgets
COMPLT_DESC=	Shell completions for fish and zsh

do-install:
	${MKDIR} ${STAGEDIR}${BINDIR} ${STAGEDIR}${PREFIX}/share/wikiman/sources \
		 ${STAGEDIR}${MANPREFIX}/man/man1

	${INSTALL_SCRIPT} ${WRKSRC}/wikiman.sh ${STAGEDIR}${PREFIX}/bin/wikiman
	(cd ${WRKSRC}/sources && ${COPYTREE_BIN} . ${STAGEDIR}${PREFIX}/share/wikiman/sources)

	${GZIP_CMD} ${WRKSRC}/wikiman.1.man
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
	${MKDIR} ${STAGEDIR}${PREFIX}/etc/bash_completion.d \
		 ${STAGEDIR}${PREFIX}/share/fish/completions \
		 ${STAGEDIR}${PREFIX}/share/zsh/site-functions

	${INSTALL_DATA} ${WRKSRC}/completions/completions.bash \
			${STAGEDIR}${PREFIX}/etc/bash_completion.d/wikiman-completion.bash
	${INSTALL_DATA} ${WRKSRC}/completions/completions.fish \
			${STAGEDIR}${PREFIX}/share/fish/completions/wikiman.fish
	${INSTALL_DATA} ${WRKSRC}/completions/completions.zsh \
			${STAGEDIR}${PREFIX}/share/zsh/site-functions/_wikiman

.include <bsd.port.mk>
