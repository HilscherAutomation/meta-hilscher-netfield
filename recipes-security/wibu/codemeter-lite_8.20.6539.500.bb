SUMMARY="CodeMeter User Runtime lite für Linux"
HOMEPAGE="https://www.wibu.de"
LICENSE="CLOSED"

require debarch.inc
DEBARCH="${@get_deb_arch(d)}"

SRC_URI="file://${BPN}_${PV}_${DEBARCH}.deb;subdir=${BPN}-${PV}"

# armhf package is missing User=daemon
SRC_URI:append:arm = " file://armhf_fix_service_user.patch"

inherit systemd
SYSTEMD_PACKAGES = "${PN} ${PN}-webadmin"
SYSTEMD_SERVICE:${PN} = "codemeter.service"
SYSTEMD_SERVICE:${PN}-webadmin = "codemeter-webadmin.service"

inherit useradd

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "--system --no-create-home --shell /sbin/nologin --user-group daemon"

PACKAGES = "${PN} ${PN}-doc ${PN}-webadmin ${PN}-bash-completion"

inherit linuxloader

do_install() {
    cp -pr ${S}/* ${D}/
    rm -rf ${D}/patches

    case ${DEBARCH} in
        amd64)
            rm -rf ${D}${libdir}/i386-linux-gnu/
            mv ${D}${libdir}/x86_64-linux-gnu/* ${D}${libdir}/
            rmdir ${D}${libdir}/x86_64-linux-gnu
            ;;
        arm64)
            mv ${D}${libdir}/aarch64-linux-gnu/* ${D}${libdir}/
            rmdir ${D}${libdir}/aarch64-linux-gnu
            ;;
        armhf)
            mv ${D}${libdir}/arm-linux-gnueabihf/* ${D}${libdir}/
            rmdir ${D}${libdir}/arm-linux-gnueabihf
            ;;
        *)
            bbfatal "Unsupported arch: ${DEBARCH}"
            ;;
    esac

    chown 0:0 -R ${D}/*

    chown daemon:daemon -R ${D}${sysconfdir}/wibu/CodeMeter
    chmod 0644 ${D}${sysconfdir}/wibu/CodeMeter/Server.ini

    chown daemon:daemon -R ${D}/var/lib/CodeMeter ${D}/var/log/CodeMeter

    # /var/spool/ctmp seems to be required when importing licenses
    install -m 0775 -d ${D}/var/spool/ctmp
    chown 0:daemon ${D}/var/spool/ctmp
}


pkg_postinst:${PN} () {
    # linux-loader is expected in /lib64 but yocto provides it in /lib per default
    # NOTE: Using patchelf does not work, as codemeter will detect signature modification and fail
    if [ "${DEBARCH}" = "amd64" ]; then
        if [ ! -e "$D/lib64/ld-linux-x86-64.so.2" ]; then
            install -d $D/lib64
            ln -s "${@get_glibc_loader(d)}" $D/lib64/ld-linux-x86-64.so.2
        fi
    fi
}

FILES:${PN} += "${libdir}"
RDEPENDS:${PN} += "libusb1 zlib"

FILES:${PN}-webadmin = " \
    ${sbindir}/CmWebAdmin \
    /var/lib/CodeMeter/WebAdmin \
    ${systemd_system_unitdir}/codemeter-webadmin.service \
"
RDEPENDS:${PN}-webadmin = "${PN}"

FILES:${PN}-bash-completion = "${datadir}/bash-completion"
RDEPENDS:${PN}-bash-completion = "bash"

INSANE_SKIP:${PN} = "already-stripped dev-so"
INSANE_SKIP:${PN}-webadmin = "already-stripped"
INHIBIT_PACKAGE_DEBUG_SPLIT="1"
