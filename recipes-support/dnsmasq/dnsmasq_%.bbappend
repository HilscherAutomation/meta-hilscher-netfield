do_install_append() {
    # Add --bind-dynamic to service to allow handling hot-pluggable devices, like WiFi, BT, USB adaptors
    sed -i -e 's/--local-service/--local-service --bind-dynamic/g' \
        ${D}${systemd_system_unitdir}/${PN}.service
}
