DESCRIPTION = "Read metadata from Python packages"
HOMEPAGE = "https://pypi.org/project/importlib-metadata/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e88ae122f3925d8bde8319060f2ddb8e"

SRC_URI = "https://files.pythonhosted.org/packages/5d/44/636bcd15697791943e2dedda0dbe098d8530a38d113b202817133e0b06c0/importlib_metadata-0.23.tar.gz"
S = "${WORKDIR}/importlib_metadata-${PV}"

SRC_URI[sha256sum] = "aa18d7378b00b40847790e7c27e11673d7fed219354109d0e7b9e5b25dc3ad26"

inherit pypi setuptools3

DEPENDS += "python3-setuptools-scm-native"
RDEPENDS_${PN} += "python3-zipp python3-pathlib2"
RDEPENDS_${PN}_append_class-target = " python3-misc"
RDEPENDS_${PN}_append_class-nativesdk = " python3-misc"


BBCLASSEXTEND = "native nativesdk"
