SUMMARY="netANALYZER test application"
HOMEPAGE="http://www.hilscher.com"
LICENSE="CLOSED"

SRC_URI = "file://trunk/*"

S="${WORKDIR}/trunk"

DEPENDS="libnetana"

do_install() {
    install -d ${D}/opt/netanalyzer
    install ${B}/netana-test ${D}/opt/netanalyzer
}

FILES_${PN} = "/opt"
