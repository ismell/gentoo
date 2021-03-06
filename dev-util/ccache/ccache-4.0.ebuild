# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake

DESCRIPTION="fast compiler cache"
HOMEPAGE="https://ccache.dev/"
SRC_URI="https://github.com/ccache/ccache/releases/download/v${PV}/ccache-${PV}.tar.xz"

LICENSE="GPL-3 LGPL-3"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="test"

DEPEND=""
RDEPEND="${DEPEND}
	dev-util/shadowman
	sys-apps/gentoo-functions"
# clang-specific tests use dev-libs/elfutils to compare objects for equality.
# Let's pull in the dependency unconditionally.
DEPEND+="
	test? ( dev-libs/elfutils )"

RESTRICT="!test? ( test )"

DOCS=( doc/{AUTHORS,MANUAL,NEWS}.adoc CONTRIBUTING.md README.md )

PATCHES=(
	"${FILESDIR}"/${PN}-3.5-nvcc-test.patch
	"${FILESDIR}"/${PN}-4.0-objdump.patch
	"${FILESDIR}"/${PN}-4.0-avoid-run-user.patch
)

src_prepare() {
	cmake_src_prepare

	sed \
		-e "/^EPREFIX=/s:'':'${EPREFIX}':" \
		"${FILESDIR}"/ccache-config-3 > ccache-config || die

	# mainly used in tests
	tc-export CC OBJDUMP
}

src_install() {
	# TODO: install manpage: https://github.com/ccache/ccache/issues/684
	cmake_src_install

	dobin ccache-config
	insinto /usr/share/shadowman/tools
	newins - ccache <<<"${EPREFIX}/usr/lib/ccache/bin"
}

pkg_prerm() {
	if [[ -z ${REPLACED_BY_VERSION} && ${ROOT:-/} == / ]] ; then
		eselect compiler-shadow remove ccache
	fi
}

pkg_postinst() {
	if [[ ${ROOT:-/} == / ]]; then
		eselect compiler-shadow update ccache
	fi
}
