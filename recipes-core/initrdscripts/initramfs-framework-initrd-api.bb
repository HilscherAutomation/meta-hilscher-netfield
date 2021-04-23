SUMMARY = "Handle initrd-api files."
HOMEPAGE = "http://www.hilscher.com"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit allarch

SRC_URI = " \
	file://initrd_api \
"

PACKAGES = "${PN}"

RDEPENDS_${PN} = "util-linux-blkid util-linux-lsblk file-signature"

do_install () {
	install -d ${D}/init.d
	install -m 500 ${WORKDIR}/initrd_api ${D}/init.d/10-initrd_api
}

FILES_${PN} = "/init.d"
