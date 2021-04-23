SUMMARY = "Initrd update hook for synchronizing users from update to live system"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

SRC_URI = "file://updateuser"

inherit allarch

S = "${WORKDIR}"

do_install () {
  install -d ${D}${sysconfdir}/update-hooks.d
  install -m 500 ${S}/updateuser ${D}${sysconfdir}/update-hooks.d/
}

FILES_${PN} = "${sysconfdir}/update-hooks.d"
