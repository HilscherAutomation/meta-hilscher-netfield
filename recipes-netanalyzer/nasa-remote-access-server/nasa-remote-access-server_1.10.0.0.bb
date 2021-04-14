SUMMARY = "netANALYZER stand-alone application for Hilscher netANALYZER devices"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

inherit autotools

SRC_URI = "file://${PN}_${PV}.tar.gz \
           file://nasa-remote-access-server.service"

S = "${WORKDIR}/${PN}_${PV}"

EXTRA_OECONF +="--enable-iotgw"

DEST_DIR="/opt/nasa/remote-access-server/"
EXTRA_OECONF +="--bindir=${DEST_DIR}"

DEPENDS="libnetana"
RDEPENDS_${PN} = "libnetana"

do_install_append(){
    # register service
    if [ "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd', '', d)}" = "systemd" ]; then
        install -d ${D}${systemd_unitdir}/system/
        install -m 0644 ${WORKDIR}/nasa-remote-access-server.service ${D}${systemd_unitdir}/system/

        # Exchange base directory in scripts (not implemented)
        #sed -i -e 's,@NASA_BASEDIR@,${NASA_BASEDIR},g' \
        #    ${D}${systemd_unitdir}/system/nasa-remote-access-server.service
    fi
}

inherit systemd
SYSTEMD_SERVICE_${PN} = "nasa-remote-access-server.service"
SYSTEMD_AUTO_ENABLE = "disable"

FILES_${PN} = "${DEST_DIR}"
