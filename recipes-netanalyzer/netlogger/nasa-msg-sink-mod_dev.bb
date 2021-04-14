SUMMARY = "netANALYZER push to mqtt library for netLOGGER"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

inherit autotools-brokensep cmake

OECMAKE_SOURCEPATH="${S}/msg_sink_mod/paho-mqtt/"

SRC_URI = "svn://subversion01.hilscher.local/svn/Netzwerkanalyse/netLOGGER/msg_sink_mod;module=trunk;protocol=https;user=${HILSCHER_SVN_USER};pswd=${HILSCHER_SVN_PSWD} \
           file://publish_to_local_mqtt_broker.patch \
           file://octet_string_no_printf.patch \
"

SRCREV="10185"

S = "${WORKDIR}/trunk"

do_configure_append() {
    cd ${S}
    autoreconf -Wcross --verbose --install --force
    oe_runconf
}

do_compile_append() {
    cd ${S}
    oe_runmake
}

do_install() {
    install -d ${D}/opt/nasa/standalone/bin
    install ${S}/.libs/libmsg_sink_mod-*.so ${D}/opt/nasa/standalone/bin/libmsg_sink_mod.so
    cp -L ${B}/libpaho-mqtt3c.so ${D}/opt/nasa/standalone/bin/
}

RDEPENDS_${PN} = "nasa-standalone"

FILES_${PN} = "/opt/nasa/standalone/bin"
