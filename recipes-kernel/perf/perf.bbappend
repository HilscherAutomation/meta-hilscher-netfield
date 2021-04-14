# Make sure no python2 is required
DEPENDS_append += "openssl"
PACKAGECONFIG_remove += "scripting"
PACKAGES_remove += "${PN}-python ${PN}-tests"

do_install_append() {
    rm -rf ${D}${libdir}/perf/perf-core/tests
    rm -rf ${D}${libexecdir}/perf-core/tests
}
