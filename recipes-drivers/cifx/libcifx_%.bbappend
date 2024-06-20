
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://cifx.link \
            file://fix_firmware_init_timing_issue.patch \
            file://syslog_error_mapping.patch \
            file://publish_eth_channel_search.patch"

do_install:append() {
  install -d -m 0775 -g cifx ${D}/opt/cifx/deviceconfig/FW

  if [ "${@bb.utils.contains('PACKAGECONFIG', 'tun', 'yes', 'no', d)}" = "yes" ]; then
    install -d "${D}${systemd_unitdir}/network/"
    install -m 0644 ${WORKDIR}/cifx.link ${D}${systemd_unitdir}/network/98-cifx.link
  fi

    cat <<EOF> ${D}/opt/cifx/deviceconfig/FW/device.conf
eth=yes
dma=no
irq=no
EOF
}

FILES:${PN} += "${systemd_unitdir}/network/98-cifx.link"
