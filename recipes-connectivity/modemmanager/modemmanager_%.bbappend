do_install_append() {
    sed -i -e 's/\(ExecStart.*\)/\1 --log-journal/g' ${D}${systemd_system_unitdir}/ModemManager.service
}
