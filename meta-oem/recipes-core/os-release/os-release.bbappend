ID_oem = "${VENDOR_OS_ID}"
NAME_oem = "${VENDOR_OS_NAME}"

PACKAGES_prepend_oem-ovl += "${PN}-oem-ovl "
FILES_${PN}-oem-ovl_oem-ovl = "${nonarch_libdir}/os-release"
