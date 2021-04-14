FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append += "file://mqtt-config.json"

do_install_append() {
    install -d ${D}${sysconfdir}/gateway
    install -m0644 ${WORKDIR}/mqtt-config.json ${D}${sysconfdir}/gateway/
}

do_install_basefilesissue () {
    # Symlink /etc/issue to /usr/lib/issue to make sure the read only variant
    # is used which contains the real distro name and firmware version
    ln -s ${libdir}/issue ${D}${sysconfdir}/issue
    ln -s ${libdir}/issue ${D}${sysconfdir}/issue.net
}
