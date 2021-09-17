SUMMARY = "Initrd reset device to factory settings"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

SRC_URI = "file://factory_reset"

S = "${WORKDIR}"

do_install () {
  install -d ${D}/init.d
  install -m 500 ${S}/factory_reset ${D}/init.d/14-factory_reset
}

FILES_${PN} = "/init.d/*"
