FILESEXTRAPATHS_prepend := "${THISDIR}/docker:${THISDIR}/aziot-edge:"

SRC_URI_append += "file://iotedge-docker.service \
                   file://iotedge-docker.socket \
                   file://iotedge.slice \
                   file://iotedge.json \
                   file://iotedge_bridge.sh \
                   file://iotedge.rules \
                   file://iotedge.default \
                   file://docker-iotedge.sh \
                   file://iotedge_systemd_use_rundir.patch \
                   file://migrate_config.sh \
                   file://aziot-genca \
                   file://iotedge_config_skip_service_start.patch \
                   file://aziot-generate-local-ca.patch \
                   file://iotedge-docker-config.sh \
"

RDEPENDS_${PN}_append += "bridge-utils yq"

SYSTEMD_SERVICE_${PN}_append += "iotedge-docker.service iotedge-docker.socket iotedge.slice"

do_install_append() {
    install -d ${D}${sysconfdir}/docker
    install -m0644 ${WORKDIR}/iotedge.json ${D}${sysconfdir}/docker/
    install -m0644 ${WORKDIR}/iotedge-docker.service ${D}${systemd_system_unitdir}
    install -m0644 ${WORKDIR}/iotedge-docker.socket ${D}${systemd_system_unitdir}
    install -m0644 ${WORKDIR}/iotedge.slice ${D}${systemd_system_unitdir}

    sed -i -e 's/docker.socket/iotedge-docker.socket/g' \
           -e 's/docker.service/iotedge-docker.service/g' \
           -e 's/\[Service\]/\[Service\]\nOOMScoreAdjust=-1000/g' \
           ${D}${systemd_system_unitdir}/aziot-edged.service

    install -d ${D}/usr/libexec/iotedge-docker/
    install -m 0755 ${WORKDIR}/iotedge-docker-config.sh ${D}/usr/libexec/iotedge-docker/iotedge-docker-config

    install ${WORKDIR}/docker-iotedge.sh ${D}${bindir}/docker-iotedge

    install -d ${D}${sbindir}
    install ${WORKDIR}/iotedge_bridge.sh ${D}${sbindir}/iotedge_bridge
    install -d ${D}${sysconfdir}/default
    install -m 0644 ${WORKDIR}/iotedge.default ${D}${sysconfdir}/default/iotedge

    install -d ${D}${sysconfdir}/tmpfiles.d
    cat <<EOF>> ${D}${sysconfdir}/tmpfiles.d/iotedge_netadmin.conf
z ${sysconfdir}/default/iotedge 0664 root netadmin
z ${sysconfdir}/docker/iotedge.json 0664 root netadmin
EOF

    install -d ${D}${base_libdir}/udev/rules.d/
    install -m 0644 ${WORKDIR}/iotedge.rules ${D}${base_libdir}/udev/rules.d/80-iotedge.rules

    sed -i -e 's;unix:///run/docker.sock;unix:///run/iotedge-docker.sock;g' ${D}${sysconfdir}/aziot/edged/config.toml.default
    sed -i -e 's;unix:///run/docker.sock;unix:///run/iotedge-docker.sock;g' ${D}${sysconfdir}/aziot/config.toml.edge.template

    install ${WORKDIR}/migrate_config.sh ${D}${bindir}/iotedge-migrate-config

    # Add script to generate a long-running CA certificate
    install ${WORKDIR}/aziot-genca ${D}${libexecdir}/aziot/

    # Set default log level to WARN
    install -d ${D}${sysconfdir}/systemd/system/aziot-edged.service.d
    echo "[Service]" > ${D}${sysconfdir}/systemd/system/aziot-edged.service.d/log-level.conf
    echo "Environment=AZIOT_LOG=WARN" >> ${D}${sysconfdir}/systemd/system/aziot-edged.service.d/log-level.conf
}

FILES_${PN}_append += "${base_libdir} ${sbindir}"
