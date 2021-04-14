SUMMARY = "Platform initialization"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

LIC_FILES_CHKSUM = ""

SRC_URI = "file://platform_init"

# Platform init is always machine specific
PACKAGE_ARCH="${MACHINE_ARCH}"

S = "${WORKDIR}"

do_install () {
  install -d ${D}/init.d
  install -m 500 ${S}/platform_init ${D}/init.d/00-platform_init
}

FILES_${PN} = "/init.d/*"
