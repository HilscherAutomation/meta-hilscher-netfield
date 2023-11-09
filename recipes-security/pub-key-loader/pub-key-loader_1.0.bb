SUMMARY = "Security Key - kernel mode driver"
HOMEPAGE = "www.hilscher.com"
LICENSE = "GPLv2"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

FILESEXTRAPATHS:prepend := "${THISDIR}/..:"

SRC_URI += "file://pub-key-loader.c"
SRC_URI += "file://Makefile"

S = "${WORKDIR}"

# Make sure package signing works correctly
INHIBIT_PACKAGE_STRIP="1"
EXTRA_OEMAKE   += "INSTALL_MOD_STRIP=1"

# libelf is required for CONFIG_STACK_VALIDATION=y
DEPENDS += "elfutils elfutils-native"

inherit module sign-wrapper

do_compile:prepend() {
	CERT="${B}/tpmcert"
	sign_wrapper_copy_certificate "${CERT}" "pem"
	rm -f cert.h

	printf "static char s_abCert[]=" > cert.h
	sed -e 's/^\(.*\)$/\"\1\\n\"/' ${CERT} >> cert.h
	echo ";" >> cert.h
}
