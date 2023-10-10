DESCRIPTION = "cifX device driver for Hilscher netX devices"
HOMEPAGE = "http://www.hilscher.com"
LICENSE = "CLOSED"

inherit cmake
inherit useradd

require driver_version.inc
S .= "libcifx/"

DEBIAN_NOAUTONAME_${PN} = "1"

USERADD_PACKAGES = "${PN}"
GROUPADD_PARAM_${PN} = "-r cifx"

# As we may be using different settings per machine, make libcifx a machine package
PACKAGE_ARCH = "${MACHINE_ARCH}"
PACKAGES =+ "${PN}-plugin-spm"
RDEPENDS_${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'spm', '${PN}-plugin-spm', '', d)}"

DEPENDS        += "${@bb.utils.contains('PACKAGECONFIG', 'tun', 'libnl', '', d)}"
RDEPENDS_${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'tun', 'libnl libnl-cli', '', d)}"

FILESEXTRAPATHS_append := "${THISDIR}/..:"

SRC_URI += " \
   file://80-hilscher-netx.rules \
   file://80-hilscher-cifxeth.rules \
   file://cifxeth \
   file://80-hilscher-netx-spi.rules \
   file://cifx.link \
   file://fix_firmware_init_timing_issue.patch \
   file://syslog_error_mapping.patch \
   file://link_state_by_libnl.patch \
   file://publish_eth_channel_search.patch \
   file://add_empty_mbx_at_shutdown.patch"

PACKAGECONFIG ?= "${@bb.utils.contains('MACHINE_FEATURES', 'pci', 'pci', '' ,d)} \
                  tun"

CIFX_SPI_CONFIGS ??= "Device=spidev0.0;Speed=25000000;Mode=0;ChunkSize=0;CSChange=0"
PACKAGECONFIG[pci] = ",-DDISABLE_PCI=ON,libpciaccess,libpciaccess uionetx"
PACKAGECONFIG[spm] = "-DHWIF=ON -DSPM_PLUGIN=ON"
PACKAGECONFIG[tun] = "-DVIRTETH=ON"


do_install_append() {
  #bootloader
  cd "${S}../BSL"
  install -d -m 0775 -g cifx "${D}/opt/cifx/deviceconfig/"
  install -m 444 NETX*  "${D}/opt/cifx/"

  if [ "${@bb.utils.contains('PACKAGECONFIG', 'pci', 'yes', 'no', d)}" = "yes" ]; then
    install -d ${D}${nonarch_base_libdir}/udev/rules.d/
    install -m 0644 ${WORKDIR}/80-hilscher-netx.rules ${D}${nonarch_base_libdir}/udev/rules.d/
  fi

  if [ "${@bb.utils.contains('PACKAGECONFIG', 'tun', 'yes', 'no', d)}" = "yes" ]; then
    install -d ${D}${nonarch_base_libdir}/udev/rules.d/
    install -m 0644 ${WORKDIR}/80-hilscher-cifxeth.rules ${D}${nonarch_base_libdir}/udev/rules.d/

    install -d "${D}/etc/init.d/"
    install -m 0744 ${WORKDIR}/cifxeth ${D}/etc/init.d/

    install -d "${D}${systemd_unitdir}/network/"
    install -m 0644 ${WORKDIR}/cifx.link ${D}${systemd_unitdir}/network/98-cifx.link
  fi

  if [ "${@bb.utils.contains('PACKAGECONFIG', 'spm', 'yes', 'no', d)}" = "yes" ]; then
    install -d ${D}${nonarch_base_libdir}/udev/rules.d/
    install -m 0644 ${WORKDIR}/80-hilscher-netx-spi.rules ${D}${nonarch_base_libdir}/udev/rules.d/

    install -d ${D}/opt/cifx/plugins/netx-spm/
    # Delete delete spi configuration from driver as we bring our own
    rm ${D}/opt/cifx/plugins/netx-spm/*
    spi_ports="${CIFX_SPI_CONFIGS}"
    idx=0
    for tmp_config in $spi_ports; do
        echo "$tmp_config" > ${D}/opt/cifx/plugins/netx-spm/config${idx}
        sed -i -e 's/;/\n/g' ${D}/opt/cifx/plugins/netx-spm/config${idx}
        chmod 0744 ${D}/opt/cifx/plugins/netx-spm/config${idx}
        idx=$(expr $idx + 1)
    done
  fi

  chgrp -R cifx ${D}/opt/cifx
  chmod 0775 ${D}/opt/cifx
}

FILES_${PN} += "/usr/lib/ \
                /opt/cifx/ \
                ${nonarch_base_libdir}/udev/rules.d/80-hilscher-netx.rules \
                ${nonarch_base_libdir}/udev/rules.d/80-hilscher-cifxeth.rules \
                ${systemd_unitdir}/network/98-cifx.link \
                "
FILES_${PN}-plugin-spm += "/opt/cifx/plugins/ \
                           ${nonarch_base_libdir}/udev/rules.d/80-hilscher-netx-spi.rules"
