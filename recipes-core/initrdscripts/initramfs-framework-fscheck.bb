SUMMARY = "Initrd TODO scripts for Hilscher netX devices"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

RDEPENDS_${PN} = "e2fsprogs-e2fsck util-linux-lsblk"

SRC_URI = "file://check_fs"

S = "${WORKDIR}"

do_install () {
  install -d ${D}/init.d
  install -m 500 ${S}/check_fs ${D}/init.d/15-check_fs
}

FILES_${PN} = "/init.d/*"
