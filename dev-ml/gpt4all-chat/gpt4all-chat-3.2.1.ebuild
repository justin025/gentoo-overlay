# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

: "${CMAKE_BUILD_TYPE:=Release}"

inherit cmake desktop flag-o-matic xdg qmake-utils

DESCRIPTION="Cross platform Qt based GUI for GPT4All"
HOMEPAGE="https://github.com/nomic-ai/gpt4all/ https://nomic.ai/"
SRC_URI="
	https://github.com/nomic-ai/gpt4all/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/nomic-ai/llama.cpp/archive/443665aec4721ecf57df8162e7e093a0cd674a76.tar.gz -> ${P}-llama.cpp.tar.gz
	https://github.com/nomic-ai/kompute/archive/f592b5bca3cbc169feb194218a086b18d618cca4.tar.gz -> ${P}-kompute.tar.gz
	https://github.com/nomic-ai/usearch/archive/22cfa3bd00ea542132ee826cdb220f9d6434bd43.tar.gz -> ${P}-usearch.tar.gz
	https://github.com/ashvardanian/StringZilla/archive/refs/tags/v3.9.1.tar.gz -> ${P}-stringzilla.tar.gz
"

S="${WORKDIR}/gpt4all-${PV}/${PN}"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE="nls cuda wayland"

BDEPEND="
	dev-libs/FP16
	dev-libs/libfmt
	dev-python/simsimd
	dev-util/vulkan-headers
	dev-util/vulkan-tools
	media-libs/shaderc
"

DEPEND="
	dev-qt/qt5compat:6=[qml]
	dev-qt/qtbase:6=[vulkan]
	dev-qt/qthttpserver:6=
	dev-qt/qtdeclarative:6
	dev-qt/qtshadertools:6=
	dev-qt/qttools:6=[qml]
	dev-qt/qtwebengine:6=[opengl,pdfium,qml]
	nls? ( dev-qt/qttools[linguist] )
	cuda? ( dev-util/nvidia-cuda-toolkit:= )
	wayland? ( dev-qt/qtwayland:6=[compositor] )
"

RDEPEND="
	${BDEPEND}
	${DEPEND}
"

PATCHES="
	"${FILESDIR}/${PN}-3.2.1-build_without_networking.patch"
"

pkg_setup() {
	if use cuda; then
		if ! [[ ${CUDAARCHS} ]]; then
			die "set envvar CUDAARCHS to the output of __nvcc_device_query"
		fi

		nvidia-modprobe -u || die
	fi
}

src_prepare() {
	pushd "${WORKDIR}" >&/dev/null || die

	rmdir "${WORKDIR}/gpt4all-${PV}/gpt4all-backend/llama.cpp-mainline" || die
	mv llama.cpp-*/ "${WORKDIR}/gpt4all-${PV}/gpt4all-backend/llama.cpp-mainline" || die

	rmdir "${WORKDIR}/gpt4all-${PV}/gpt4all-backend/llama.cpp-mainline/ggml/src/kompute" || die
	mv kompute-*/ "${WORKDIR}/gpt4all-${PV}/gpt4all-backend/llama.cpp-mainline/ggml/src/kompute" || die

	rmdir ${S}/usearch ||die
	mv usearch-*/ "${S}/usearch" || die

	rmdir "${S}/usearch/stringzilla" || die
	mv StringZilla-* "${S}/usearch/stringzilla" || die

	popd >&/dev/null || die

	if ! use nls ; then
		eapply "${FILESDIR}"/${PN}-3.2.1-build_without_nls.patch
	fi

	if ! use wayland ; then
		sed \
			-e "s| Qt6::WaylandCompositor||g" \
			-e "s| WaylandCompositor||g" \
			-i CMakeLists.txt || die
	fi

	cmake_src_prepare
}

src_configure() {
	if use cuda; then
		export CUDAHOSTCXX=gcc-$(cuda-config -s | tr ' ' '\n' | tail -n1)
	fi

	append-cxxflags "-Wno-dangling-reference"

	mycmakeargs=(
		-DKOMPUTE_OPT_DISABLE_VULKAN_VERSION_CHECK="yes"
		-DKOMPUTE_OPT_USE_BUILT_IN_VULKAN_HEADER="no"
		-DKOMPUTE_OPT_USE_BUILT_IN_FMT="no"
		-DKOMPUTE_OPT_USE_BUILT_IN_SPDLOG="no"
		-DQMAKE_EXECUTABLE="$(qt6_get_bindir)/qmake"
		-DLLMODEL_CUDA="$(usex cuda)"
	)
	if use cuda; then
		mycmakeargs+=(
			-DCMAKE_CUDA_ARCHITECTURES="${CUDAARCHS}"
		)
	fi

	cmake_src_configure
}

src_install() {
	local bindir="/opt/${PN}"

	# Installing libs to /usr/lib64 results in kompute not being detected properly
	echo "LD_LIBRARY_PATH=${bindir}/bin ${bindir}/bin/chat" > ${PN} || die

	insinto "${bindir}"
	doins -r "${BUILD_DIR}/bin"

	doins "${PN}"

	dodir usr/bin
	dosym -r "${bindir}"/${PN} /usr/bin/${PN}

	sed \
		-e "s|Name=.*|Name=GPT4ALL Chat|g" \
		-e "s|Exec=.*|Exec=${PN}|g" \
		-e "s|Icon=.*|Icon=${PN}|g" \
		-i  flatpak-manifest/io.gpt4all.gpt4all.desktop || die

	domenu flatpak-manifest/io.gpt4all.gpt4all.desktop
	newicon -s 64 icons/gpt4all.svg ${PN}.svg

	fperms +x "${bindir}/${PN}"
	fperms +x "${bindir}/bin/chat"
	fperms +x "${bindir}/bin/xxd"
}
