SUMMARY = "Security Key - kernel mode driver"
HOMEPAGE = "www.hilscher.com"
LICENSE = "GPLv2"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

FILESEXTRAPATHS_append := "${THISDIR}/.."

SRC_URI += "file://pub-key-loader.c"
SRC_URI += "file://Makefile"

S = "${WORKDIR}"

# Make sure package signing works correctly
INHIBIT_PACKAGE_STRIP="1"
EXTRA_OEMAKE   += "INSTALL_MOD_STRIP=1"

# libelf is required for CONFIG_STACK_VALIDATION=y
DEPENDS += "elfutils elfutils-native"

inherit module

do_make_scripts() {
        unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
        make CC="${KERNEL_CC}" LD="${KERNEL_LD}" AR="${KERNEL_AR}" \
                   -C ${STAGING_KERNEL_DIR} ${EXTRA_OEMAKE} scripts
}

do_compile() {
  CERT="${KEYS_IMAGE_SIGN_CERT}"
  rm -f cert.h

  printf "static char s_abCert[]=" > cert.h
  sed -e 's/^\(.*\)$/\"\1\\n\"/' ${CERT} >> cert.h
  echo ";" >> cert.h

  unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
  oe_runmake KDIR="${STAGING_KERNEL_DIR}"
}

do_install() {
  oe_runmake DEPMOD=echo INSTALL_MOD_PATH="${D}" \
                   KDIR=${STAGING_KERNEL_DIR} \
                   CC="${KERNEL_CC}" LD="${KERNEL_LD}" \
                   modules_install
}
