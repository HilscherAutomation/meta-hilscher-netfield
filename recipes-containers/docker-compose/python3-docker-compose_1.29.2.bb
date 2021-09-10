SUMMARY = "Multi-container orchestration for Docker"
HOMEPAGE = "https://www.docker.com/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=435b266b3899aa8a959f17d41c56def8"

inherit pypi setuptools3

SRC_URI[sha256sum] = "4c8cd9d21d237412793d18bd33110049ee9af8dab3fe2c213bbd0733959b09b7"

RDEPENDS_${PN} = "\
    python3-cached-property \
    python3-certifi \
    python3-chardet \
    python3-colorama \
    python3-distro \
    python3-docker \
    python3-docker-pycreds \
    python3-dockerpty \
    python3-docopt \
    python3-fcntl \
    python3-idna \
    python3-jsonschema \
    python3-misc \
    python3-paramiko \
    python3-pysocks \
    python3-dotenv \
    python3-pyyaml \
    python3-requests \
    python3-terminal \
    python3-texttable \
    python3-urllib3 \
    python3-websocket-client \
"
