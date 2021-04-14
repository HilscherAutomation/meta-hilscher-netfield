SUMMARY = "Initialize the device data directory"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

LIC_FILES_CHKSUM = ""

RDEPENDS_${PN} = "device-data-driver coreutils net-tools"

SRC_URI = "file://device_data"

S = "${WORKDIR}"

do_install () {
  install -d ${D}/init.d
  install -m 500 ${S}/device_data ${D}/init.d/50-device_data
}

FILES_${PN} = "/init.d"
