SRC_URI:append = " \
    file://earlyoom-defaults \
    file://make_high_prior.patch \
"

do_install:append() {
    install ${WORKDIR}/earlyoom-defaults ${D}${sysconfdir}/default/${BPN}
}
