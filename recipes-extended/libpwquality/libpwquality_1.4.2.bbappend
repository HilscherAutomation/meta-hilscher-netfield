do_install_append() {
    install -d ${D}${base_libdir}/security
    mv ${D}${libdir}/security/pam_pwquality.* ${D}${base_libdir}/security/
    rmdir ${D}${libdir}/security/
}

FILES_${PN}_append += "${base_libdir}/security"
