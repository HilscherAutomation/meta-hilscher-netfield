FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append += "file://updateiotedge"

do_install_append () {
  install -d ${D}${sysconfdir}/update-hooks.d
  install -m 500 ${S}/updateiotedge ${D}${sysconfdir}/update-hooks.d/90-updateiotedge
}

PACKAGES_append += " \
	${PN}-iotedge \
"

SUMMARY_${PN}-iotedge = "Initrd update hook for updating iotedge services"
RDEPENDS_${PN}-iotedge += ""
FILES_${PN}-iotedge += "${sysconfdir}/update-hooks.d/*-updateiotedge"
