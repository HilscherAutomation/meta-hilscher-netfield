FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI:append = " \
   file://flash_based_support.patch \
   file://fix_module_unload_of.patch \
   file://fix_compile_errors.patch \
   file://fix_unload.patch \
"
