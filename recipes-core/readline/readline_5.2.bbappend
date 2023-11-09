FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://inputrc"

do_install:append() {
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/inputrc ${D}${sysconfdir}/inputrc
}

FILES:${PN}:append = " ${sysconfdir}/inputrc"
