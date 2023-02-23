SRC_URI_append += " \
    file://earlyoom-defaults \
    file://make_high_prior.patch \
"

do_install_append() {
    install ${WORKDIR}/earlyoom-defaults ${D}${sysconfdir}/default/${BPN}
}
