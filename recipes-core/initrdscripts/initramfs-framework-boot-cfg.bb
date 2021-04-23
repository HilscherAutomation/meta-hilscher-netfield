SUMMARY = "Handle boot configuration as defined in boot.cfg"
HOMEPAGE = "http://www.hilscher.com"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit allarch

SRC_URI = " \
	file://boot_cfg \
"

RRECOMMENDS_${PN} = "kernel-module-loop kernel-module-squashfs kernel-module-nls-cp437 kernel-module-nls-iso8859-1 kernel-module-overlay"

# Required stuff to support partition resizing
RDEPENDS_${PN} = "e2fsprogs-mke2fs coreutils e2fsprogs-e2fsck e2fsprogs-resize2fs dosfstools btrfs-tools util-linux-sfdisk util-linux-blkid"

PACKAGES = "${PN}"

RDEPENDS_${PN} += "file-signature"

do_install () {
	install -d ${D}/init.d
	install -m 500 ${WORKDIR}/boot_cfg ${D}/init.d/20-boot_cfg
}

FILES_${PN} = "/init.d"
