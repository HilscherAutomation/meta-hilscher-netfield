SUMMARY="A tool for creating isolated ‘virtual’ python environments."
HOMEPAGE="https://virtualenv.pypa.io/"
LICENSE="MIT"

LIC_FILES_CHKSUM="file://LICENSE.txt;md5=51910050bd6ad04a50033f3e15d6ce43"

SRC_URI[sha256sum] = "ca07b4c0b54e14a91af9f34d0919790b016923d157afda5efdde55c96718f752"

inherit pypi setuptools3 update-alternatives

DEPENDS = "python3-setuptools-native python3"

ALTERNATIVE_PRIORITY = "100"
ALTERNATIVE_${PN} = "virtualenv"
ALTERNATIVE_LINK_NAME[virtualenv] = "${bindir}/virtualenv"
