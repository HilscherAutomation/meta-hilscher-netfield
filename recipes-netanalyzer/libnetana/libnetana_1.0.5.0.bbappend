FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://fix_error_on_missing_kernel_driver.patch"
