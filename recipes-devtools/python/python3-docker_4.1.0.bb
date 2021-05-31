SUMMARY = "A Python library for the Docker Engine API."
HOMEPAGE = "https://github.com/docker/docker-py"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=34f3846f940453127309b920eeb89660"

SRC_URI[sha256sum] = "6e06c5e70ba4fad73e35f00c55a895a448398f3ada7faae072e2bb01348bafc1"

RDEPENDS_${PN} += " \
	python3-misc \
	python3-six \
	python3-docker-pycreds \
	python3-requests \
	python3-websocket-client \
"

inherit pypi setuptools3
DEPENDS += "python3-pip-native"
