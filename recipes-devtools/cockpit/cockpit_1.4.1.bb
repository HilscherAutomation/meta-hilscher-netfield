SRC_URI="file://cockpit-netiot-1.4.1.tar.bz2"
SRC_URI[sha256sum] = "1bad62ea8ea17af5163e44f0952170a1802957a85d0d9cbd8654361aded63c45"

S="${WORKDIR}/cockpit-netiot-${PV}"

LIC_FILES_CHKSUM="file://COPYING;md5=4fbd65380cdd255951079008b364516c"

SRC_URI += "file://use_tarball_version_if_available.patch"

EXTRA_OECONF:append = " ${@bb.utils.contains("IMAGE_FEATURES", "debug-tweaks", "--enable-debug", "" ,d)}"

do_configure:prepend() {
  echo "${PV}" > ${S}/.tarball

  sh autogen.sh ${CONFIGUREOPTS} ${EXTRA_OECONF} $@
}

require cockpit.inc
CVE_VERSION="194"
