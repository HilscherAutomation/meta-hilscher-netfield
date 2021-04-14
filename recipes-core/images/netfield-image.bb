DESCRIPTION = "netFIELD IoT base image"

inherit core-image

require hilscher-packages.inc

do_adjust_fstab() {
    sed -i -e '/^[#[:space:]]*\/dev\/root/{s/defaults/ro/;s/\([[:space:]]*[[:digit:]]\)\([[:space:]]*\)[[:digit:]]$/\1\20/}' ${IMAGE_ROOTFS}/etc/fstab
}

do_create_platform_dir() {
   install -d ${IMAGE_ROOTFS}/var/platform
   install -d ${IMAGE_ROOTFS}/usr/local
}
ROOTFS_POSTUNINSTALL_COMMAND_append += "${@bb.utils.contains('NETIOT_ROOT_OVERLAY', '1', '', 'do_create_platform_dir ; do_adjust_fstab ; ', d)}"
