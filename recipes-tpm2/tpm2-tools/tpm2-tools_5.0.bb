SUMMARY = "Tools for TPM2."
DESCRIPTION = "tpm2-tools"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://doc/LICENSE;md5=a846608d090aa64494c45fc147cc12e3"
SECTION = "tpm"

#PACKAGE_ARCH = "${BUILD_ARCH}"
BBCLASSEXTEND = "native nativesdk"

#PACKAGES =+ " ${PN}-native"

DEPENDS = "tpm2-abrmd tpm2-tss openssl curl autoconf-archive"

SRC_URI = "https://github.com/tpm2-software/${BPN}/releases/download/${PV}/${BPN}-${PV}.tar.gz"

SRC_URI[md5sum] = "5f64a328203a1ccb1ab9a0c08125e9e4"
SRC_URI[sha256sum] = "e1b907fe29877628052e08ad84eebc6c3f7646d29505ed4862e96162a8c91ba1"
SRC_URI[sha1sum] = "cdfe4e12e679e547528a2d908862762b63921e63"
SRC_URI[sha384sum] = "c391a7bb2dc579cf8b56186218846b37099d58d732b8501c28715b295dd2b9a59fd402afc06cc24530523ca1ad48aa41"
SRC_URI[sha512sum] = "ea57a28a61e28b78cae7067ff58facd8754fafab7a2689fd93f8b3374073b6ac30301a75f8ff5c654800ab469ee6604d0b8a86c310631b9545b816ecaa05968e"

inherit autotools pkgconfig bash-completion

S = "${WORKDIR}/tpm2-tools-${PV}"

FILES_${PN}_class_native = "/usr/*"
