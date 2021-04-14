FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append += " \
	file://sw-selection.sh \
"

do_install_append () {
	install -d ${D}${libdir}/swupdate/conf.d
	install -m 0644 ${WORKDIR}/sw-selection.sh ${D}${libdir}/swupdate/conf.d/12-sw-selection.sh
}
