SUMMARY="Firewalld provides a dynamically managed firewall with support for network/firewall zones that define the trust level of network connections or interfaces"
HOMEPAGE="https://firewalld.org/"
LICENSE="GPL-2.0-only"

LIC_FILES_CHKSUM="file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

SRC_URI = "https://github.com/${BPN}/${BPN}/releases/download/v${PV}/${BPN}-${PV}.tar.gz"
SRC_URI[sha256sum] = "d8c64540039a7a5cbda7999aaa4426495a1d8dc32504439d977e80f4f16ae31c"

S="${WORKDIR}/${BPN}-${PV}"

DEPENDS = "intltool-native gettext-native glib-2.0-native \
           docbook-xml-dtd4-native docbook-xsl-stylesheets-native libxslt-native xmlto-native \
"
inherit autotools-brokensep systemd pkgconfig

EXTRA_OECONF = " \
  --with-iptables=${sbindir}/iptables --with-iptables-restore=${sbindir}/iptables-restore \
  --with-ip6tables=${sbindir}/ip6tables --with-ip6tables-restore=${sbindir}/ip6tables-restore \
  --with-ebtables=${base_sbindir}/ebtables --with-ebtables-restore=${base_sbindir}/ebtables-restore \
  --with-ipset=${sbindir}/ipset \
  --with-systemd-unitdir=${systemd_system_unitdir} \
  PYTHON=python3 \
  --with-xml-catalog=${STAGING_ETCDIR_NATIVE}/xml/catalog \
"

PACKAGECONFIG ??= "nftables"
PACKAGECONFIG[nftables]=",,,nftables"

inherit python3native
RDEPENDS:${PN}= "python3 python3-core python3-dbus python3-slip-dbus python3-decorator python3-pygobject python3-six \
 nftables-python iptables ebtables ipset bash"

SYSTEMD_PACKAGES="${PN}"
SYSTEMD_SERVICE:${PN} = "firewalld.service"

PACKAGES =+ "${PN}-applet"

FILES:${PN}-applet = "${datadir}/icons  ${datadir}/glib-2.0 ${sysconfdir}/firewall/ ${sysconfdir}/xdg ${bindir}/firewall-applet ${bindir}/firewall-config"
RDEPENDS:${PN}-applet = "python3"
FILES:${PN} += "${PYTHON_SITEPACKAGES_DIR} ${datadir}"

do_install:append() {
    for file in ${D}${bindir}/* ${D}${sbindir}/*; do
        sed -i -e '1s@.*@#!/usr/bin/env python3@' $file
    done

    # Remove service file for cockpit which is also supplied by cockpit
    rm ${D}${libdir}/${PN}/services/cockpit.xml
}
