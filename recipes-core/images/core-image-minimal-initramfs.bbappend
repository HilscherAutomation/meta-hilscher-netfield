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

######################################################
# tools required during production
######################################################

PACKAGE_INSTALL:append = " cifx-data-collector ethtool "

# tpm tools require more than the default 128kB initramfs
INITRAMFS_MAXSIZE ?= "139264"

# tpm2-tools           -> tpm2_dictionarylockout
# libtss2-tcti-device  -> tpm2-tools 'device' access
# tpm2-abrmd           -> libtss2-tcti-tabrmd.so
# opensc               -> pkcs11-tool
# tpm2-pkcs11          -> pkcs11 module (libtpm2_pkcs11.so)
TPM_PROV_TOOLS = "jq tpm2-tools opensc tpm2-pkcs11 libtss2-tcti-device openssl-pkcs11-provider ${@bb.utils.contains('IMAGE_FEATURES', 'debug-tweaks', 'swtpm', '', d)}"

PACKAGE_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'tpm2', '${TPM_PROV_TOOLS}', '', d)} "

######################################################

delete_unwanted_cifx_files() {
    # Remove unneeded cifX stuff which is pulled in by libcifx.
    rm -rf ${IMAGE_ROOTFS}/opt/cifx/deviceconfig
    rm -rf ${IMAGE_ROOTFS}/opt/cifx/FW
    rm ${IMAGE_ROOTFS}/lib/udev/rules.d/80-hilscher*
    rm ${IMAGE_ROOTFS}${sbindir}/cifxeth
}

add_etc_target() {
    # Add /etc/target to get rid of kernel warning:
    #   "cannot open /etc/target"
    mkdir -p ${IMAGE_ROOTFS}/etc/target
}

ROOTFS_POSTUNINSTALL_COMMAND:append = " delete_unwanted_cifx_files;add_etc_target;"
