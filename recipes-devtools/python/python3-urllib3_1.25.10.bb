SUMMARY = "Python HTTP library with thread-safe connection pooling, file post support, sanity friendly, and more"
HOMEPAGE = "https://github.com/shazow/urllib3"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=65715c2eb961313d71b297dd5a04f85e"

SRC_URI[sha256sum] = "91056c15fa70756691db97756772bb1eb9678fa585d9184f24534b100dc60f4a"

inherit pypi setuptools3

RDEPENDS_${PN} += "\
    python3-certifi \
    python3-cryptography \
    python3-email \
    python3-idna \
    python3-netclient \
    python3-pyopenssl \
    python3-threading \
"

CVE_PRODUCT = "urllib3"

BBCLASSEXTEND = "native nativesdk"
