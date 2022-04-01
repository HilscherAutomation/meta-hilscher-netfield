SUMMARY = "Modular initramfs support for netFIELD-OS devices."
LICENSE = "CLOSED"

RDEPENDS_${PN} += "initramfs-framework-base"

SRC_URI = " \
	file://macros_hooks \
	file://netfield_init \
	file://initrd_api \
	file://factory_default_reset \
	file://backup_restore \
	file://platform_init \
	file://device_data \
	file://detect_cifx file://detect_cifx_setup \
	file://provisioning file://functions \
	file://oemfs \
	file://platform_mount \
	file://update_hooks_pre_overlayfs file://update_hooks_post_overlayfs \
	file://overlayfs \
"

do_install() {
	install -d ${D}/init.d

	install -m 0755 ${WORKDIR}/macros_hooks ${D}/init.d/00-macros_hooks

	install -m 0755 ${WORKDIR}/netfield_init ${D}/init.d/10-netfield_init
	install -m 0755 ${WORKDIR}/platform_init ${D}/init.d/11-platform_init
	install -m 0755 ${WORKDIR}/initrd_api ${D}/init.d/12-initrd_api
	install -m 0755 ${WORKDIR}/factory_default_reset ${D}/init.d/13-factory_default_reset
	install -m 0755 ${WORKDIR}/backup_restore ${D}/init.d/14-backup_restore
	install -m 0755 ${WORKDIR}/device_data ${D}/init.d/15-device_data
	install -m 0755 ${WORKDIR}/detect_cifx ${D}/init.d/16-detect_cifx
	install -d ${D}${bindir}
	install -m 0755 ${WORKDIR}/detect_cifx_setup ${D}${bindir}/detect_cifx_setup
	install -m 0755 ${WORKDIR}/provisioning ${D}/init.d/17-provisioning
	install -m 0755 ${WORKDIR}/functions ${D}/init.d/functions

	install -m 0755 ${WORKDIR}/oemfs ${D}/init.d/91-oemfs
	install -m 0755 ${WORKDIR}/platform_mount ${D}/init.d/92-platform_mount
	install -m 0755 ${WORKDIR}/update_hooks_pre_overlayfs ${D}/init.d/93-update_hooks_pre_overlayfs
	install -m 0755 ${WORKDIR}/overlayfs ${D}/init.d/94-overlayfs
	install -m 0755 ${WORKDIR}/update_hooks_post_overlayfs ${D}/init.d/95-update_hooks_post_overlayfs
}

PACKAGES = " \
	${PN}-netfield-init \
	${PN}-platform-init \
	${PN}-initrd-api\
	${PN}-factory-default-reset \
	${PN}-backup-restore \
	${PN}-device-data \
	${PN}-detect-cifx \
	${PN}-provisioning \
	${PN}-oemfs \
	${PN}-platform-mounts \
	${PN}-update-hooks \
	${PN}-overlayfs \
	\
	${PN}-base \
"

SUMMARY_${PN}-netfield-init = "Modular initramfs support for generic netfield initialization."
RDEPENDS_${PN}-netfield-init += "${PN}-base pub-key-loader device-data-driver e2fsprogs-e2fsck util-linux-lsblk file-signature"
FILES_${PN}-netfield-init += "/init.d/*-netfield_init"

SUMMARY_${PN}-platform-init = "Modular initramfs support for platform initialization."
RDEPENDS_${PN}-platform-init += "${PN}-base"
FILES_${PN}-platform-init += "/init.d/*-platform_init"

SUMMARY_${PN}-initrd-api = "Modular initramfs support for intrd-api."
RDEPENDS_${PN}-initrd-api += "${PN}-base file-signature"
# NOTE: The dependencies below are required by the "Initial-Device-Partition-Manager" (initrd-api-part-cfg.bb).
RDEPENDS_${PN}-initrd-api += "dosfstools e2fsprogs-e2fsck e2fsprogs-resize2fs e2fsprogs-mke2fs util-linux-sfdisk"
FILES_${PN}-initrd-api += "/init.d/*-initrd_api"

SUMMARY_${PN}-factory-default-reset = "Modular initramfs support for factory_default_reset."
RDEPENDS_${PN}-factory-default-reset += "${PN}-base"
FILES_${PN}-factory-default-reset += "/init.d/*-factory_default_reset"

SUMMARY_${PN}-backup-restore = "Modular initramfs support for backup_restore."
RDEPENDS_${PN}-backup-restore += "${PN}-base fsarchiver"
FILES_${PN}-backup-restore += "/init.d/*-backup_restore"

SUMMARY_${PN}-device-data = "Modular initramfs support for providing device data (device-label)."
RDEPENDS_${PN}-device-data += "${PN}-base coreutils net-tools"
FILES_${PN}-device-data += "/init.d/*-device_data"

SUMMARY_${PN}-detect-cifx = "Modularinitramfs support for cifx card detection."
RDEPENDS_${PN}-detect-cifx += "${PN}-base cifxhelpers cifxhelpers-read-hwinfo"
FILES_${PN}-detect-cifx = "/init.d/*-detect_cifx ${bindir}/detect_cifx_setup"

SUMMARY_${PN}-provisioning = "Modular initramfs support for manufacturing processes."
RDEPENDS_${PN}-provisioning += "${PN}-base nfs-utils-mount"
FILES_${PN}-provisioning += "/init.d/*-provisioning /init.d/functions"

SUMMARY_${PN}-oemfs = "Modular initramfs support for oemfs."
RDEPENDS_${PN}-oemfs += "${PN}-base"
FILES_${PN}-oemfs += "/init.d/*-oemfs"

SUMMARY_${PN}-platfrom-mount = "Modular initramfs support for platform-mount."
RDEPENDS_${PN}-platfrom-mount += "${PN}-base"
FILES_${PN}-platfrom-mount += "/init.d/*-platfrom_mount"

SUMMARY_${PN}-update-hooks = "Modular initramfs support for update_hooks."
RDEPENDS_${PN}-update-hooks += "${PN}-base"
FILES_${PN}-update-hooks += "/init.d/*-update_hooks*"

SUMMARY_${PN}-overlayfs = "Modular initramfs support for overlayfs."
RDEPENDS_${PN}-overlayfs += "${PN}-base"
FILES_${PN}-overlayfs += "/init.d/*-overlayfs"

# Put all remaining files into the base package.
ALLOW_EMPTY_${PN}-base = "1"
RRECOMMENDS_${PN}-base += "${PACKAGES}"
FILES_${PN}-base = "/"
