SUMMARY = "Python module that implements the SSH2 protocol"
HOMEPAGE = "https://github.com/paramiko/paramiko"
LICENSE = "LGPLv2.1"
LIC_FILES_CHKSUM = "file://LICENSE;md5=fd0120fc2e9f841c73ac707a30389af5"

inherit pypi setuptools3

SRC_URI[sha256sum] = "920492895db8013f6cc0179293147f830b8c7b21fdfc839b6bad760c27459d9f"

RDEPENDS_${PN} += " \
    python3-bcrypt \
    python3-cryptography \
    python3-pyasn1 \
    python3-nacl \
"
