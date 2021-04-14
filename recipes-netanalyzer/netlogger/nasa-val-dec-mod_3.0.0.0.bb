SUMMARY = "netANALYZER backend library for netLOGGER"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

inherit autotools-brokensep

SRC_URI = "svn://subversion01.hilscher.local/svn/Netzwerkanalyse/netLOGGER/val_dec_mod/tags;module=${PV};protocol=https;user=${HILSCHER_SVN_USER};pswd=${HILSCHER_SVN_PSWD}"
SRCREV="8949"

S = "${WORKDIR}/${PV}"

do_install() {
    install -d ${D}/opt/nasa/standalone/bin
    install ${B}/.libs/libval_dec_mod-${PV}.so ${D}/opt/nasa/standalone/bin/libval_dec_mod.so
}

RDEPENDS_${PN} = "nasa-standalone"

FILES_${PN} = "/opt/nasa/standalone/bin"
