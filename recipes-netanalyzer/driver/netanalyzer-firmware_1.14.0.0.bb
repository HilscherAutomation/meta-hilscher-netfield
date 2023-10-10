SUMMARY = "netANALYZER firmware for Hilscher netANALYZER devices"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

require driver_version.inc
PV="1.14.0.0"

S .= "firmware"

inherit allarch

do_install() {
  install -d ${D}/lib/firmware/netanalyzer/
  cp -r ${S}/* ${D}/lib/firmware/netanalyzer/
}

PACKAGES="${PN}"
FILES_${PN}="/lib"
