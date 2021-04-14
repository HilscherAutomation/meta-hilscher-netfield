FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI_append += " \
    file://server.conf \
    file://openvpn-initial-server-config.service \
"

PACKAGES =+ "${PN}-serverconf"
RDEPENDS_${PN}_append += "${PN}-serverconf"

SYSTEMD_PACKAGES_append += "${PN}-serverconf"
SYSTEMD_SERVICE_${PN}-serverconf = "openvpn-initial-server-config.service"
SYSTEMD_AUTO_ENABLE_${PN}-serverconf = "enable"

do_install_append() {
    install -d ${D}${sysconfdir}/openvpn/
    install -m 0644 ${WORKDIR}/server.conf ${D}${sysconfdir}/openvpn/
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/openvpn-initial-server-config.service ${D}${systemd_system_unitdir}
}

FILES_${PN}-serverconf = "\
    ${sysconfdir}/openvpn/server.conf \
    ${systemd_system_unitdir}/openvpn-initial-server-config.service \
"
