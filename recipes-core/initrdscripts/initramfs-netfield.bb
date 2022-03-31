SUMMARY = "Modular initramfs support for netFIELD-OS devices."
LICENSE = "CLOSED"

RDEPENDS_${PN} += "initramfs-framework-base"

#PR = "r4"

#inherit allarch

SRC_URI = " \
	file://platform_init \
	file://owner_cert \
	file://initrd_api \
	file://provisioning file://functions \
	file://factory_reset \
	file://check_fs \
	file://restore_backup \
	file://boot_cfg \
	file://device_data \
	file://detect_cifx file://detect_cifx_setup \
"

S = "${WORKDIR}"

do_install() {
	install -d ${D}/init.d

	install -m 0755 ${WORKDIR}/platform_init ${D}/init.d/00-platform_init
	install -m 0755 ${WORKDIR}/owner_cert ${D}/init.d/01-owner_cert
	install -m 0755 ${WORKDIR}/initrd_api ${D}/init.d/10-initrd_api
	install -m 0755 ${WORKDIR}/provisioning ${D}/init.d/11-provisioning
	install -m 0755 ${WORKDIR}/functions ${D}/init.d/functions
	install -m 0755 ${WORKDIR}/factory_reset ${D}/init.d/14-factory_reset
	install -m 0755 ${WORKDIR}/check_fs ${D}/init.d/15-check_fs
	install -m 0755 ${WORKDIR}/restore_backup ${D}/init.d/16-restore_backup
	install -m 0755 ${WORKDIR}/boot_cfg ${D}/init.d/20-boot_cfg
	install -m 0755 ${WORKDIR}/device_data ${D}/init.d/50-device_data
	
	install -m 0755 ${WORKDIR}/detect_cifx ${D}/init.d/51-detect_cifx
	install -d ${D}${bindir}
	install -m 0755 ${WORKDIR}/detect_cifx_setup ${D}${bindir}/detect_cifx_setup
}

PACKAGES = " \
	${PN}-platform-init \
	${PN}-owner-cert \
	${PN}-initrd-api \
	${PN}-provisioning \
	${PN}-factory-reset \
	${PN}-check-fs \
	${PN}-restore-backup \
	${PN}-boot-cfg \
	${PN}-device-data \
	${PN}-detect-cifx \
	${PN}-base \
"

SUMMARY_${PN}-platform-init = "Modular initramfs support for platform initialization."
RDEPENDS_${PN}-platform-init += "${PN}-base"
FILES_${PN}-platform-init += "/init.d/*-platform_init"

SUMMARY_${PN}-owner-cert = "Modular initramfs support for providing built-in owner certificate."
RDEPENDS_${PN}-owner-cert += "${PN}-base pub-key-loader"
FILES_${PN}-owner-cert += "/init.d/*-owner_cert"

SUMMARY_${PN}-initrd-api = "Modular initramfs support for intrd-api."
RDEPENDS_${PN}-initrd-api += "${PN}-base util-linux-blkid util-linux-lsblk file-signature"
FILES_${PN}-initrd-api += "/init.d/*-initrd_api"

SUMMARY_${PN}-provisioning = "Modular initramfs support for manufacturing processes."
RDEPENDS_${PN}-provisioning += "${PN}-base nfs-utils-mount"
FILES_${PN}-provisioning += "/init.d/*-provisioning /init.d/functions"

SUMMARY_${PN}-factory-reset = "Modular initramfs support for factory reset."
RDEPENDS_${PN}-factory-reset += "${PN}-base"
FILES_${PN}-factory-reset += "/init.d/*-factory_reset"

SUMMARY_${PN}-check-fs = "Modular initramfs support for filesystem checks."
RDEPENDS_${PN}-check-fs += "${PN}-base e2fsprogs-e2fsck util-linux-lsblk"
FILES_${PN}-check-fs += "/init.d/*-check_fs"

SUMMARY_${PN}-restore-backup = "Modular initramfs support for backup/restore process."
RDEPENDS_${PN}-restore-backup += "${PN}-base fsarchiver"
FILES_${PN}-restore-backup += "/init.d/*-restore_backup"

SUMMARY_${PN}-boot-cfg = "Modular initramfs support for handling boot.cfg files."
RDEPENDS_${PN}-boot-cfg += "${PN}-base e2fsprogs-mke2fs coreutils e2fsprogs-e2fsck e2fsprogs-resize2fs dosfstools btrfs-tools util-linux-sfdisk util-linux-blkid"
RRECOMMENDS_${PN}-boot-cfg += "kernel-module-loop kernel-module-squashfs kernel-module-nls-cp437 kernel-module-nls-iso8859-1 kernel-module-overlay"
FILES_${PN}-boot-cfg += "/init.d/*-boot_cfg"

SUMMARY_${PN}-device-data = "Modular initramfs support for providing device data (device-label)."
RDEPENDS_${PN}-device-data += "${PN}-base device-data-driver coreutils net-tools"
FILES_${PN}-device-data += "/init.d/*-device_data"

SUMMARY_${PN}-detect-cifx = "Modularinitramfs support for cifx card detection."
RDEPENDS_${PN}-detect-cifx += "${PN}-base cifxhelpers cifxhelpers-read-hwinfo"
FILES_${PN}-detect-cifx = "/init.d/*-detect_cifx ${bindir}/detect_cifx_setup"

# Put all remaining files into the base package.
ALLOW_EMPTY_${PN}-base = "1"
RRECOMMENDS_${PN}-base += "${PACKAGES}"
FILES_${PN}-base = "/"
