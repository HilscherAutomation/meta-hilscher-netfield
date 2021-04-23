SUMMARY = "Hilscher: netfield OEM overlay image."

require recipes-core/images/netfield-image-oem-default.bb

# Additional packages
# NOTE: cockpit-branding-default is included in base image and can be left out here
OEM_IMAGE_INSTALL += " \
"

do_oem_ovl_postinstall() {
	if [ -e "${IMAGE_ROOTFS}${nonarch_libdir}/os-release" ]; then
		# Remove old VARIANT_ID and append the new one
		sed -i "/^VARIANT_ID=/,1d" ${IMAGE_ROOTFS}${nonarch_libdir}/os-release
		echo "VARIANT_ID=\"netfield\"" >> ${IMAGE_ROOTFS}${nonarch_libdir}/os-release
	fi
}
ROOTFS_POSTPROCESS_COMMAND_append += "do_oem_ovl_postinstall;"
