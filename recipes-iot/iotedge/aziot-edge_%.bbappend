FILESEXTRAPATHS:prepend := "${THISDIR}/docker:${THISDIR}/aziot-edge:"

SRC_URI:append = " file://iotedge-docker.service \
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
                   file://fix_missing_storage_folder.patch \
                   file://iotedge-docker-config.sh \
                   file://update_gateway_settings.patch \
                   file://update_gateway_settings \
"

RDEPENDS:${PN}:append = " bridge-utils yq"
# acl is required to set ACL in docker.socket
RDEPENDS:${PN}:append = " acl"
# bash is required for update_gateway_settings script
RDEPENDS:${PN}:append = " bash"
# toml-cli is required for aziot-genca script
RDEPENDS:${PN}:append = " toml-cli"

SYSTEMD_SERVICE:${PN}:append = " iotedge-docker.service iotedge-docker.socket iotedge.slice"

export SOCKET_DIR="/run/aziot"

do_install:append() {
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
    install -d ${D}${sysconfdir}/default/iotedge
    install -m 0644 ${WORKDIR}/iotedge.default ${D}${sysconfdir}/default/iotedge/bridge

    install -d ${D}${libdir}/tmpfiles.d
    cat <<EOF>> ${D}${libdir}/tmpfiles.d/iotedge_netadmin.conf
d ${sysconfdir}/default/iotedge/ 0775 root netadmin -
z ${sysconfdir}/default/iotedge/ 0775 root netadmin
z ${sysconfdir}/default/iotedge/bridge 0664 root netadmin
z ${sysconfdir}/docker/ 0775 root netadmin -
z ${sysconfdir}/docker/iotedge.json 0664 root netadmin
EOF

    install -d ${D}${base_libdir}/udev/rules.d/
    install -m 0644 ${WORKDIR}/iotedge.rules ${D}${base_libdir}/udev/rules.d/80-iotedge.rules

    sed -i -e 's;unix:///run/docker.sock;unix:///run/iotedge-docker.sock;g' ${D}${sysconfdir}/aziot/edged/config.toml.default
    sed -i -e 's;unix:///run/docker.sock;unix:///run/iotedge-docker.sock;g' ${D}${sysconfdir}/aziot/config.toml.edge.template

    install ${WORKDIR}/migrate_config.sh ${D}${bindir}/iotedge-migrate-config

    # Add script to generate a long-running CA certificate
    install ${WORKDIR}/aziot-genca ${D}${libexecdir}/aziot/

    # Add script to update settings.json when cloud assigns hardwareid
    install ${WORKDIR}/update_gateway_settings ${D}${libexecdir}/aziot/

    # Set default log level to WARN
    install -d ${D}${sysconfdir}/systemd/system/aziot-edged.service.d
    echo "[Service]" > ${D}${sysconfdir}/systemd/system/aziot-edged.service.d/log-level.conf
    echo "Environment=AZIOT_LOG=WARN" >> ${D}${sysconfdir}/systemd/system/aziot-edged.service.d/log-level.conf
}

FILES:${PN}:append = " ${base_libdir} ${sbindir}"
