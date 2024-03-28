SUMMARY="A pkcs#11 provider for OpenSSL 3.0+"
LICENSE="Apache-2.0"
HOMEPAGE="https://github.com/latchset/pkcs11-provider/"

LIC_FILES_CHKSUM="file://COPYING;md5=b53b787444a60266932bd270d1cf2d45"

SRC_URI="git://github.com/latchset/pkcs11-provider.git;protocol=https;branch=main"
SRCREV="58040b4e32975cc1d7f39e424ee7b0097cd11311"

S="${WORKDIR}/git"

inherit autotools pkgconfig

DEPENDS += "autoconf-archive openssl"

FILES:${PN} += "${libdir}/ossl-modules/pkcs11.so"
