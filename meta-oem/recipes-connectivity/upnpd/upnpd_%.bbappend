FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append += "file://oem-logo.png file://netfield-logo.png"

do_install_append() {
    install -m 0644 ${WORKDIR}/oem-logo.png ${D}/opt/upnpd/desc/
    install -m 0644 ${WORKDIR}/netfield-logo.png ${D}/opt/upnpd/desc/
}

pkg_postinst_${PN}-oem () {
    mv $D/opt/upnpd/desc/oem-logo.png $D/opt/upnpd/desc/logo.png
}

pkg_postinst_${PN}-oem-hilscher () {
    mv $D/opt/upnpd/desc/netfield-logo.png $D/opt/upnpd/desc/logo.png
}

PACKAGES =+ "${PN}-oem ${PN}-oem-hilscher"
FILES_${PN}-oem = "/opt/upnpd/desc/oem-logo.png"
FILES_${PN}-oem-hilscher = "/opt/upnpd/desc/netfield-logo.png"
