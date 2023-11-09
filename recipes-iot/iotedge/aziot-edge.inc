SUMMARY = "iotedge - Azure IoTEdge runtime"
HOMEPAGE = "https://github.com/Azure/iotedge"
LICENSE = "MIT"
LIC_FILES_CHKSUM="file://../LICENSE;md5=0f7e3b1308cb5c00b372a6e78835732d"

DEPENDS:append = " libstd-rs openssl"

SRC_URI += "file://aziot_use_unwind_instead_abort.patch"

inherit systemd
SYSTEMD_AUTO_ENABLE = "disable"
SYSTEMD_SERVICE:${PN} = "aziot-edged.service aziot-edged.mgmt.socket aziot-edged.workload.socket"

inherit useradd
USERADD_PACKAGES="${PN}"
USERADD_PARAM:${PN} = "--system --no-create-home --home-dir /var/lib/aziot/edged --shell /sbin/nologin --user-group --groups docker,systemd-journal,aziotcs,aziotks,aziotid,aziottpm iotedge;"
USERADD_PARAM:${PN} += "-g iotedge -s /sbin/nologin edgeagentuser;"
USERADD_PARAM:${PN} += "-g iotedge -s /sbin/nologin edgehubuser;"
GROUPADD_PARAM:${PN} = "-r docker;-r systemd-journal;-r aziotcs;-r aziotks;-r aziotid; -r aziottpm"

do_install:append() {
    install -d ${D}${sysconfdir}/aziot/edged/config.d ${D}${sysconfdir}/logrotate.d ${D}${systemd_system_unitdir} \
               ${D}${localstatedir}/lib/aziot/edged ${D}${localstatedir}/secrets

    sed -e 's;@connect_workload_uri@;unix:///run/iotedge/workload.sock;g' \
        -e 's;@connect_management_uri@;unix:///run/iotedge/mgmt.sock;g' \
        -e 's;@listen_workload_uri@;fd://aziot-edged.workload.socket;g' \
        -e 's;@listen_management_uri@;fd://aziot-edged.workload.socket;g' \
        ${S}/contrib/config/linux/default.toml > ${D}${sysconfdir}/aziot/edged/config.toml.default
    sed -e 's;@connect_workload_uri@;unix:///run/iotedge/workload.sock;g' \
        -e 's;@connect_management_uri@;unix:///run/iotedge/mgmt.sock;g' \
        -e 's;@listen_workload_uri@;fd://aziot-edged.workload.socket;g' \
        -e 's;@listen_management_uri@;fd://aziot-edged.mgmt.socket;g' \
        ${S}/contrib/config/linux/template.toml > ${D}${sysconfdir}/aziot/config.toml.edge.template

    # Adjust permissions (taken from debian/postinst script)
    chown iotedge:iotedge ${D}${localstatedir}/lib/aziot/edged
    chown iotedge:iotedge ${D}${sysconfdir}/aziot/edged/config.toml.default
    chown iotedge:iotedge ${D}${sysconfdir}/aziot/edged/config.d

    chmod 0755 ${D}${localstatedir}/lib/aziot/edged
    chmod 0600 ${D}${sysconfdir}/aziot/config.toml.edge.template
    chmod 0400 ${D}${sysconfdir}/aziot/edged/config.toml.default
    chmod 0700 ${D}${sysconfdir}/aziot/edged/config.d

    install -d -m 0777 ${D}${localstatedir}/lib/aziot/storage
    install -d -m 0777 ${D}${localstatedir}/lib/aziot/storage/edgeAgent
    install -d -m 0777 ${D}${localstatedir}/lib/aziot/storage/edgeHub

    install -m 0644 ${S}/contrib/config/linux/logrotate ${D}${sysconfdir}/logrotate.d/aziot-edge

    for systemd_unit in aziot-edged.service aziot-edged.workload.socket aziot-edged.mgmt.socket; do
        install -m 0644 ${S}/contrib/systemd/debian/$systemd_unit ${D}${systemd_system_unitdir}
    done

    # Make sure to start docker as well
    sed -i -e 's/After=network-online.target/After=docker.socket network-online.target/g' \
           -e 's/Requires=network-online.target/Requires=docker.socket network-online.target/g' ${D}${systemd_system_unitdir}/aziot-edged.service

    install -d ${D}${libexecdir}/aziot
    mv ${D}${bindir}/aziot-edged ${D}${libexecdir}/aziot/
}

PACKAGES="${PN}-dev ${PN}"
RDEPENDS:${PN} = "docker openssl procps azure-identity-service"
FILES:${PN} = "${bindir} ${libexecdir} ${sysconfdir} ${libdir} ${localstatedir}"
FILES:${PN}-dev = "${libdir}/rust"
INHIBIT_PACKAGE_DEBUG_SPLIT="1"
PROVIDES="iotedge"
RPROVIDES:${PN}="iotedge"
