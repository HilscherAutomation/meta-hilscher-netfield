FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append += "file://zshrc  \
                   file://zshenv \
                   file://zlogin \
"

EXTRA_OECONF_remove += "--disable-dynamic"
RDEPENDS_${PN}_append += "ncurses-terminfo"

# Make sure we override bash an be the default shell
ALTERNATIVE_PRIORITY="101"

do_install_append() {
    # Install basic environment
    install -d ${D}${sysconfdir}
    for file in zshrc zshenv zlogin; do
        install -m0644 ${WORKDIR}/$file ${D}${sysconfdir}/
    done
}

FILES_${PN}_append += "${sysconfdir}"
