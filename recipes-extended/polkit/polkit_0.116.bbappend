FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append += "file://bind_use_of_cookies_to_specific.patch \
                   file://60-network-manager.rules \
                   file://60-modem-manager.rules \
                   file://60-firewalld.rules \
                   file://60-timedatectl.rules \
                   file://99-netfield.rules \
"

inherit useradd

USERADD_PACKAGES="${PN}"
GROUPADD_PARAM_${PN} = "-r timeadmin;-r netadmin;"

do_install_append() {
    for rule in 60-network-manager.rules 60-modem-manager.rules 60-firewalld.rules 60-timedatectl.rules 99-netfield.rules; do
        install -m 0644 ${WORKDIR}/$rule ${D}${datadir}/polkit-1/rules.d
    done

    # Make sure polkit is not oom-killed so cockpit can correctly detect permissions
    sed -i -e 's/\[Service\]/\[Service\]\nOOMScoreAdjust=-1000/g' \
              ${D}${systemd_system_unitdir}/polkit.service
}
