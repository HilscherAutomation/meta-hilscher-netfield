# ------------------------------------------------------------------------------
# Preconfigured oem base defines
VENDOR_NAME ??= "TBD-by-OEM"
VENDOR_URL ??= "TBD-by-OEM"

VENDOR_DEVICE_NAME ??= "TBD-by-OEM"
VENDOR_DEVICE_DESC ??= "TBD-by-OEM"
VENDOR_DEVICE_REV ?= "TBD-by-OEM"
VENDOR_DEVICE_URL ??= "TBD-by-OEM"

VENDOR_UPNP_DEVICE_TYPE ??= "TBD-by-OEM"

VENDOR_OS_ID ??= "TBD-by-OEM"
VENDOR_OS_NAME ??= "TBD-by-OEM"

# NOTE: Currently unused
VENDOR_OUI ??= "TBD-by-OEM"
VENDOR_DEVICE_PN ??= "TBD-by-OEM"
# ------------------------------------------------------------------------------

do_oem_base_definitions() {
    # login screen
    sed -e "s,netFIELD OS,${VENDOR_OS_NAME},g" \
        -e "s,@MACHINE@,$(echo ${VENDOR_DEVICE_NAME} | tr [a-z] [A-Z]),g" \
        -i ${IMAGE_ROOTFS}${libdir}/issue

    # os-release
    sed -e 's@^ID.*@ID="${VENDOR_OS_ID}"@g' \
        -e 's@^NAME.*@NAME="${VENDOR_OS_NAME}"@g' \
        -i ${IMAGE_ROOTFS}${libdir}/os-release
    # Remove old VARIANT_ID anmd append the new one
    sed '/^VARIANT_ID/,1d' -i ${IMAGE_ROOTFS}${libdir}/os-release
    echo "VARIANT_ID=\"${VENDOR_VARIANT_ID}\"" >> ${IMAGE_ROOTFS}${libdir}/os-release

    # upnp
    sed -e "s,\(<deviceType>\).*\(</deviceType>\),\1${VENDOR_UPNP_DEVICE_TYPE}\2," \
        -e "s,\(<manufacturer>\).*\(</manufacturer>\),\1${VENDOR_NAME}\2," \
        -e "s,\(<manufacturerURL>\).*\(</manufacturerURL>\),\1${VENDOR_URL}\2," \
        -e "s,\(<modelDescription>\).*\(</modelDescription>\),\1${VENDOR_DEVICE_DESC}\2," \
        -e "s,\(<modelName>\).*\(</modelName>\),\1${VENDOR_DEVICE_NAME}\2," \
        -e "s,\(<modelNumber>\).*\(</modelNumber>\),\1${VENDOR_DEVICE_REV}\2," \
        -e "s,\(<modelURL>\).*\(</modelURL\),\1${VENDOR_DEVICE_URL}\2," \
        -i ${IMAGE_ROOTFS}/opt/upnpd/netiotdevicedesc.xml

    # nginx
    sed -e "s,\( *server_name *\).*,\1${VENDOR_NAME} - ${VENDOR_DEVICE_DESC};," \
        -i ${IMAGE_ROOTFS}${sysconfdir}/nginx/nginx.conf
}

ROOTFS_POSTUNINSTALL_COMMAND_append += " do_oem_base_definitions ;"
