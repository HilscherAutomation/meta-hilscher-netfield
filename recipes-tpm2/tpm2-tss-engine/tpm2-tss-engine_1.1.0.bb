SUMMARY = "The tpm2-tss-engine project implements a cryptographic engine for OpenSSL." 
DESCRIPTION = "The tpm2-tss-engine project implements a cryptographic engine for OpenSSL for Trusted Platform Module (TPM 2.0) using the tpm2-tss software stack that follows the Trusted Computing Groups (TCG) TPM Software Stack (TSS 2.0). It uses the Enhanced System API (ESAPI) interface of the TSS 2.0 for downwards communication. It supports RSA decryption and signatures as well as ECDSA signatures."

LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=7b3ab643b9ce041de515d1ed092a36d4"

SECTION = "security/tpm"

BBCLASSEXTEND = "native nativesdk"

#DEPENDS = "autoconf-archive-native bash-completion libtss2 libgcrypt openssl"
DEPENDS = "autoconf-archive-native tpm2-tss libtss2 libgcrypt openssl"

#SRCREV = "6f387a4efe2049f1b4833e8f621c77231bc1eef4"
#SRC_URI = "git://github.com/tpm2-software/tpm2-tss-engine.git"
SRC_URI = "https://github.com/tpm2-software/${BPN}/releases/download/v${PV}/${BPN}-${PV}.tar.gz"

SRC_URI[sha256sum] = "ea2941695ac221d23a7f3e1321140e75b1495ae6ade876f2f4c2ed807c65e2a5"

inherit autotools-brokensep pkgconfig systemd

S = "${WORKDIR}/tpm2-tss-engine-${PV}"

PACKAGES += "${PN}-engines ${PN}-engines-staticdev ${PN}-bash-completion"
#PACKAGES += "${PN}-engines ${PN}-engines-staticdev"

FILES:${PN}-dev = "${includedir}/*"
# tpm2tss.so is a symlink required to make -engine tpm2tss work in openssl
INSANE_SKIP:${PN}-engines="dev-so"
FILES:${PN}-engines = "${libdir}/engines-1.1/"
FILES:${PN}-engines-staticdev = "${libdir}/engines-1.1/libtpm2tss.a"
FILES:${PN}-bash-completion += "${datadir}/bash-completion/completions"
