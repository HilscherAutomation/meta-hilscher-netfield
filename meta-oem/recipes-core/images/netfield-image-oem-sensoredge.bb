SUMMARY = "Hilscher: netfield OEM overlay image."

require recipes-core/images/netfield-image-oem-default.bb

# Additional packages
OEM_IMAGE_INSTALL += " \
    cockpit-branding-netfield-sensoredge \
    cockpit-oem-ovl-remove-docker \
    cockpit-oem-ovl-remove-general-settings \
    cockpit-oem-ovl-remove-iotedge-docker \
    cockpit-oem-ovl-remove-networkservices \
    cockpit-oem-ovl-remove-onboarding \
    cockpit-oem-ovl-remove-terminal \
"

do_oem_ovl_postinstall() {
	if [ -e "${IMAGE_ROOTFS}${nonarch_libdir}/os-release" ]; then
		# Remove old VARIANT_ID and append the new one
		sed -i "/^VARIANT_ID=/,1d" ${IMAGE_ROOTFS}${nonarch_libdir}/os-release
		echo "VARIANT_ID=\"sensoredge\"" >> ${IMAGE_ROOTFS}${nonarch_libdir}/os-release
	fi
}
ROOTFS_POSTPROCESS_COMMAND_append += "do_oem_ovl_postinstall;"
