PROVIDES += "${PN}-iotedge"

PACKAGES =+ "${PN}-iotedge"

SYSTEMD_PACKAGES:append = " ${PN}-iotedge"
SYSTEMD_AUTO_ENABLE:${PN}-iotedge = "disable"
SYSTEMD_SERVICE:${PN}-iotedge = "containerd-iotedge.service"

do_install:append() {
    # Make sure to start our own containerd instance
    cp ${D}${systemd_system_unitdir}/containerd.service ${D}${systemd_system_unitdir}/containerd-iotedge.service

    sed -e 's@\(ExecStart=${bindir}/docker-containerd\)@\1 --state /run/containerd-iotedge --root /var/lib/containerd-iotedge/ --address /run/containerd-iotedge/containerd-iotedge.sock@g' \
        -i ${D}${systemd_system_unitdir}/containerd-iotedge.service
}

RDEPENDS:${PN}-iotedge = "${PN}"
FILES:${PN}-iotedge = "${systemd_system_unitdir}/containerd-iotedge.service"
