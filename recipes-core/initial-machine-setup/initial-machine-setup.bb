SUMMARY = "Sets initial host name"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI = "file://initial-hostname.service \
           file://initial-hostname.sh \
           file://initial-iotedge-setup.service \
           file://initial-iotedge-setup.sh \
           file://initial-branding.service \
           file://initial-branding.sh \
"

PR="r1"

do_install() {
  install -d "${D}/${base_sbindir}"
  for script in initial-hostname.sh initial-iotedge-setup.sh initial-branding.sh; do
      install -m 755 "${WORKDIR}/$script" "${D}/${base_sbindir}"
  done

  install -d "${D}/${systemd_unitdir}/system/"
  for service in initial-hostname.service initial-iotedge-setup.service initial-branding.service; do
      install -m 644 "${WORKDIR}/$service" "${D}/${systemd_unitdir}/system/"
  done
}

SYSTEMD_SERVICE_${PN} = "initial-hostname.service initial-iotedge-setup.service initial-branding.service"

FILES_${PN} = "${base_sbindir}"
FILES_${PN} += "${systemd_unitdir}/system"
