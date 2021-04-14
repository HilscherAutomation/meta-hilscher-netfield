SUMMARY="Helper scripts for netfield images to perform a complete system backup (system+data partition)"
LICENSE="CLOSED"

SRC_URI="file://fsa_backup \
         file://fsa_restore \
"

inherit allarch
PACKAGES="${PN}"

do_install() {
    install -d ${D}${sbindir}

    for helper in fsa_backup fsa_restore; do
        install ${WORKDIR}/$helper ${D}${sbindir}/$helper
    done
}

FILES_${PN} = "${sbindir}"
