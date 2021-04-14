SUMMARY="Scripts for btrfs maintenance tasks like periodic scrub, balance, trim or defrag on selected mountpoints or directories."
HOMEPAGE="https://github.com/kdave/btrfsmaintenance"
LICENSE="GPLv2"

LIC_FILES_CHKSUM="file://COPYING;md5=892f569a555ba9c07a568a7c0c4fa63a"

SRC_URI="git://github.com/kdave/btrfsmaintenance.git;protocol=https"
SRCREV="cf421fcadbbad9665ce3d14cba7d673d9386346d"

S="${WORKDIR}/git"

inherit systemd allarch

SYSTEMD_SERVICE_${PN} ="btrfs-scrub.timer btrfs-defrag.timer btrfs-balance.timer btrfs-trim.timer"

do_install() {
	install -d ${D}${datadir}/btrfsmaintenance
	install ${S}/btrfs-*.sh ${D}${datadir}/btrfsmaintenance
	install -m0644 ${S}/btrfsmaintenance-functions ${D}${datadir}/btrfsmaintenance

	install -d ${D}${sysconfdir}/default
	install ${S}/sysconfig.btrfsmaintenance ${D}${sysconfdir}/default/btrfsmaintenance

	install -d ${D}${systemd_system_unitdir}
	install -m0644 ${S}/*.service ${D}${systemd_system_unitdir}
	install -m0644 ${S}/*.timer ${D}${systemd_system_unitdir}
}

FILES_${PN} = "${datadir} ${sysconfdir} ${systemd_system_unitdir}"
