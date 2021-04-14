FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI_append += "file://json-c-compatibility.patch"

FILES_${PN}_append += "${libdir}/tmpfiles.d/cryptsetup.conf"
