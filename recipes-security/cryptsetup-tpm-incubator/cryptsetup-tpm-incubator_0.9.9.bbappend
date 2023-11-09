FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://json-c-compatibility.patch"

FILES:${PN}:append = " ${libdir}/tmpfiles.d/cryptsetup.conf"
