do_install:append() {
    install -d ${D}${base_libdir}/security
    mv ${D}${libdir}/security/pam_pwquality.* ${D}${base_libdir}/security/
    rmdir ${D}${libdir}/security/
}

FILES:${PN}:append = " ${base_libdir}/security"
