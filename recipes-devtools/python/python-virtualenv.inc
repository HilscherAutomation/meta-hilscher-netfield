SUMMARY="A tool for creating isolated ‘virtual’ python environments."
HOMEPAGE="https://virtualenv.pypa.io/"
LICENSE="MIT"

LIC_FILES_CHKSUM="file://LICENSE.txt;md5=51910050bd6ad04a50033f3e15d6ce43"

SRC_URI[md5sum] = "4feb74ee26255dd7e62e36ce96bcc4c6"
SRC_URI[sha256sum] = "ca07b4c0b54e14a91af9f34d0919790b016923d157afda5efdde55c96718f752"

ALTERNATIVE_${PN} = "virtualenv"
ALTERNATIVE_LINK_NAME[virtualenv] = "${bindir}/virtualenv"
