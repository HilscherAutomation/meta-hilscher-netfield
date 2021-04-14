SUMMARY="Show a welcome banner on console logins"
LICENSE="CLOSED"

PACKAGE_ARCH="${MACHINE_ARCH}"

SRC_URI += "file://issue"

inherit hilscher-firmware-version

do_install() {
    install -d ${D}${libdir}
    sed -e "s;@VERSION@;${FULL_FW_VERSION};g" \
        -e "s;@MACHINE@;$(echo ${MACHINE} | tr [a-z] [A-Z]);g" \
            ${WORKDIR}/issue > ${D}${libdir}/issue
}

FILES_${PN} = "${libdir}/issue"
