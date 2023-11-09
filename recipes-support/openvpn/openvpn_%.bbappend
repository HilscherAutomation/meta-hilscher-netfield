FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " \
    file://server.conf \
    file://openvpn-initial-server-config.service \
"

PACKAGES =+ "${PN}-serverconf"
RDEPENDS:${PN}:append = " ${PN}-serverconf"

SYSTEMD_PACKAGES:append = " ${PN}-serverconf"
SYSTEMD_SERVICE:${PN}-serverconf = "openvpn-initial-server-config.service"
SYSTEMD_AUTO_ENABLE:${PN}-serverconf = "enable"

do_install:append() {
    install -d ${D}${sysconfdir}/openvpn/
    install -m 0644 ${WORKDIR}/server.conf ${D}${sysconfdir}/openvpn/
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/openvpn-initial-server-config.service ${D}${systemd_system_unitdir}
}

FILES:${PN}-serverconf = "\
    ${sysconfdir}/openvpn/server.conf \
    ${systemd_system_unitdir}/openvpn-initial-server-config.service \
"
