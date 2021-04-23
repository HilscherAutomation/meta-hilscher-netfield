SUMMARY = "Starts and configures services required for recovery."
HOMEPAGE = ""
LICENSE = "CLOSED"

LIC_FILES_CHKSUM = ""

SRC_URI = "file://prepare_platform.sh \
           file://rescue.service \
           file://rescue.conf"

S = "${WORKDIR}/"

do_install() {
  install -d -m 0775 "${D}/opt/rescue/"
  install -d -m 0775 "${D}${sysconfdir}/default"

  install ${WORKDIR}/prepare_platform.sh "${D}/opt/rescue/"

  install ${WORKDIR}/rescue.conf "${D}${sysconfdir}/default/rescue"

  install -d "${D}${systemd_unitdir}/system/"
  install -m 0644 ${WORKDIR}/rescue.service "${D}${systemd_unitdir}/system/rescue-image.service"
}

FILES_${PN} += "/opt/rescue/prepare_platform.sh"
FILES_${PN} += "${systemd_unitdir}/system/rescue-image.service"

inherit systemd
SYSTEMD_SERVICE_${PN} = "rescue-image.service"
SYSTEMD_AUTO_ENABLE = "enable"

CONFFILES_${PN} = "${sysconfdir}/default/rescue"
