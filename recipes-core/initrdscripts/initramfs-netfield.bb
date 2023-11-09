SUMMARY = "Modular initramfs support for netFIELD-OS devices."
LICENSE = "CLOSED"

RDEPENDS:${PN} += "initramfs-framework-base"

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
	install -m 0755 ${WORKDIR}/update_hooks_pre_overlayfs ${D}/init.d/93-update_hooks_pre_overlayfs
	install -m 0755 ${WORKDIR}/overlayfs ${D}/init.d/94-overlayfs
	install -m 0755 ${WORKDIR}/update_hooks_post_overlayfs ${D}/init.d/95-update_hooks_post_overlayfs
}

PACKAGES = " \
	${PN} \
	${PN}-base \
	${PN}-netfield-init \
	${PN}-platform-init \
	${PN}-initrd-api\
	${PN}-factory-default-reset \
	${PN}-backup-restore \
	${PN}-device-data \
	${PN}-detect-cifx \
	${PN}-provisioning \
	${PN}-oemfs \
	${PN}-update-hooks \
	${PN}-overlayfs \
"

SUMMARY:${PN}-netfield-init = "Modular initramfs support for the netfield-os (base-components)"
RRECOMMENDS:${PN}-base += ""
FILES:${PN}-base += "/init.d/*-macros_hooks"

SUMMARY:${PN}-netfield-init = "Modular initramfs support for generic netfield initialization."
RDEPENDS:${PN}-netfield-init += "${PN}-base pub-key-loader device-data-driver e2fsprogs-e2fsck util-linux-lsblk file-signature"
FILES:${PN}-netfield-init += "/init.d/*-netfield_init"

SUMMARY:${PN}-platform-init = "Modular initramfs support for platform initialization."
RDEPENDS:${PN}-platform-init += "${PN}-base"
FILES:${PN}-platform-init += "/init.d/*-platform_init"

SUMMARY:${PN}-initrd-api = "Modular initramfs support for intrd-api."
RDEPENDS:${PN}-initrd-api += "${PN}-base file-signature"
# NOTE: The dependencies below are required by the "Initial-Device-Partition-Manager" (initrd-api-part-cfg.bb).
RDEPENDS:${PN}-initrd-api += "dosfstools e2fsprogs-e2fsck e2fsprogs-resize2fs e2fsprogs-mke2fs util-linux-sfdisk"
FILES:${PN}-initrd-api += "/init.d/*-initrd_api"

SUMMARY:${PN}-factory-default-reset = "Modular initramfs support for factory_default_reset."
RDEPENDS:${PN}-factory-default-reset += "${PN}-base"
FILES:${PN}-factory-default-reset += "/init.d/*-factory_default_reset"

SUMMARY:${PN}-backup-restore = "Modular initramfs support for backup_restore."
RDEPENDS:${PN}-backup-restore += "${PN}-base fsarchiver"
FILES:${PN}-backup-restore += "/init.d/*-backup_restore"

SUMMARY:${PN}-device-data = "Modular initramfs support for providing device data (device-label)."
RDEPENDS:${PN}-device-data += "${PN}-base coreutils net-tools"
FILES:${PN}-device-data += "/init.d/*-device_data"

SUMMARY:${PN}-detect-cifx = "Modularinitramfs support for cifx card detection."
RDEPENDS:${PN}-detect-cifx += "${PN}-base cifxhelpers cifxhelpers-read-hwinfo"
FILES:${PN}-detect-cifx = "/init.d/*-detect_cifx ${bindir}/detect_cifx_setup"

SUMMARY:${PN}-provisioning = "Modular initramfs support for manufacturing processes."
RDEPENDS:${PN}-provisioning += "${PN}-base nfs-utils-mount"
FILES:${PN}-provisioning += "/init.d/*-provisioning /init.d/functions"

SUMMARY:${PN}-oemfs = "Modular initramfs support for oemfs."
RDEPENDS:${PN}-oemfs += "${PN}-base"
FILES:${PN}-oemfs += "/init.d/*-oemfs"

SUMMARY:${PN}-update-hooks = "Modular initramfs support for update_hooks."
RDEPENDS:${PN}-update-hooks += "${PN}-base initramfs-update-hooks"
FILES:${PN}-update-hooks += "/init.d/*-update_hooks*"

SUMMARY:${PN}-overlayfs = "Modular initramfs support for overlayfs."
RDEPENDS:${PN}-overlayfs += "${PN}-base"
FILES:${PN}-overlayfs += "/init.d/*-overlayfs"

# This package references all other packages so that it can be used as a wrapper.
ALLOW_EMPTY:${PN} = "1"
RRECOMMENDS:${PN} += "${PACKAGES}"
FILES:${PN} = ""
