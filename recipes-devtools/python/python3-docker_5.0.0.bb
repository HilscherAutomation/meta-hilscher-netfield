SUMMARY = "A Python library for the Docker Engine API."
HOMEPAGE = "https://github.com/docker/docker-py"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=34f3846f940453127309b920eeb89660"

SRC_URI[sha256sum] = "3e8bc47534e0ca9331d72c32f2881bb13b93ded0bcdeab3c833fb7cf61c0a9a5"

RDEPENDS_${PN} += " \
	python3-misc \
	python3-six \
	python3-docker-pycreds \
	python3-requests \
	python3-websocket-client \
"

inherit pypi setuptools3
DEPENDS += "python3-pip-native"
