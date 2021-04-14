FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

do_install_prepend_oem() {
	sed -i "s,\(<deviceType>\).*\(</deviceType>\),\1${VENDOR_UPNP_DEVICE_TYPE}\2," ${WORKDIR}/netiotdevicedesc.xml

	sed -i "s,\(<manufacturer>\).*\(</manufacturer>\),\1${VENDOR_NAME}\2," ${WORKDIR}/netiotdevicedesc.xml
	sed -i "s,\(<manufacturerURL>\).*\(</manufacturerURL>\),\1${VENDOR_URL}\2," ${WORKDIR}/netiotdevicedesc.xml
	sed -i "s,\(<modelDescription>\).*\(</modelDescription>\),\1${VENDOR_DEVICE_DESC}\2," ${WORKDIR}/netiotdevicedesc.xml
	sed -i "s,\(<modelName>\).*\(</modelName>\),\1${VENDOR_DEVICE_NAME}\2," ${WORKDIR}/netiotdevicedesc.xml
	sed -i "s,\(<modelNumber>\).*\(</modelNumber>\),\1${VENDOR_DEVICE_REV}\2," ${WORKDIR}/netiotdevicedesc.xml
	sed -i "s,\(<modelURL>\).*\(</modelURL\),\1${VENDOR_DEVICE_URL}\2," ${WORKDIR}/netiotdevicedesc.xml
}

PACKAGES_prepend_oem-ovl += "${PN}-oem-ovl "
FILES_${PN}-oem-ovl_oem-ovl = "/opt/upnpd/netiotdevicedesc.xml /opt/upnpd/desc"
