FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://updateiotedge"

do_install:append () {
  install -d ${D}${sysconfdir}/update-hooks.d
  install -m 500 ${S}/updateiotedge ${D}${sysconfdir}/update-hooks.d/90-updateiotedge
}

PACKAGES:append = " \
	${PN}-iotedge \
"

SUMMARY:${PN}-iotedge = "Initrd update hook for updating iotedge services"
RDEPENDS:${PN}-iotedge += ""
FILES:${PN}-iotedge += "${sysconfdir}/update-hooks.d/*-updateiotedge"
