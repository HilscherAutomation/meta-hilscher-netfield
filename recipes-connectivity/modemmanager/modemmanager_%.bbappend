do_install:append() {
    sed -i -e 's/\(ExecStart.*\)/\1 --log-journal/g' ${D}${systemd_system_unitdir}/ModemManager.service

    # No execution bits should be configured for udev rules!
    chmod -x ${D}${nonarch_base_libdir}/udev/rules.d/*
}
