SUMMARY = "iotedged"
HOMEPAGE = "https://github.com/Azure/iotedge"
LICENSE = "MIT"
LIC_FILES_CHKSUM="file://../LICENSE;md5=0f7e3b1308cb5c00b372a6e78835732d"

DEPENDS_append += "libstd-rs"

# Configuration fails due to if (WIN32 AND (...) in c-shared/CMakelist
# | CMake Error at deps/c-shared/CMakeLists.txt:267 (if):
# |   if given arguments:
# |
# |     "WIN32" "AND" "(" "VERSION_EQUAL" "10.0.17763.0" "OR" "VERSION_GREATER" "10.0.17763.0" ")"
# |
# |   Unknown arguments specified
EXTRA_OECMAKE += "-DCMAKE_SYSTEM_VERSION=3"

# Make sure libiothsm is not build by cargo, but by us
export LIBIOTHSM_NOBUILD="1"

do_configure_append() {
    cd ${S}
    cargo_do_configure
}

do_compile_append() {
    cd ${S}
    mkdir -p target/release/deps
    rm -f target/release/deps/libiothsm.so target/release/deps/libutpm.so target/release/deps/libaziotsharedutil.so ${STAGING_LIBDIR}/rust/libiothsm.so
    ln -s ${WORKDIR}/build/libiothsm.so ${STAGING_LIBDIR}/rust/libiothsm.so
    ln -s ${WORKDIR}/build/deps/utpm/libutpm.so target/release/deps/libutpm.so
    ln -s ${WORKDIR}/build/deps/c-shared/libaziotsharedutil.so target/release/deps/libaziotsharedutil.so

    export VERSION=$(cat version.txt)

    cargo_do_compile
}

inherit pkgconfig
DEPENDS="openssl curl"

# Fix problem during compile (seems like CXXFLAGS are used for C code as well):
#  cc1: error: command line option '-fvisibility-inlines-hidden' is valid to C++/ObjC++ but not for C
CXXFLAGS_remove += "-fvisibility-inlines-hidden"

inherit cmake
OECMAKE_SOURCEPATH="${S}/hsm-sys/azure-iot-hsm-c"
EXTRA_OECMAKE+="-DBUILD_SHARED=1"
# libuuid is required by hsm-sys
DEPENDS += "util-linux"

inherit systemd
SYSTEMD_AUTO_ENABLE = "disable"
SYSTEMD_SERVICE_${PN} = "iotedge.service iotedge.mgmt.socket iotedge.socket"

inherit useradd
USERADD_PACKAGES="${PN}"
USERADD_PARAM_${PN} = "--system --no-create-home --home-dir /var/lib/iotedge --shell /bin/false --user-group --groups docker iotedge;"
GROUPADD_PARAM_${PN} = "-r docker;"

do_install_append() {
  install -d ${D}${sysconfdir}/iotedge ${D}${sysconfdir}/logrotate.d ${D}${systemd_system_unitdir}
  install -m 0644 ${S}/contrib/config/linux/debian/config.yaml ${D}${sysconfdir}/iotedge/
  install -m 0644 ${S}/contrib/config/linux/logrotate ${D}${sysconfdir}/logrotate.d/iotedge
  for systemd_unit in iotedge.service iotedge.socket iotedge.mgmt.socket; do
    install -m 0644 ${S}/contrib/systemd/debian/$systemd_unit ${D}${systemd_system_unitdir}
  done

  # Make sure to start docker as well
  sed -i -e 's/After=network-online.target/After=docker.socket network-online.target/g' \
         -e 's/Requires=network-online.target/Requires=docker.socket network-online.target/g' ${D}${systemd_system_unitdir}/iotedge.service

  install -d ${D}${bindir} ${D}${localstatedir}/lib/iotedge
  chown iotedge:iotedge ${D}${localstatedir}/lib/iotedge
  install ${B}/${HOST_SYS}/release/iotedged ${D}${bindir}
  install ${B}/${HOST_SYS}/release/iotedge ${D}${bindir}
}

RDEPENDS_${PN} = "docker openssl procps"
PACKAGES="${PN}"
FILES_${PN} = "${bindir} ${sysconfdir} ${libdir} ${localstatedir}"
INHIBIT_PACKAGE_DEBUG_SPLIT="1"

# Some string formatting error occur on ARM platforms
SECURITY_STRINGFORMAT = ""

# /usr/lib/libiothsm.so causes Q/A issue: non -dev/-dbg/nativesdk- package contains symlink .so
INSANE_SKIP="dev-so"
