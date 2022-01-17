SUMMARY="Helper scripts for netfield images to perform a complete system backup (system+data partition)"
LICENSE="CLOSED"

SRC_URI="file://fsa_backup \
         file://fsa_restore \
         file://fsa_info \
"

inherit allarch
PACKAGES="${PN}"

do_install() {
    install -d ${D}${sbindir}

    for helper in fsa_backup fsa_restore fsa_info; do
        install ${WORKDIR}/$helper ${D}${sbindir}/$helper
    done
}

FILES_${PN} = "${sbindir}"
