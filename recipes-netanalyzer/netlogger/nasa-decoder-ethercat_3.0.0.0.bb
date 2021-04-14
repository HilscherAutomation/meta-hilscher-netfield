SUMMARY = "netANALYZER backend library for netLOGGER"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

inherit autotools-brokensep

SRC_URI = "svn://subversion01.hilscher.local/svn/Netzwerkanalyse/netLOGGER/decoder_ethercat/tags;module=${PV};protocol=https;user=${HILSCHER_SVN_USER};pswd=${HILSCHER_SVN_PSWD}"
SRCREV="8952"

S = "${WORKDIR}/${PV}"

do_install() {
    install -d ${D}/opt/nasa/standalone/bin
    install ${B}/.libs/libecat_dec_mod-${PV}.so ${D}/opt/nasa/standalone/bin/libecat_dec_mod.so
}

RDEPENDS_${PN} = "nasa-standalone"

FILES_${PN} = "/opt/nasa/standalone/bin"
