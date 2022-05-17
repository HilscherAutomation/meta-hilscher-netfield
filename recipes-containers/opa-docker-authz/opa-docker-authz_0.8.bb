SUMMARY="A policy-enabled authorization plugin for Docker. "
HOMEPAGE="https://www.openpolicyagent.org"

LICENSE="Apache-2.0"
LIC_FILES_CHKSUM="file://src/${GO_IMPORT}/LICENSE;md5=fa818a259cbed7ce8bc2a22d35a464fc"

GO_IMPORT = "github.com/open-policy-agent/opa-docker-authz"
GO_INSTALL = "${GO_IMPORT}"

SRC_URI = "git://${GO_IMPORT};protocol=https;nobranch=1 \
           file://${BPN}.service \
           file://authz.rego"
SRCREV="3d71d2a929e241c214a1a217971eca6b4735447c"

inherit go-mod systemd

SYSTEMD_PACKAGES="${PN}"
SYSTEMD_SERVICES_${PN} = "${BPN}.service"

inherit apparmor
APPARMOR_PROFILES="${BPN}.apparmor:usr.bin.${BPN}"

do_install_append() {
    # Remove libdir, as it is not required for anything
    rm -rf ${D}${libdir}

    install -d ${D}${sysconfdir}/docker/policies
    install -m 0644 ${S}/src/${GO_IMPORT}/example.rego ${D}${sysconfdir}/docker/policies/authz.rego

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/${BPN}.service ${D}${systemd_system_unitdir}
}

FILES_${PN} += "${systemd_system_unitdir}"
RDEPENDS_${PN} = "docker"
