SUMMARY = "upnp daemon (ssdp service)"
HOMEPAGE = ""
LICENSE = "CLOSED"

LIC_FILES_CHKSUM = ""

SRC_URI = "file://upnpd \
           file://upnpd.sh \
           file://netiotdevicedesc.xml \
           file://upnpd.service \
           file://init-desc \
           file://00-upnpd.conf \
           file://logo.png \
           file://nm-dispatcher"

S = "${WORKDIR}/upnpd"

DEPENDS        = "libupnp"
RDEPENDS_${PN} = "libupnp"

APPARMOR_PROFILES="${PN}.apparmor:opt.${PN}.${PN}"
inherit apparmor

PACKAGES = "${PN} ${PN}-dbg"

do_install() {
  install -d -m 0775 "${D}/opt/upnpd"
  install -d -m 0775 "${D}/opt/upnpd/desc"

  install upnpd "${D}/opt/upnpd"
  install ${WORKDIR}/upnpd.sh "${D}/opt/upnpd"
  install -m 0664 ${WORKDIR}/netiotdevicedesc.xml "${D}/opt/upnpd"
  install -m 0774 ${WORKDIR}/logo.png             "${D}/opt/upnpd/desc"
  install -m 0774 ${WORKDIR}/init-desc            "${D}/opt/upnpd/"

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
PACKAGES =+ "${PN}-conf"
RDEPENDS_${PN} += "${PN}-conf net-tools"

FILES_${PN}-conf = "/opt/upnpd/netiotdevicedesc.xml"
FILES_${PN}     += "/opt/upnpd/upnpd /opt/upnpd/upnpd.sh"
FILES_${PN}     += "/opt/upnpd/init-desc"
FILES_${PN}     += "/opt/upnpd/desc"
FILES_${PN}     += "${sysconfdir}"
FILES_${PN}-dbg += "/opt/upnpd/.debug"

inherit systemd
SYSTEMD_SERVICE_${PN} = "upnpd@.service"
SYSTEMD_AUTO_ENABLE   = "disable"

CONFFILES_${PN} = "${sysconfdir}/default/upnpd"
