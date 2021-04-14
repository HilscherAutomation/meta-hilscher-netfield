SUMMARY = "Initrd restore backup scripts for Hilscher netX devices"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

RDEPENDS_${PN} = "fsarchiver"

SRC_URI = "file://restore_backup"

S = "${WORKDIR}"

do_install () {
  install -d ${D}/init.d
  install -m 500 ${S}/restore_backup ${D}/init.d/16-restore_backup
}

FILES_${PN} = "/init.d/*"
