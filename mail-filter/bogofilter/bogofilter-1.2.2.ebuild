# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/mail-filter/bogofilter/bogofilter-1.2.3.ebuild,v 1.8 2012/12/15 17:45:29 armin76 Exp $

EAPI=4
inherit db-use eutils flag-o-matic toolchain-funcs

DESCRIPTION="Bayesian spam filter designed with fast algorithms, and tuned for speed."
HOMEPAGE="http://bogofilter.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2
		mirror://gnu/gsl/gsl-1.15.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sh sparc x86 ~x86-fbsd"
IUSE="berkdb sqlite tokyocabinet gsl atompkg"

DEPEND="virtual/libiconv
	berkdb?  ( >=sys-libs/db-3.2 )
	!berkdb? (
		sqlite?  ( >=dev-db/sqlite-3.6.22 )
		!sqlite? (
			tokyocabinet? ( dev-db/tokyocabinet )
			!tokyocabinet? ( >=sys-libs/db-3.2 )
		)
	)"
#	sci-libs/gsl-bogofilter-atom"
#	app-arch/pax" # only needed for bf_tar
RDEPEND="${DEPEND}"

S="${WORKDIR}"/${P}

pkg_setup() {
	has_version mail-filter/bogofilter || return 0
	if  (   use berkdb && ! has_version 'mail-filter/bogofilter[berkdb]' ) || \
		( ! use berkdb &&   has_version 'mail-filter/bogofilter[berkdb]' ) || \
		(   use sqlite && ! has_version 'mail-filter/bogofilter[sqlite]' ) || \
		( ! use sqlite &&   has_version 'mail-filter/bogofilter[sqlite]' ) || \
		( has_version '>=mail-filter/bogofilter-1.2.1-r1' && \
			(   use tokyocabinet && ! has_version 'mail-filter/bogofilter[tokyocabinet]' ) || \
			( ! use tokyocabinet &&   has_version 'mail-filter/bogofilter[tokyocabinet]' )
		) ; then
		ewarn
		ewarn "If you want to switch the database backend, you must dump the wordlist"
		ewarn "with the current version (old use flags) and load it with the new version!"
		ewarn
	fi
}

#src_prepare() {
	#cd "${WORKDIR}"/gsl-1.15/
	#econf --prefix="/opt/bogofilter/gsl/" --libdir="/opt/bogofilter/atom-libs/"
	#emake
	#emake install
	#cd "${WORKDIR}"/${P}
#}

src_configure() {
    cd "${WORKDIR}"/gsl-1.15/
	econf --prefix="/opt/bogofilter/gsl/" --libdir="${WORKDIR}/opt/bogofilter/atom-libs/"
	#ls -LR
	#emake DESTDIR="${D}" install
	#set -ex
	myconf="" berkdb=true
	if use gsl ; then
		myconf="--with-included-gsl"
	else
		myconf="--without-included-gsl"
	fi

	if use atompkg ; then
		export LD_LIBRARY_PATH="/opt/bogofilter/atom-libs/"
		echo ${libdir}
	fi

	# determine backend: berkdb *is* default
	if use berkdb && use sqlite ; then
		elog "Both useflags berkdb and sqlite are in USE:"
		elog "Using berkdb as database backend."
	elif use berkdb && use tokyocabinet ; then
		elog "Both useflags berkdb and tokyocabinet are in USE:"
		elog "Using berkdb as database backend."
	elif use sqlite && use tokyocabinet ; then
		elog "Both useflags sqlite and tokyocabinet are in USE:"
		elog "Using sqlite as database backend."
		myconf="${myconf} --with-database=sqlite"
		berkdb=false
	elif use sqlite ; then
		myconf="${myconf} --with-database=sqlite"
		berkdb=false
	elif use tokyocabinet ; then
		myconf="${myconf} --with-database=tokyocabinet"
		berkdb=false
	elif ! use berkdb ; then
		elog "Neither berkdb nor sqlite nor tokyocabinet are in USE:"
		elog "Using berkdb as database backend."
	fi

	# Include the right berkdb headers for FreeBSD
	if ${berkdb} ; then
		append-cppflags "-I$(db_includedir)"
	fi

	# bug #324405
	if [[ $(gcc-version) == "3.4" ]] ; then
		epatch "${FILESDIR}"/${PN}-1.2.2-gcc34.patch
	fi
	#myconf="${myconf} --prefix=/opt/bogofilter/ --with-gsl-prefix=${D}/opt/bogofilter/gsl/ --libdir=${D}/opt/bogofilter/atom-libs/"
    
	#cd "${WORKDIR}"/${P}
	#LD_LIBRARY_PATH="${D}/opt/bogofilter/atom-libs/" econf ${myconf}
}

src_compile() {
	cd "${WORKDIR}"/gsl-1.15/
	emake
	LD_LIBRARY_PATH="${D}/opt/bogofilter/atom-libs/" emake DESTDIR="${D}" install
	cp -R ${D}/var/tmp/portage/mail-filter/bogofilter-1.2.3/work/opt/bogofilter/atom-libs ${WORKDIR}/ || die
	cp -R ${D}/opt/bogofilter/ ${WORKDIR}/ || die
	#die
	#cd "${WORKDIR}"/${P}
	#LD_LIBRARY_PATH="${D}/opt/bogofilter/atom-libs/" emake
	#emake
	#cd /opt/bogofilter/
}

src_install() {
    myconf="${myconf} --prefix=/opt/bogofilter/ --with-gsl-prefix=${WORKDIR}/bogofilter/gsl/ --libdir=${WORKDIR}/atom-libs/"

	#dodir ${D}/opt/bogofilter/atom-libs/
	#doins ${WORKDIR}/gsl-1.15/.libs/*

	#cd ${WORKDIR}/gsl-1.15/
	#emake DESTDIR="${D}" install
	
	cd "${WORKDIR}"/${P}
	ls -LR
	ls -LR ${D}/opt/bogofilter
	cp -R ${WORKDIR}/atom-libs/* ${WORKDIR}/bogofilter/gsl/lib64
	LD_LIBRARY_PATH="${WORKDIR}/atom-libs/" econf ${myconf}
	LD_LIBRARY_PATH=/var/tmp/portage/mail-filter/bogofilter-1.2.3/image/var/tmp/portage/mail-filter/bogofilter-1.2.3/work/opt/bogofilter/atom-libs/ econf ${myconf}
	die
	#cd ${WORKDIR}/gsl-1.15/
	#emake DESTDIR="${D}" install
	#cd ${WORKDIR}/${P}/
	emake DESTDIR="${D}" install

	dodir /opt/bogofilter/gsl/
	insinto /opt/bogofilter/gsl
	#cd /opt/bogofilter/gsl/
	doins -r ${WORKDIR}/gsl-1.15/*
	doins -r ${D}/gsl/*
	
	dodir /opt/bogofilter/atom-libs/
	insinto /opt/bogofilter/atom-libs/
	#cd /opt/bogofiter/atom-libs/
	doins ${WORKDIR}/gsl-1.15/.libs/*
	doins ${D}/gsl/.libs/*
	
	dodir /opt/bogofilter/
	insinto /opt/bogofilter/
	#cd /opt/bogofilter/
	doins -r ${S}/*

	exeinto /usr/share/${PN}/contrib
	doexe contrib/{bogofilter-qfe,parmtest,randomtrain}.sh \
		contrib/{bfproxy,bogominitrain,mime.get.rfc822,printmaildir}.pl \
		contrib/{spamitarium,stripsearch}.pl

	insinto /usr/share/${PN}/contrib
	doins contrib/{README.*,dot-qmail-bogofilter-default} \
		contrib/{bogogrep.c,bogo.R,bogofilter-milter.pl,*.example} \
		contrib/vm-bogofilter.el \
		contrib/{trainbogo,scramble}.sh

	dodoc AUTHORS NEWS README RELEASE.NOTES* TODO GETTING.STARTED \
		doc/integrating-with-* doc/README.{db,sqlite}

	dohtml doc/*.html

	dodir /usr/share/doc/${PF}/samples
	mv "${D}"/etc/bogofilter.cf.example "${D}"/usr/share/doc/${PF}/samples/
	rmdir "${D}"/etc

	die
}

pkg_postinst() {
	echo
	elog "If you need \"${ROOT}usr/bin/bf_tar\" please install app-arch/pax."
	echo
}
