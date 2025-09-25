FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://00-base-interfaces.conf \
                   file://80-wlan-dnsmasq.rules"

# dbus support is required to interact with NetworkManager
PACKAGECONFIG:append = " dbus"

do_install:append() {
    # Allow writing to config directory by netadmin users
    install -d ${D}${libdir}/tmpfiles.d/
    cat <<EOF>> ${D}${libdir}/tmpfiles.d/dnsmasq_netadmin.conf
z ${sysconfdir}/dnsmasq.d 0775 root netadmin
z ${sysconfdir}/dnsmasq.d/* 0664 root netadmin
EOF

    # Make sure dnsmasq only uses wlan interfaces per default and reload it, if interfaces change
    install -m 0664 ${WORKDIR}/00-base-interfaces.conf ${D}${sysconfdir}/dnsmasq.d/

    install -d ${D}${nonarch_base_libdir}/udev/rules.d/
    install -m 0644 ${WORKDIR}/80-wlan-dnsmasq.rules ${D}${nonarch_base_libdir}/udev/rules.d/
}

FILES:${PN}:append = " ${libdir}/tmpfiles.d ${nonarch_base_libdir}/udev/rules.d/"
