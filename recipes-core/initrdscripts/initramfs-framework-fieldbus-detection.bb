SUMMARY = "Find and set /var/platform links for fieldbus cards (cifX)"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

LIC_FILES_CHKSUM = ""

RDEPENDS_${PN} = "cifxhelpers cifxhelpers-read-hwinfo"

SRC_URI = "file://detect_cifx.sh \
           file://detect_cifx_setup.sh"

S = "${WORKDIR}"

do_install () {
  install -d ${D}/init.d
  install -m 500 ${S}/detect_cifx.sh ${D}/init.d/51-detect_cifx
  install -d ${D}${bindir}
  install -m 500 ${S}/detect_cifx_setup.sh ${D}${bindir}/detect_cifx_setup
}

FILES_${PN} = "/init.d ${bindir}"
