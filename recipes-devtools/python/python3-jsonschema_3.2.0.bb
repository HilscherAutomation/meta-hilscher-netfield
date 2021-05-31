SUMMARY = "An implementation of JSON Schema validation for Python"
HOMEPAGE = "https://github.com/Julian/jsonschema"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING;md5=7a60a81c146ec25599a3e1dabb8610a8 \
                    file://json/LICENSE;md5=9d4de43111d33570c8fe49b4cb0e01af"
DEPENDS += "python3-vcversioner-native python3-setuptools-scm-native"

FILESEXTRAPATHS_prepend := "${THISDIR}/python-jsonschema:"

SRC_URI[sha256sum] = "c8a85b28d377cc7737e46e2d9f2b4f44ee3c0e1deac6bf46ddefc7187d30797a"

inherit pypi setuptools3

PACKAGECONFIG ??= "nongpl"
PACKAGECONFIG[format] = ",,,\
    python3-idna \
    python3-jsonpointer \
    python3-webcolors \
    python3-rfc3987 \
    python3-strict-rfc3339 \
"
PACKAGECONFIG[nongpl] = ",,,\
    python3-idna \
    python3-jsonpointer \
    python3-webcolors \
    python3-rfc3986-validator \
    python3-rfc3339-validator \
"

RDEPENDS_${PN} += " \
    python3-attrs \
    python3-core \
    python3-datetime \
    python3-importlib-metadata \
    python3-io \
    python3-json \
    python3-netclient \
    python3-numbers \
    python3-pkgutil \
    python3-pprint \
    python3-pyrsistent \
    python3-shell \
    python3-six \
    python3-unittest \
    python3-setuptools-scm \
    python3-zipp \
"

BBCLASSEXTEND = "native nativesdk"
