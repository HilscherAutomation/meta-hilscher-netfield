SUMMARY = "cifX device driver for Hilscher netX devices - kernel mode driver"
HOMEPAGE = "www.hilscher.com"
LICENSE = "GPL-2.0-only"

LIC_FILES_CHKSUM = "file://uio_netx.c;endline=12;md5=6d80c9f2fec84ce69fed2318825480a3"

FILESEXTRAPATHS:prepend := "${THISDIR}/..:"

require driver_version.inc
S .= "/uio_netx"

SRC_URI += "file://fix_dt_handling.patch"

EXTRA_OEMAKE = "KDIR=${STAGING_KERNEL_DIR} \
                TMPSYMVERS=${KBUILD_EXTRA_SYMBOLS}"

# Make sure package signing works correctly
INHIBIT_PACKAGE_STRIP="1"
EXTRA_OEMAKE:append   = " INSTALL_MOD_STRIP=1 "

inherit module sign-wrapper
