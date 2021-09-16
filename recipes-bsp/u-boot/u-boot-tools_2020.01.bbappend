FILESEXTRAPATHS_prepend := "${THISDIR}/u-boot-tools:"
SRC_URI_append += "file://pkcs11_use_keydir_as_path.patch \
                   file://0001-set_boot_image_size_to_64MB.patch"
