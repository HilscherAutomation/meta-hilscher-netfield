FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://zshrc  \
                   file://zshenv \
                   file://zlogin \
"

EXTRA_OECONF:remove = "--disable-dynamic"
RDEPENDS:${PN}:append = " ncurses-terminfo"

# Make sure we override bash an be the default shell
ALTERNATIVE_PRIORITY="101"

do_install:append() {
    # Install basic environment
    install -d ${D}${sysconfdir}
    for file in zshrc zshenv zlogin; do
        install -m0644 ${WORKDIR}/$file ${D}${sysconfdir}/
    done
}

FILES:${PN}:append = " ${sysconfdir}"
