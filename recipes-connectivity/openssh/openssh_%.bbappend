FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Always enable SSH
SYSTEMD_AUTO_ENABLE = "enable"

do_install_append() {
    sed -i -e 's/\[Service\]/\[Service\]\nOOMScoreAdjust=-1000/g' \
              ${D}${systemd_system_unitdir}/sshd@.service
}
