do_install_prepend_oem() {
	[ ! -e ${WORKDIR}/issue.orig ] && cp ${WORKDIR}/issue ${WORKDIR}/issue.orig
	cp ${WORKDIR}/issue.orig ${WORKDIR}/issue

    sed -i "s,netFIELD OS,${VENDOR_OS_NAME},g" ${WORKDIR}/issue
	sed -i -e "s,@MACHINE@,$(echo ${VENDOR_DEVICE_NAME} | tr [a-z] [A-Z]),g" ${WORKDIR}/issue
}

PACKAGES_prepend_oem-ovl += "${PN}-oem-ovl "
FILES_${PN}-oem-ovl_oem-ovl = "${libdir}/issue"
