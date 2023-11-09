SUMMARY="Early OOM Daemon for Linux "
LICENSE="MIT"
HOMEPAGE="https://github.com/rfjakob/earlyoom"

LIC_FILES_CHKSUM="file://LICENSE;md5=875c33872f2633c48ce20e87d8cd3270"

SRC_URI="git://github.com/rfjakob/earlyoom.git;protocol=https"
SRCREV="ebaea9526bcee14889b00d83a9dd3d038315cee2"

S="${WORKDIR}/git"

inherit systemd

SYSTEMD_PACKAGES="${PN}"
SYSTEMD_SERVICE:${PN} = "${BPN}.service"

EXTRA_OEMAKE="DESTDIR=${D} PREFIX=/usr SYSTEMDUNITDIR=${systemd_system_unitdir}"

do_compile() {
    oe_runmake ${BPN}
}

do_install() {
    oe_runmake install

    # Remove executable flag from config files
    chmod -R -x ${D}${sysconfdir}
}
