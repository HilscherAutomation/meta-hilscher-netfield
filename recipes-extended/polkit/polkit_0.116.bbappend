FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append += "file://bind_use_of_cookies_to_specific.patch \
                   file://40-netfield.rules \
"

do_install_append() {
    install -m 0644 ${WORKDIR}/40-netfield.rules ${D}${sysconfdir}/polkit-1/rules.d/

    # Make sure polkit is not oom-killed so cockpit can correctly detect permissions
    sed -i -e 's/\[Service\]/\[Service\]\nOOMScoreAdjust=-1000/g' \
              ${D}${systemd_system_unitdir}/polkit.service
}
