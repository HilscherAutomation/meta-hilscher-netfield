FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI_append += "file://inputrc"

do_install_append() {
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/inputrc ${D}${sysconfdir}/inputrc
}

FILES_${PN}_append += "${sysconfdir}/inputrc"
