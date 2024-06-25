SUMMARY = "upnp daemon (ssdp service)"
HOMEPAGE = ""
LICENSE = "CLOSED"

LIC_FILES_CHKSUM = ""

SRC_URI = "file://upnpd \
           file://upnpd.sh \
           file://upnpd.service \
           file://00-upnpd.conf \
           file://nm-dispatcher"

S = "${WORKDIR}/upnpd"

DEPENDS        = "libupnp"
RDEPENDS:${PN} = "libupnp"

APPARMOR_PROFILES="${PN}.apparmor:opt.${PN}.${PN}"
inherit apparmor

PACKAGES = "${PN} ${PN}-dbg"

do_install() {
  install -d -m 0775 "${D}/opt/upnpd"

  install upnpd "${D}/opt/upnpd"
  install ${WORKDIR}/upnpd.sh "${D}/opt/upnpd"

  install -d "${D}${systemd_unitdir}/system/"
  install -m 0644 ${WORKDIR}/upnpd.service "${D}${systemd_unitdir}/system/upnpd@.service"

  install -d ${D}${sysconfdir}/nginx/services/http/
  install ${WORKDIR}/00-upnpd.conf ${D}${sysconfdir}/nginx/services/http/

  install -d ${D}${sysconfdir}/NetworkManager/dispatcher.d
  install ${WORKDIR}/nm-dispatcher ${D}${sysconfdir}/NetworkManager/dispatcher.d/01-upnpd

  install -d ${D}${sysconfdir}/default
  echo 'UPNPD_ENABLED="1"' > ${D}${sysconfdir}/default/upnpd
  echo '# -1 = use https port of nginx' >> ${D}${sysconfdir}/default/upnpd
  echo 'UPNPD_PRESENTATION_PORT="-1"' >> ${D}${sysconfdir}/default/upnpd
}
RDEPENDS:${PN} += "${PN}-conf net-tools"

FILES:${PN}     += "/opt/upnpd/upnpd /opt/upnpd/upnpd.sh"
FILES:${PN}     += "${sysconfdir}"
FILES:${PN}-dbg += "/opt/upnpd/.debug"

inherit systemd
SYSTEMD_SERVICE:${PN} = "upnpd@.service"
SYSTEMD_AUTO_ENABLE   = "disable"

CONFFILES:${PN} = "${sysconfdir}/default/upnpd"
