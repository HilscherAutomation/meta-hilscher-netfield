SUMMARY="A daemon to restrict/limit docker API calls (e.g. preventing privileged mode)"
LICENSE="CLOSED"

SRC_URI = "file://authz.py \
           file://${PN}.service \
           file://${PN}.apparmor \
           file://filters/deny-privileged"

RDEPENDS_${PN} = "gunicorn python3-flask docker-ce"

inherit apparmor systemd

APPARMOR_PROFILES="${PN}.apparmor:${PN}"

SYSTEMD_PACKAGE = "${PN}"
SYSTEMD_SERVICE_${PN} = "${PN}.service"
SYSTEMD_AUTO_ENABLE_${PN} = "enable"

do_install() {
    install -d ${D}${sbindir}
    install ${WORKDIR}/authz.py ${D}${sbindir}/${PN}.py

    # install systemd unit files
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/${PN}.service ${D}${systemd_unitdir}/system/

    install -d ${D}${datadir}/${PN}
    cp ${WORKDIR}/filters/* ${D}${datadir}/${PN}/
}

FILES_${PN} += "${datadir}/${PN}"
