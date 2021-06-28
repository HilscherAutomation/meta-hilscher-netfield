SUMMARY = "Initrd update hook for updating iotedge services"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

SRC_URI = "file://updateiotedge"

inherit allarch

S = "${WORKDIR}"

do_install () {
  install -d ${D}${sysconfdir}/update-hooks.d
  install -m 500 ${S}/updateiotedge ${D}${sysconfdir}/update-hooks.d/
}

FILES_${PN} = "${sysconfdir}/update-hooks.d"
