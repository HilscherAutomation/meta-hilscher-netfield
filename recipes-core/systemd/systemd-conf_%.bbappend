do_install_append() {
    # Make sure kernel logs / audit logs are not printed to serial console
    install -d ${D}${sysconfdir}/sysctl.d
    echo "kernel.printk = 4" > ${D}${sysconfdir}/sysctl.d/printk.conf
    chmod 0600 ${D}${sysconfdir}/sysctl.d/printk.conf
}

FILES_${PN}_append += "${sysconfdir}/sysctl.d"
