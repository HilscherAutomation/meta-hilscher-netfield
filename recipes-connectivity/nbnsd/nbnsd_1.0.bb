SUMMARY  = "nbnsd - A minimal NetBIOS Name Service responder"
HOMEPAGE = "http://www.mostang.com/~davidm/nbnsd/nbnsd.c"
SECTION  = "net/misc"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://nbnsd.c;endline=24;md5=c3f2c1fba5d4fe63f8dac1f408f2c749"

SRC_URI = "file://nbnsd.c \
           file://update_hostname.patch \
           file://multi_interface_support.patch \
           file://nbnsd.service"

APPARMOR_PROFILES="nbnsd.apparmor:usr.sbin.nbnsd"

SYSTEMD_PACKAGES          = "${PN}"
SYSTEMD_SERVICE:${PN}     = "nbnsd.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

inherit apparmor systemd

S="${WORKDIR}"

do_compile() {
    ${CC} ${LDFLAGS} nbnsd.c -o nbnsd
}

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 nbnsd ${D}${sbindir}

    # install systemd unit files
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/nbnsd.service ${D}${systemd_unitdir}/system/
}

FILES:${PN} = "${sbindir} \
               ${systemd_unitdir}"
