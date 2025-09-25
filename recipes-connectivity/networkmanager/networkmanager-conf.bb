SUMMARY="Network manager machine specific base configuration"
LICENSE="CLOSED"

PRECONFIGURED_SYSTEM_CONNECTIONS ??= "eth0 eth1 cifx0"

PACKAGE_ARCH = "${MACHINE_ARCH}"

SRC_URI:append = " file://eth0 \
                   file://eth1 \
                   file://cifx0 \
                   file://wifi_permanent_mac \
                   file://static-arp \
                   file://hostname_change \
                   file://use_dnsmasq \
"

do_install() {
    install -m 0755 -d ${D}${sysconfdir}/NetworkManager/system-connections
    for conn in ${PRECONFIGURED_SYSTEM_CONNECTIONS}; do
        install -m 0600 ${WORKDIR}/$conn ${D}/etc/NetworkManager/system-connections/$conn
    done

    install -d ${D}${datadir}/NetworkManager
    install -m 0644 ${WORKDIR}/wifi_permanent_mac ${D}${datadir}/NetworkManager/wifi_permanent_mac.conf
    install -d ${D}${sysconfdir}/NetworkManager/conf.d
    ln -s ${datadir}/NetworkManager/wifi_permanent_mac.conf ${D}${sysconfdir}/NetworkManager/conf.d/00-wifi_permanent_mac.conf

    # Make sure to use dnsmasq plugin
    install -d ${D}${datadir}/NetworkManager
    install -m 0644 ${WORKDIR}/use_dnsmasq ${D}${datadir}/NetworkManager/use_dnsmasq.conf
    ln -s ${datadir}/NetworkManager/use_dnsmasq.conf ${D}${sysconfdir}/NetworkManager/conf.d/00-use-dnsmasq.conf

    install -d ${D}${sysconfdir}/NetworkManager/dispatcher.d
    install ${WORKDIR}/static-arp ${D}${sysconfdir}/NetworkManager/dispatcher.d/02-static-arp
    install ${WORKDIR}/hostname_change ${D}${sysconfdir}/NetworkManager/dispatcher.d/03-hostname-changed
}

PACKAGES="${PN}"
FILES:${PN} = "${sysconfdir} ${datadir}"
RDEPENDS:${PN} = "net-tools"
