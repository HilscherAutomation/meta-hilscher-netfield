SUMMARY = "netANALYZER backend library for netLOGGER"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

inherit autotools-brokensep

SRC_URI = "svn://subversion01.hilscher.local/svn/Netzwerkanalyse/netLOGGER/backend/tags;module=${PV};protocol=https;user=${HILSCHER_SVN_USER};pswd=${HILSCHER_SVN_PSWD}"
SRCREV="9813"

S = "${WORKDIR}/${PV}"

do_install() {
    install -d ${D}/opt/nasa/standalone/bin
    install ${B}/.libs/libbackend-${PV}.so ${D}/opt/nasa/standalone/bin/libbackend.so
}

RDEPENDS_${PN} = "nasa-standalone"

FILES_${PN} = "/opt/nasa/standalone/bin"
