DESCRIPTION = "Backport of pathlib-compatible object wrapper for zip files"
HOMEPAGE = "https://github.com/jaraco/zipp"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=a33f38bbf47d48c70fe0d40e5f77498e"

SRC_URI[sha256sum] = "3718b1cbcd963c7d4c5511a8240812904164b7f381b647143a89d3b98f9bcd8e"

inherit pypi setuptools3

DEPENDS += "python3-setuptools-scm-native"
RDEPENDS_${PN} += "python3-more-itertools"

BBCLASSEXTEND = "native nativesdk"
