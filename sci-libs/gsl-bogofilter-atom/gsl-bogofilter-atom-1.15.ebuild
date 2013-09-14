# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit eutils flag-o-matic autotools toolchain-funcs

MY_PN="gsl"
MY_P="gsl-1.15"

DESCRIPTION="The GNU Scientific Library"
HOMEPAGE="http://www.gnu.org/software/gsl/"
SRC_URI="mirror://gnu/${MY_PN}/${MY_P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="cblas-external static-libs"

RDEPEND="cblas-external? ( virtual/cblas )"
DEPEND="${RDEPEND}
	app-admin/eselect-cblas
	virtual/pkgconfig
	mail-filter/bogofilter"

DOCS=( AUTHORS BUGS ChangeLog NEWS README THANKS TODO )

WORKDIR="/var/tmp/portage/sci-libs/gsl-bogofilter-atom-1.15/work/gsl-1.15"
S="${WORKDIR}"

pkg_pretend() {
	if [[ ${MERGE_TYPE} != binary ]]; then
		# prevent to use external cblas from a previously installed gsl
		local current_lib
		if use cblas-external; then
			current_lib=$(eselect cblas show | cut -d' ' -f2)
			if [[ ${current_lib} == gsl ]]; then
				ewarn "USE flag cblas-external is set: linking gsl with an external cblas."
				ewarn "However the current selected external cblas is gsl."
				ewarn "Please install and/or eselect another cblas"
			fi
		fi
	fi
}

pkg_setup() {
	ESELECT_PROF="gsl"

	if [[ ${MERGE_TYPE} != binary ]]; then
		# bug 349005
		[[ $(tc-getCC)$ == *gcc* ]] && \
			[[ $(tc-getCC)$ != *apple* ]] && \
			[[ $(gcc-major-version)$(gcc-minor-version) -eq 44 ]] \
			&& filter-mfpmath sse
		filter-flags -ffast-math
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${MY_P}-cblas.patch
	eautoreconf --help

	cp "${FILESDIR}"/eselect.cblas.gsl "${T}"/
	sed -i -e "s:/usr:${EPREFIX}/usr:" "${T}"/eselect.cblas.gsl || die
	if [[ ${CHOST} == *-darwin* ]] ; then
		sed -i -e 's/\.so\([\.0-9]\+\)\?/\1.dylib/g' \
			"${T}"/eselect.cblas.gsl || die
	fi
}

src_configure() {
	if use cblas-external; then
		export CBLAS_LIBS="$($(tc-getPKG_CONFIG) --libs cblas)"
		export CBLAS_CFLAGS="$($(tc-getPKG_CONFIG) --cflags cblas)"
	fi
	econf \
		--prefix=/opt/bogofilter \
		--libdir=/opt/bogofilter/atom-libs \
		--enable-shared \
		$(use_with cblas-external cblas) \
		$(use_enable static-libs static)
	echo $EPREFIX
	echo $EROOT
}

src_install() {
	default

	find "${ED}" -name '*.la' -exec rm -f {} +
	rm -rf ${ED}/usr/
	rm -rf ${ED}/opt/bogofilter/bin
	rm -rf ${ED}/opt/bogofilter/include

	# take care of pkgconfig file for cblas implementation.
	sed -e "s/@LIBDIR@/$(get_libdir)/" \
		-e "s/@PV@/${PV}/" \
		-e "/^prefix=/s:=:=${EPREFIX}:" \
		-e "/^libdir=/s:=:=${EPREFIX}:" \
		"${FILESDIR}"/cblas.pc.in > cblas.pc \
		|| die "sed cblas.pc failed"
	echo $get_libdir
	ls $libdir
	insinto /opt/bogofilter/atom-libs/blas/gsl
	doins cblas.pc || die "installing cblas.pc failed"
	eselect cblas add $(get_libdir) "${T}"/eselect.cblas.gsl \
		${ESELECT_PROF}
	rm -rf opt/bogofilter/include/gsl
	rm -rf usr/lib/debug/opt/bogofilter/bin/gsl*
	rm -rf usr/lib/debug/opt/bogofilter/atom-libs
	rm usr/share/aclocal/gsl.m4
	rm -rf usr/share/doc/gsl*
	rm -rf usr/share/info/gsl*
	rm -rf usr/share/man/man1/gsl*
	rm -rf usr/share/man/man3/gsl*
}

pkg_postinst() {
	local p=cblas
	local current_lib=$(eselect ${p} show | cut -d' ' -f2)
	if [[ ${current_lib} == ${ESELECT_PROF} || -z ${current_lib} ]]; then
		# work around eselect bug #189942
		local configfile="${EROOT}"/etc/env.d/${p}/$(get_libdir)/config
		[[ -e ${configfile} ]] && rm -f ${configfile}
		eselect ${p} set ${ESELECT_PROF}
		elog "${p} has been eselected to ${ESELECT_PROF}"
	else
		elog "Current eselected ${p} is ${current_lib}"
		elog "To use ${p} ${ESELECT_PROF} implementation, you have to issue (as root):"
		elog "\t eselect ${p} set ${ESELECT_PROF}"
	fi
}
