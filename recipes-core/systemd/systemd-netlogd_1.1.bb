SUMMARY="Forwards messages from the journal to other hosts over the network using syslog format RFC 5424 "
HOMEPAGE="https://github.com/systemd/systemd-netlogd"
LICENSE="GPLv2 & LGPL-2.1+"

LIC_FILES_CHKSUM="file://LICENSE.GPL2;md5=751419260aa954499f7abaabaa882bbe \
                  file://LICENSE.LGPL2.1;md5=4fbd65380cdd255951079008b364516c"

SRC_URI = "git://github.com/systemd/systemd-netlogd.git;protocol=https \
           file://disable_doc_generation.patch \
           file://fix_gettid.patch"
SRCREV="319a6393d96bce612bf8e559b9ab7260431332d3"

S="${WORKDIR}/git"

DEPENDS="systemd gperf libcap gperf-native"

inherit meson useradd

USERADD_PACKAGES="${PN}"
USERADD_PARAM:${PN}  = "-r -d / -s /bin/nologin -g systemd-journal systemd-journal-netlog"
GROUPADD_PARAM:${PN} = "-r systemd-journal"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    mv ${D}${sysconfdir}/*.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} += "${systemd_unitdir}"
