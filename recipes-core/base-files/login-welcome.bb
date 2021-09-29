SUMMARY="Show a welcome banner on console logins"
LICENSE="CLOSED"

inherit allarch
SRC_URI += "file://issue"

do_install() {
    install -d ${D}${libdir}
    install ${WORKDIR}/issue ${D}${libdir}/issue
}

FILES_${PN} = "${libdir}/issue"
