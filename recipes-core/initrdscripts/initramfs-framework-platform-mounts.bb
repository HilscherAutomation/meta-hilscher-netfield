SUMMARY = "Move mounts created by initramfs to rootfs"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

SRC_URI = "file://platform_mounts"

S = "${WORKDIR}"

do_install () {
  install -d ${D}/init.d
  install -m 500 ${S}/platform_mounts ${D}/init.d/98-platform_mounts
}

FILES_${PN} = "/init.d"
