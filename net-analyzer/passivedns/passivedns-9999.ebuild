# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="A network sniffer that logs all DNS server replies for use in a passive DNS setup"
HOMEPAGE="https://github.com/gamelinux/passivedns/ https://gamelinux.org/"

EGIT_REPO_URI="https://github.com/gamelinux/passivedns.git"

LICENSE=""
SLOT="0"
KEYWORDS="amd64"

RDEPEND="
	net-libs/ldns
	net-libs/libpcap
"

src_compile() {
	autoreconf --install || die
	./configure --enable-json || die
	emake
}
src_install() {
	insinto /usr/bin
	doins src/passivedns

	fperms +x /usr/bin/passivedns
}
