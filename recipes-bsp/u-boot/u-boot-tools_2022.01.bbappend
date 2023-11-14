FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-tools:"
SRC_URI:append = " file://pkcs11_use_keydir_as_path.patch \
                   file://0001-set_boot_image_size_to_64MB.patch \
                   file://mkimage-wrapper \
                  "

do_install:append() {
	# replace the original mkimage with a wrapper (see script for more info)
	mv ${D}/${bindir}/uboot-mkimage ${D}/${bindir}/uboot-mkimage.bin
	cp ${WORKDIR}/mkimage-wrapper   ${D}/${bindir}/uboot-mkimage

	chmod 755 ${D}/${bindir}/uboot-mkimage
}
