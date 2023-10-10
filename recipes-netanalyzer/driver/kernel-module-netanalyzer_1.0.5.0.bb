SUMMARY = "netANALYZER device driver for Hilscher netANALYZER devices"
HOMEPAGE = "www.hilscher.com"
LICENSE = "GPLv2"

LIC_FILES_CHKSUM = "file://LICENSE;md5=c85113d9fb28eb2a1504e899037c915d"

inherit module sign-wrapper

require driver_version.inc

SRC_URI += " \
   file://flash_based_support.patch \
   file://fix_module_unload_of.patch \
   file://fix_compile_errors.patch \
"

S .= "netanalyzer_kernel_mod/"

EXTRA_OEMAKE += "KDIR=${STAGING_KERNEL_DIR}"

# Make sure package signing works correctly
INHIBIT_PACKAGE_STRIP="1"
EXTRA_OEMAKE += "INSTALL_MOD_STRIP=1"

# libelf is required for CONFIG_STACK_VALIDATION=y
DEPENDS += "elfutils elfutils-native"

do_install_append() {
  # Delete Module.symvers in /usr/include/..
  rm -rf ${D}${exec_prefix}

  install -d ${D}/lib/firmware/netanalyzer
  cp ${S}/../bsl/* ${D}/lib/firmware/netanalyzer
}

PACKAGES="${PN} netanalyzer-bsl"
FILES_netanalyzer-bsl = "/lib/firmware"
RDEPENDS_${PN}="netanalyzer-firmware netanalyzer-bsl"

PR="r1"
