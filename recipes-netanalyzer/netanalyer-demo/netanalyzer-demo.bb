SUMMARY="netANALYZER sample application"
HOMEPAGE="http://www.hilscher.com"
LICENSE="CLOSED"

SRC_URI = "file://netanalyzer_demo.c"

S="${WORKDIR}"

DEPENDS="libnetana"

do_configure() {
    :
}

do_compile() {
    ${CC} ${LDFLAGS} netanalyzer_demo.c -o ${B}/netanalyzer_demo -I=/usr/include/netana -lnetana
}

do_install() {
    install -d ${D}/opt/netanalyzer
    install ${B}/netanalyzer_demo ${D}/opt/netanalyzer
}

FILES_${PN} = "/opt"
