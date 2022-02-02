do_install_append() {
    for service in aziot-identityd aziot-keyd aziot-certd aziot-tpmd; do
        install -d ${D}${sysconfdir}/systemd/system/${service}.service.d
        echo "[Service]" > ${D}${sysconfdir}/systemd/system/${service}.service.d/log-level.conf
        echo "Environment=AZIOT_LOG=WARN" >> ${D}${sysconfdir}/systemd/system/${service}.service.d/log-level.conf
    done
}
