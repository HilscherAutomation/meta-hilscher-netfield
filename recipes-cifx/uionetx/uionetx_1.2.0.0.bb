SUMMARY = "cifX device driver for Hilscher netX devices - kernel mode driver"
HOMEPAGE = "www.hilscher.com"
LICENSE = "GPLv2"

LIC_FILES_CHKSUM = "file://uio_netx.c;endline=12;md5=95fc4e2e758291d082694859311f7cea"

FILESEXTRAPATHS_append := "${THISDIR}/.."

SVN_MODULE="tags/V${PV}"
SRCREV="r12735"
SRC_URI = "svn://subversion01/svn/EmbeddedOS/Drivers/cifX/Linux;module=${SVN_MODULE};protocol=https;user=${HILSCHER_SVN_USER};pswd=${HILSCHER_SVN_PSWD}"

SRC_URI += " \
	file://0001-Bugfix-in-driver-unloading-function.patch \
"

S = "${WORKDIR}/${SVN_MODULE}/uio_netx"

EXTRA_OEMAKE = "KDIR=${STAGING_KERNEL_DIR} \
                TMPSYMVERS=${KBUILD_EXTRA_SYMBOLS}"

# Make sure package signing works correctly
INHIBIT_PACKAGE_STRIP="1"
EXTRA_OEMAKE_append   += " INSTALL_MOD_STRIP=1 "

inherit module
