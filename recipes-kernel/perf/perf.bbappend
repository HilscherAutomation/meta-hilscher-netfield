# Make sure no python2 is required
DEPENDS:append = " openssl"
PACKAGECONFIG:remove = "scripting"
PACKAGES:remove = "${PN}-python ${PN}-tests"

do_install:append() {
    rm -rf ${D}${libdir}/perf/perf-core/tests
    rm -rf ${D}${libexecdir}/perf-core/tests
}
