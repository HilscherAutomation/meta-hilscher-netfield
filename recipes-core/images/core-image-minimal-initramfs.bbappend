inherit hilscher-image-check

do_rootfs[vardepsexclude] += "FIRMWARE_VERSION FULL_FW_VERSION"

INITRAMFS_SCRIPTS = " \
	initramfs-netfield \
	initramfs-module-lvm \
	initramfs-module-udev \
"

PACKAGE_INSTALL:append = " openssl-bin"
PACKAGE_INSTALL:append = " dosfstools e2fsprogs util-linux-mkfs util-linux-blkid tar grep"
PACKAGE_INSTALL:append = " lvm2 util-linux-sfdisk"

# Cosmetic tool to show progress during recovery / restore on console
PACKAGE_INSTALL:append = " pv"

# Speed up bz2 extraction
PACKAGE_INSTALL:append = " pbzip2"

# Required to re-read partition tables after deploying wic
PACKAGE_INSTALL:append = " util-linux-blockdev"

# Install fsarchiver to allow restorting backups in initramfs
PACKAGE_INSTALL:append = " fsarchiver"

# required for firmware update process
PACKAGE_INSTALL:append = " rsync"

# Add tpm tools to initramfs for provisioning tpm in production process
PACKAGE_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'tpm2', 'tpm2-tools', '', d)}"

# tools required during production
PACKAGE_INSTALL:append = " cifx-data-collector ethtool"

delete_unwanted_cifx_files() {
    # Remove unneeded cifX stuff which is pulled in by libcifx.
    rm -rf ${IMAGE_ROOTFS}/opt/cifx/deviceconfig
    rm -rf ${IMAGE_ROOTFS}/opt/cifx/FW
    rm ${IMAGE_ROOTFS}/lib/udev/rules.d/80-hilscher*
    rm ${IMAGE_ROOTFS}/etc/init.d/cifxeth
}

ROOTFS_POSTUNINSTALL_COMMAND:append = " delete_unwanted_cifx_files;"
