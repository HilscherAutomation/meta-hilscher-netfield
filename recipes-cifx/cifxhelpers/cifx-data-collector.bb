SUMMARY = "Collect cifX device data"
LICENSE = "CLOSED"

SRC_URI = "file://cifx-data-collector.c"

DEPENDS = "libcifx libnl"
RDEPENDS:${PN} = "libcifx libnl"

S = "${WORKDIR}"

do_compile() {
             ${CC} ${LDFLAGS} -I=/usr/include/cifx/ cifx-data-collector.c -lcifx -lnl-cli-3 -o cifx-data-collector
}

do_install() {
             install -d ${D}${bindir}
             install -m 0755 cifx-data-collector ${D}${bindir}
}
