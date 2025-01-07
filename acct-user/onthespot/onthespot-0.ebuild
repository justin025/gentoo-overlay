# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for the system wide media-sound/onthespot server"
ACCT_USER_ID=534
ACCT_USER_HOME=/var/lib/onthespot
ACCT_USER_HOME_PERMS=0750
ACCT_USER_GROUPS=( onthespot )

acct-user_add_deps
