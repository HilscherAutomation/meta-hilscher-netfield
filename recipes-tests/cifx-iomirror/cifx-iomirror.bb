DESCRIPTON="cifX / netX sample tool to mirror I/O data (e.g. for EMC tests)"
LICENSE="CLOSED"

SRC_URI = " \
    file://cifx-iomirror.c \
    file://cifx-iomirror.service \
"


inherit systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "cifx-iomirror.service"
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

do_compile() {
    ${CC} ${LDFLAGS} ${WORKDIR}/cifx-iomirror.c -I=/usr/include/cifx -lcifx -lpthread -lnl-cli-3 -o ${B}/cifx-iomirror
}

do_install() {
    install -d ${D}/opt/cifx/examples
    install ${B}/cifx-iomirror ${D}/opt/cifx/examples/

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/cifx-iomirror.service ${D}${systemd_system_unitdir}
}

DEPENDS = "libcifx libnl"
RDEPENDS:${PN} = "libcifx libnl"

FILES:${PN} = "/opt/cifx/"
