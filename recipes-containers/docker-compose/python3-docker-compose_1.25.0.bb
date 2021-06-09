SUMMARY = "Multi-container orchestration for Docker"
HOMEPAGE = "https://www.docker.com/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=435b266b3899aa8a959f17d41c56def8"

inherit pypi setuptools3

SRC_URI[sha256sum] = "2c5fcbfd3ff445b6f3eebb549cb167ef1d8f70c5806aab8f309fc8fa74cd977e"

SRC_URI += "file://0001-setup.py-remove-maximum-version-requirements.patch"

RDEPENDS_${PN} = "\
    python3-cached-property \
    python3-certifi \
    python3-chardet \
    python3-colorama \
    python3-docker \
    python3-docker-pycreds \
    python3-dockerpty \
    python3-docopt \
    python3-fcntl \
    python3-idna \
    python3-jsonschema \
    python3-misc \
    python3-paramiko \
    python3-pyyaml \
    python3-requests \
    python3-six \
    python3-terminal \
    python3-texttable \
    python3-urllib3 \
    python3-websocket-client \
"
