SUMMARY = "Initrd update hook for synchronizing ca certificate updates"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

SRC_URI = "file://updateca"

inherit allarch

S = "${WORKDIR}"

do_install () {
  install -d ${D}${sysconfdir}/update-hooks.d
  install -m 500 ${S}/updateca ${D}${sysconfdir}/update-hooks.d/
}

FILES_${PN} = "${sysconfdir}/update-hooks.d"
