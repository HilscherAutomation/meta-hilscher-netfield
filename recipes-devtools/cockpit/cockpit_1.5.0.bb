SRC_URI="file://cockpit-netiot-${PV}.tar.bz2"
SRC_URI[sha256sum] = "f62fa7201ea5cdb104931dd20699ca026432ebc6c63d90273d7aea8c0b8c5029"

S="${WORKDIR}/cockpit-netiot-${PV}"

LIC_FILES_CHKSUM="file://COPYING;md5=4fbd65380cdd255951079008b364516c"

SRC_URI += " \
    file://use_tarball_version_if_available.patch \
"

EXTRA_OECONF:append = " ${@bb.utils.contains("IMAGE_FEATURES", "debug-tweaks", "--enable-debug", "" ,d)}"

do_configure:prepend() {
  echo "${PV}" > ${S}/.tarball

  sh autogen.sh ${CONFIGUREOPTS} ${EXTRA_OECONF} $@
}

require cockpit.inc
CVE_VERSION="194"
