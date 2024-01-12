FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Always enable SSH
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN}-sshd:append = " libpam "

do_install:append() {
    sed -i -e 's/\[Service\]/\[Service\]\nOOMScoreAdjust=-1000/g' \
              ${D}${systemd_system_unitdir}/sshd@.service
}
