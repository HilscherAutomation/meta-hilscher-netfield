SUMMARY = "netANALYZER backend library for netLOGGER"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

inherit autotools-brokensep

SRC_URI = "svn://subversion01.hilscher.local/svn/Netzwerkanalyse/netLOGGER/decoder_profinet/tags;module=${PV};protocol=https;user=${HILSCHER_SVN_USER};pswd=${HILSCHER_SVN_PSWD}"
SRCREV="9301"

S = "${WORKDIR}/${PV}"

do_install() {
    install -d ${D}/opt/nasa/standalone/bin
    install ${B}/.libs/libpn_dec_mod-${PV}.so ${D}/opt/nasa/standalone/bin/libpn_dec_mod.so
}

RDEPENDS_${PN} = "nasa-standalone"

FILES_${PN} = "/opt/nasa/standalone/bin"
