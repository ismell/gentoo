# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} )
PYTHON_REQ_USE="threads(+)"

inherit flag-o-matic distutils-r1 toolchain-funcs

EGIT_COMMIT="dd4dac055152d47c829034224cdecf594c7b3f12"
DESCRIPTION="Lightweight and super-fast messaging library built on top of the ZeroMQ library"
HOMEPAGE="
	https://www.zeromq.org/bindings:python
	https://pypi.org/project/pyzmq/
	https://github.com/zeromq/pyzmq/"
SRC_URI="
	https://github.com/zeromq/pyzmq/archive/${EGIT_COMMIT}.tar.gz
		-> ${P}.tar.gz"
S=${WORKDIR}/${PN}-${EGIT_COMMIT}

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 arm arm64 ~mips ~ppc ~ppc64 x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="+draft"

DEPEND="
	>=net-libs/zeromq-4.2.2-r2:=[drafts]
"
RDEPEND="${DEPEND}
	dev-python/py[${PYTHON_USEDEP}]
	dev-python/cffi:=[${PYTHON_USEDEP}]
"
BDEPEND="
	dev-python/cython[${PYTHON_USEDEP}]
	test? (
		>=www-servers/tornado-5.0.2[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest
distutils_enable_sphinx docs \
	"dev-python/numpydoc"

python_configure_all() {
	tc-export CC
	append-cppflags -DZMQ_BUILD_DRAFT_API=$(usex draft '1' '0')
}

python_compile() {
	esetup.py cython --force
	distutils-r1_python_compile
}

python_test() {
	local deselect=(
		# lore says it sometimes hangs
		zmq/tests/test_auth.py::TestThreadAuthentication::test_curve

		# broken tests
		zmq/tests/test_auth.py::TestThreadAuthentication::test_curve_user_id
		zmq/tests/test_constants.py::TestConstants::test_draft
		zmq/tests/test_context.py::TestContext::test_mockable
		zmq/tests/test_draft.py::TestDraftSockets::test_client_server
		zmq/tests/test_draft.py::TestDraftSockets::test_radio_dish
		zmq/tests/test_message.py::TestFrame::test_buffer_numpy
		zmq/tests/test_message.py::TestFrame::test_bytes
		zmq/tests/test_message.py::TestFrame::test_frame_more
		zmq/tests/test_message.py::TestFrame::test_lifecycle1
		zmq/tests/test_message.py::TestFrame::test_lifecycle2
		zmq/tests/test_message.py::TestFrame::test_memoryview_shape
		zmq/tests/test_message.py::TestFrame::test_multi_tracker
		zmq/tests/test_message.py::TestFrame::test_tracker
		zmq/tests/test_security.py::TestSecurity::test_curve
		zmq/tests/test_security.py::TestSecurity::test_plain
		zmq/tests/test_socket.py::TestSocket::test_large_send
		zmq/tests/test_socket.py::TestSocket::test_tracker
		zmq/tests/test_socket.py::TestSocketGreen::test_large_send

		# hanging tests
		zmq/tests/test_socket.py::TestSocketGreen::test_tracker
		zmq/tests/asyncio/test_asyncio.py::TestAsyncioAuthentication::test_blacklist
		zmq/tests/asyncio/test_asyncio.py::TestAsyncioAuthentication::test_curve
		zmq/tests/asyncio/test_asyncio.py::TestAsyncioAuthentication::test_plain
	)
	[[ ${EPYTHON} == python3.9 ]] && deselect+=(
		# crashes python
		zmq/tests/test_socket.py::TestSocketGreen
	)

	pytest -vv ${deselect[@]/#/--deselect } ||
		die "Tests failed with ${EPYTHON}"
}
