FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

RDEPENDS_${PN}-base_append += "initramfs-update-user initramfs-update-ca"
RDEPENDS_${PN}-base_append += "file-signature"

