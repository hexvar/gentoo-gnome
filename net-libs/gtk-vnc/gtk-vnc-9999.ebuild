# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-libs/gtk-vnc/gtk-vnc-0.4.3-r1.ebuild,v 1.6 2011/10/30 17:24:14 armin76 Exp $

EAPI="4"
GNOME2_LA_PUNT="yes"

inherit autotools eutils base gnome.org python
if [[ ${PV} = 9999 ]]; then
	inherit gnome2-live
fi

DESCRIPTION="VNC viewer widget for GTK"
HOMEPAGE="http://live.gnome.org/gtk-vnc"

LICENSE="GPL-2"
SLOT="0"
if [[ ${PV} = 9999 ]]; then
	KEYWORDS=""
else
	KEYWORDS="alpha amd64 ia64 ppc ppc64 sparc x86 ~x86-fbsd"
fi
IUSE="examples +gtk3 +introspection python sasl +vala"
REQUIRED_USE="vala? ( introspection )"

# libview is used in examples/gvncviewer -- no need
# TODO: review nsplugin when it will be considered less experimental

COMMON_DEPEND=">=dev-libs/glib-2.10:2
	>=net-libs/gnutls-1.4
	>=x11-libs/cairo-1.2
	>=x11-libs/gtk+-2.18:2
	x11-libs/libX11
	gtk3? ( >=x11-libs/gtk+-2.91.3:3 )
	introspection? ( >=dev-libs/gobject-introspection-0.9.4 )
	python? ( >=dev-python/pygtk-2:2 )
	sasl? ( dev-libs/cyrus-sasl )"
RDEPEND="${COMMON_DEPEND}"
DEPEND="${COMMON_DEPEND}
	>=dev-lang/perl-5
	sys-devel/gettext
	>=dev-util/intltool-0.40
	virtual/pkgconfig
	vala? (
		dev-lang/vala:0.14
		>=dev-libs/gobject-introspection-0.9.4 )"

if [[ ${PV} = 9999 ]]; then
	# Needed by src/keymap-gen.pl to autogenerate keymap .c/.h files
	# Not needed in the tarball because they're created during distcheck
	DEPEND="${DEPEND}
		dev-perl/Text-CSV"
fi

GTK2_BUILDDIR="${WORKDIR}/${P}_gtk2"
GTK3_BUILDDIR="${WORKDIR}/${P}_gtk3"

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	python_convert_shebangs -r 2 .
	mkdir "${GTK2_BUILDDIR}" || die
	mkdir "${GTK3_BUILDDIR}" || die

	# Remove a few files that were autogenerated during distcheck.
	# Having these around in srcdir breaks out of tree build since they're
	# expected to be in builddir, which is correct for trunk builds since
	# they're generated files, not source files. Funny false dichotomy.
	rm -vf "${S}"/src/{vncconnectionenums.[ch],vncdisplayenums.[ch]}

	# Fix incorrect codegendir check: h2def.py is in pygobject, not pygtk
	sed -e 's/codegendir pygtk-2.0/codegendir pygobject-2.0/g' \
		-i src/Makefile.* || die

	gnome2_src_prepare
}

src_configure() {
	local myconf
	myconf="
		$(use_with examples) \
		$(use_enable introspection) \
		$(use_with sasl) \
		$(use_enable vala) \
		VAPIGEN=$(type -P vapigen-0.14) \
		--with-coroutine=gthread \
		--without-libview \
		--disable-static"

	cd ${GTK2_BUILDDIR}
	einfo "Running configure in ${GTK2_BUILDDIR}"
	ECONF_SOURCE="${S}" econf ${myconf} \
		$(use_with python) \
		--with-gtk=2.0

	if use gtk3; then
		cd ${GTK3_BUILDDIR}
		einfo "Running configure in ${GTK3_BUILDDIR}"
		# Python support is via gobject-introspection
		# Ex: from gi.repository import GtkVnc
		ECONF_SOURCE="${S}" econf ${myconf} \
			--with-python=no \
			--with-gtk=3.0
	fi
}

src_compile() {
	cd ${GTK2_BUILDDIR}
	einfo "Running make in ${GTK2_BUILDDIR}"
	emake || die

	if use gtk3; then
		cd ${GTK3_BUILDDIR}
		einfo "Running make in ${GTK3_BUILDDIR}"
		emake || die
	fi
}

src_test() {
	cd ${GTK2_BUILDDIR}
	einfo "Running make check in ${GTK2_BUILDDIR}"
	emake check || die

	if use gtk3; then
		cd ${GTK3_BUILDDIR}
		einfo "Running make check in ${GTK3_BUILDDIR}"
		emake check || die
	fi
}

src_install() {
	dodoc AUTHORS ChangeLog NEWS README || die

	cd ${GTK2_BUILDDIR}
	einfo "Running make install in ${GTK2_BUILDDIR}"
	# bug #328273
	MAKEOPTS="${MAKEOPTS} -j1" base_src_install

	if use gtk3; then
		cd ${GTK3_BUILDDIR}
		einfo "Running make install in ${GTK3_BUILDDIR}"
		# bug #328273
		MAKEOPTS="${MAKEOPTS} -j1" base_src_install
	fi

	python_clean_installation_image

	# Remove .la files
	find "${ED}" -name '*.la' -exec rm -f '{}' + || die
}
