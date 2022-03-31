inherit hilscher-image-check

do_rootfs[vardepsexclude] += "FIRMWARE_VERSION FULL_FW_VERSION"

INITRAMFS_SCRIPTS = " \
	initramfs-framework-base \
	initramfs-netfield-base \
	initramfs-module-lvm \
	initramfs-module-udev \
"

PACKAGE_INSTALL_append += "openssl-bin"
PACKAGE_INSTALL_append += "dosfstools e2fsprogs util-linux-mkfs util-linux-blkid tar grep"
PACKAGE_INSTALL_append += "lvm2 util-linux-sfdisk"

# Cosmetic tool to show progress during recovery / restore on console
PACKAGE_INSTALL_append += "pv"

# Speed up bz2 extraction
PACKAGE_INSTALL_append += "pbzip2"

# Required to re-read partition tables after deploying wic
PACKAGE_INSTALL_append += "util-linux-blockdev"

# Install fsarchiver to allow restorting backups in initramfs
PACKAGE_INSTALL_append += "fsarchiver"

# required for firmware update process
PACKAGE_INSTALL_append += "rsync"

delete_unwanted_cifx_files() {
    # Remove unneeded cifX stuff which is pulled in by libcifx. Also remove plugins as we don't want SPI devices here
    rm -rf ${IMAGE_ROOTFS}/opt/cifx/deviceconfig
    rm -rf ${IMAGE_ROOTFS}/opt/cifx/FW
    rm -rf ${IMAGE_ROOTFS}/opt/cifx/plugins
    rm ${IMAGE_ROOTFS}/lib/udev/rules.d/80-hilscher*
    rm ${IMAGE_ROOTFS}/etc/init.d/cifxeth
}

ROOTFS_POSTUNINSTALL_COMMAND_append += " delete_unwanted_cifx_files;"
