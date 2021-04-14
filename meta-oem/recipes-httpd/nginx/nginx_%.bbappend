FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

do_install_prepend_oem() {
	sed -i "s,\( *server_name *\).*,\1${VENDOR_NAME} - ${VENDOR_DEVICE_DESC};," ${WORKDIR}/nginx.conf
}

PACKAGES_prepend_oem-ovl += "${PN}-oem-ovl "
FILES_${PN}-oem-ovl_oem-ovl = "${sysconfdir}/nginx/nginx.conf"
CONFFILES_${PN}-oem-ovl_oem-ovl = "${sysconfdir}/nginx/nginx.conf"
