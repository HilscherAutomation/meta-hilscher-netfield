SUMMARY = "netANALYZER device driver for Hilscher netANALYZER devices"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

inherit autotools

SRC_URI = "svn://subversion01.hilscher.local/svn/EmbeddedOS/Drivers/netANALYZER/Linux/tags/;module=V${PV};protocol=https;user=${HILSCHER_SVN_USER};pswd=${HILSCHER_SVN_PSWD};externals=allowed"
SRCREV="12706"

S = "${WORKDIR}/V${PV}/libnetana/"

RDEPENDS_${PN} = "kernel-module-netanalyzer"

PR="r1"
