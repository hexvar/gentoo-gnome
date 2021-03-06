# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6
PYTHON_COMPAT=( python3_{5,6,7} )

inherit gnome2 python-any-r1 virtualx meson

DESCRIPTION="Log messages and event viewer"
HOMEPAGE="https://wiki.gnome.org/Apps/Logs"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

RDEPEND="
	>=dev-libs/glib-2.43.90:2
	gnome-base/gsettings-desktop-schemas
	sys-apps/systemd:=
	>=x11-libs/gtk+-3.22.15:3
"
DEPEND="${RDEPEND}
	~app-text/docbook-xml-dtd-4.3
	app-text/yelp-tools
	dev-libs/appstream-glib
	dev-libs/libxslt
	>=dev-util/intltool-0.50
	gnome-base/gnome-common
	virtual/pkgconfig
	test? (
		${PYTHON_DEPS}
		$(python_gen_any_dep 'dev-util/dogtail[${PYTHON_USEDEP}]') )
"

python_check_deps() {
	use test && has_version "dev-util/dogtail[${PYTHON_USEDEP}]"
}

pkg_setup() {
	use test && python-any-r1_pkg_setup
}
