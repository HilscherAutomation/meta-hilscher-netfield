do_install:append() {
    # Add --bind-dynamic to service to allow handling hot-pluggable devices, like WiFi, BT, USB adaptors
    sed -i -e 's/--local-service/--local-service --bind-dynamic/g' \
        ${D}${systemd_system_unitdir}/${PN}.service

    # Allow writing to config directory by netadmin users
    install -d ${D}${libdir}/tmpfiles.d/
    cat <<EOF>> ${D}${libdir}/tmpfiles.d/dnsmasq_netadmin.conf
z ${sysconfdir}/dnsmasq.d 0775 root netadmin
z ${sysconfdir}/dnsmasq.d/* 0664 root netadmin
EOF
}

FILES:${PN}:append = " ${libdir}/tmpfiles.d"
