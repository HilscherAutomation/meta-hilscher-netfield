SUMMARY="AxProtector Runtime für Linux"
HOMEPAGE="https://www.wibu.de"
LICENSE="CLOSED"

require debarch.inc
DEBARCH="${@get_deb_arch(d)}"

SRC_URI="file://${BPN}_${PV}_${DEBARCH}.deb;subdir=${BPN}-${PV}"

PACKAGES = "${PN} ${PN}-doc"

do_install() {
    cp -pr ${S}/* ${D}/

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
            mv ${D}${libdir}/arm-linux-gnu/* ${D}${libdir}/
            rmdir ${D}${libdir}/arm-linux-gnu
            ;;
        *)
            bbfatal "Unsupported arch: ${DEBARCH}"
            ;;
    esac

    chown 0:0 -R ${D}/*
}

FILES:${PN} += "${libdir}"
INSANE_SKIP:${PN} = "already-stripped"
INHIBIT_PACKAGE_DEBUG_SPLIT="1"
