do_oem_base_definitions() {
    # login screen
    sed -e "s,netFIELD OS,${VENDOR_OS_NAME},g" \
        -e "s,@MACHINE@,$(echo ${VENDOR_DEVICE_NAME} | tr [a-z] [A-Z]),g" \
        -i ${IMAGE_ROOTFS}${libdir}/issue

    # os-release
    sed -e 's@^ID.*@ID="${VENDOR_OS_ID}"@g' \
        -e 's@^NAME.*@NAME="${VENDOR_OS_NAME}"@g' \
        -i ${IMAGE_ROOTFS}${libdir}/os-release

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
# Make sure to no pull in base-passwd and shadow
EXTRA_USERS_PARAMS=""
do_force_admin_pw_change() {
    :
}

do_create_homes() {
    :
}
# Prevent adjustment of fstab in oem overlays
do_adjust_fstab() {
    :
}

do_create_platform_dir() {
    :
}

# Prevent /fw_version symlink in overlay
do_install_manifest() {
    :
}
