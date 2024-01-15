SUMMARY="PKCS11-Proxy is a network proxy for a PKCS11 Library"
LICENSE="GPLv2"
HOMEPAGE="https://github.com/SUNET/pkcs11-proxy"

SRC_URI = "git://github.com/SUNET/pkcs11-proxy;protocol=https;branch=master"
SRCREV  = "2032875c95563c15cf77395f924191fdd6a1b33f"

LIC_FILES_CHKSUM = "file://debian/copyright;md5=34e381f8f7bc1692d1d0ce33fd706031"

SRC_URI += "file://only_build_proxy_library.patch"

S = "${WORKDIR}/git"

inherit cmake native

RDEPENDS:${PN} = "libp11-native"
