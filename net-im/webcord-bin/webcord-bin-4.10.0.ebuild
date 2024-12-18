# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="
        af am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he
        hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr
        sv sw ta te th tr uk ur vi zh-CN zh-TW
"

inherit chromium-2 desktop xdg unpacker

DESCRIPTION="A Discord and SpaceBar electron-based client implemented without Discord API"
HOMEPAGE="https://github.com/SpacingBat3/WebCord/"
SRC_URI="https://github.com/SpacingBat3/WebCord/releases/download/v4.10.0/webcord_${PV}_${ARCH}.deb -> ${P}.deb"

S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* amd64 ~arm64"

QA_PREBUILT="*"

pkg_setup() {
        chromium_suid_sandbox_check_kernel_config
}

src_prepare() {
        default
        # cleanup languages
        pushd "usr/lib/webcord/locales" > /dev/null || die
        chromium_remove_language_paks
        popd > /dev/null || die
}

src_install() {
	insinto /opt
	doins -r "usr/lib/webcord"

	dosym /opt/webcord/webcord /usr/bin/webcord

	domenu usr/share/applications/webcord.desktop
	newicon -s 512 usr/share/pixmaps/webcord.png webcord.png

	fperms +x /opt/webcord/webcord
}
