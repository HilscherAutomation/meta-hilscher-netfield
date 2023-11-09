FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
	file://sw-selection.sh \
"

do_install:append () {
	install -d ${D}${libdir}/swupdate/conf.d
	install -m 0644 ${WORKDIR}/sw-selection.sh ${D}${libdir}/swupdate/conf.d/12-sw-selection.sh
}

PACKAGES:prepend = "${PN}-oem "
FILES:${PN}-oem = "${libdir}/swupdate/conf.d/12-sw-selection.sh"
