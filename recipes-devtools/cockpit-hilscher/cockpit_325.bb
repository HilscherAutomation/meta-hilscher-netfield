SUMMARY = "Admin interface for Linux machines"
DESCRIPTION = "Cockpit makes it easy to administer your GNU/Linux servers via a web browser"

LICENSE = "LGPL-2.1-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=4fbd65380cdd255951079008b364516c"

require cockpit.inc
inherit gettext pkgconfig autotools systemd features_check
inherit ${@bb.utils.contains('PACKAGECONFIG', 'old-bridge', '', 'python3targetconfig', d)}

SRC_URI += " \
    git://github.com/HilscherAutomation/cockpit;protocol=https;branch=hilscher-features-325;name=cockpit \
    git://github.com/allisonkarlitskaya/systemd_ctypes.git;protocol=https;branch=main;destsuffix=git/vendor/systemd_ctypes;name=ctypes \
    git://github.com/cockpit-project/node-cache.git;protocol=https;nobranch=1;destsuffix=git/node_modules;name=node-cache \
    git://github.com/cockpit-project/pixel-test-reference;protocol=https;nobranch=1;destsuffix=git/test/reference;name=pixel-test-reference \
    git://github.com/allisonkarlitskaya/ferny;protocol=https;branch=main;destsuffix=git/vendor/ferny;name=ferny \
    git://github.com/allisonkarlitskaya/beipack;protocol=https;branch=main;destsuffix=git/vendor/beipack;name=beipack \
    file://0001-Warn-not-error-if-xsltproc-is-not-found.patch \
    file://0001-Makefile-common.am-Create-src-common-directory-befor.patch \
    file://0001-add-default-origin-with-port.patch \
    "

SRCREV_cockpit = "ecb85dd74529ff156d4c3f427ab134535b030e43"
SRCREV_ctypes = "c7df9c0114641e2063dc56608c4671fe73a984fb"
# Found via tags in node-cache repository
SRCREV_node-cache = "9110090aa24d4bfd435a0c7e283bafe1790481a0"
# Found via tags in pixel-test-reference repository
SRCREV_pixel-test-reference = "7d6df6174953038e7887ce8b89f55ef4c63e9bc1"
SRCREV_ferny = "c8713c4d3ba74a9d8db1ce8e0a15296e6a333257"
SRCREV_beipack = "4217d8ade60885a18156e86e566b808edad000ee"

S = "${WORKDIR}/git"

DEPENDS += "glib-2.0-native intltool-native virtual/gettext json-glib gnutls krb5 libpam systemd python3-setuptools-native nodejs-native"
DEPENDS += "${@bb.utils.contains('PACKAGECONFIG', 'old-bridge', '', 'python3-pip-native', d)}"

COMPATIBLE_HOST:libc-musl = "null"

RDEPENDS:${PN} += "glib-networking"

REQUIRED_DISTRO_FEATURES = "systemd pam"

COCKPIT_USER_GROUP ?= "root"

EXTRA_AUTORECONF = "-I tools"
EXTRA_OECONF = " \
    --with-admin-group=${COCKPIT_USER_GROUP} \
    --disable-doc \
    --with-systemdunitdir=${systemd_system_unitdir} \
    --with-pamdir=${base_libdir}/security \
    --enable-debug \
    --prefix=/usr \
"

PACKAGECONFIG[pcp] = ",,pcp"
PACKAGECONFIG[dashboard] = ",,libssh"
#PACKAGECONFIG[storaged] = ",,udisks2"

PACKAGES =+ " \
    ${PN}-pcp \
    ${PN}-realmd \
    ${PN}-tuned \
    ${PN}-shell \
    ${PN}-systemd \
    ${PN}-users \
    ${PN}-kdump \
    ${PN}-sosreport \
    ${PN}-storaged \
    ${PN}-networkmanager \
    ${PN}-selinux \
    ${PN}-playground \
    ${PN}-dashboard \
    ${PN}-packagekit \
    ${PN}-apps \
    ${PN}-bridge \
    ${PN}-ws \
    ${PN}-desktop \    
"
SYSTEMD_PACKAGES = "${PN}-ws"

FILES:${PN}-pcp = " \
    ${libexecdir}/cockpit-pcp \
    ${datadir}/cockpit/pcp \
    ${localstatedir}/lib/pcp/config/pmlogconf/tools/cockpit \
"
FILES:${PN}-realmd = "${datadir}/cockpit/realmd"
FILES:${PN}-tuned = "${datadir}/cockpit/tuned"
FILES:${PN}-shell = "${datadir}/cockpit/shell"
FILES:${PN}-systemd = "${datadir}/cockpit/systemd"
FILES:${PN}-users = "${datadir}/cockpit/users"
FILES:${PN}-kdump = " \
    ${datadir}/cockpit/kdump \
    ${datadir}/metainfo/org.cockpit_project.cockpit_kdump.metainfo.xml \
"
FILES:${PN}-sosreport = " \
    ${datadir}/cockpit/sosreport \
    ${datadir}/metainfo/org.cockpit_project.cockpit_sosreport.metainfo.xml \
    ${datadir}/pixmaps/cockpit-sosreport.png \
    ${datadir}/icons/hicolor/64x64/apps/cockpit-sosreport.png \
"
FILES:${PN}-storaged = " \
    ${datadir}/cockpit/storaged \
    ${datadir}/metainfo/org.cockpit_project.cockpit_storaged.metainfo.xml \
"

FILES:${PN}-networkmanager = " \
    ${datadir}/cockpit/networkmanager \
    ${datadir}/metainfo/org.cockpit_project.cockpit_networkmanager.metainfo.xml \
"
RDEPENDS:${PN}-networkmanager = "networkmanager"

FILES:${PN}-selinux = " \
    ${datadir}/cockpit/selinux \
    ${datadir}/metainfo/org.cockpit_project.cockpit_selinux.metainfo.xml \
"
FILES:${PN}-playground = "${datadir}/cockpit/playground"
FILES:${PN}-dashboard = "${datadir}/cockpit/dashboard"
ALLOW_EMPTY:${PN}-dashboard = "1"

FILES:${PN}-packagekit = "${datadir}/cockpit/packagekit"
FILES:${PN}-apps = "${datadir}/cockpit/apps"

FILES:${PN}-bridge = " \
    ${bindir}/cockpit-bridge \
    ${libexecdir}/cockpit-askpass \
    ${PYTHON_SITEPACKAGES_DIR} \
"
RDEPENDS:${PN}-bridge = "${@bb.utils.contains('PACKAGECONFIG', 'old-bridge', '', 'python3', d)}"

FILES:${PN}-desktop = "${libexecdir}/cockpit-desktop"
RDEPENDS:${PN}-desktop += "bash"

FILES:${PN}-ws = " \
    ${sysconfdir}/cockpit/ws-certs.d \
    ${sysconfdir}/pam.d/cockpit \
    ${sysconfdir}/issue.d/cockpit.issue \
    ${sysconfdir}/motd.d/cockpit \
    ${datadir}/cockpit/motd/update-motd \
    ${datadir}/cockpit/motd/inactive.motd \
    ${systemd_system_unitdir}/cockpit.service \
    ${systemd_system_unitdir}/cockpit-motd.service \
    ${systemd_system_unitdir}/cockpit.socket \
    ${systemd_system_unitdir}/cockpit-session.socket \
    ${systemd_system_unitdir}/cockpit-session@.service \
    ${systemd_system_unitdir}/cockpit-wsinstance-http.socket \
    ${systemd_system_unitdir}/cockpit-wsinstance-http.service \
    ${systemd_system_unitdir}/cockpit-wsinstance-http-redirect.socket \
    ${systemd_system_unitdir}/cockpit-wsinstance-http-redirect.service \
    ${systemd_system_unitdir}/cockpit-wsinstance-https-factory.socket \
    ${systemd_system_unitdir}/cockpit-wsinstance-https-factory@.service \
    ${systemd_system_unitdir}/cockpit-wsinstance-https@.socket \
    ${systemd_system_unitdir}/cockpit-wsinstance-https@.service \
    ${systemd_system_unitdir}/system-cockpithttps.slice \
    ${systemd_system_unitdir}/cockpit-session-socket-user.service \
    ${systemd_system_unitdir}/cockpit-wsinstance-socket-user.service \
    ${systemd_system_unitdir}/cockpit-issue.service \
    ${libdir}/tmpfiles.d/cockpit-tempfiles.conf \
    ${base_libdir}/security/pam_ssh_add.so \
    ${base_libdir}/security/pam_cockpit_cert.so \
    ${libexecdir}/cockpit-ws \
    ${libexecdir}/cockpit-wsinstance-factory \
    ${libexecdir}/cockpit-tls \
    ${libexecdir}/cockpit-session \
    ${localstatedir}/lib/cockpit \
    ${datadir}/cockpit/static \
    ${datadir}/cockpit/branding \
"
CONFFILES:${PN}-ws += " \
    ${sysconfdir}/issue.d/cockpit.issue \
    ${sysconfdir}/motd.d/cockpit \
"
RDEPENDS:${PN}-ws += "openssl-bin"
SYSTEMD_SERVICE:${PN}-ws = "cockpit.socket"

FILES:${PN} += " \
    ${datadir}/cockpit/base1 \
    ${sysconfdir}/cockpit/machines.d \
    ${datadir}/cockpit/ssh \
    ${libexecdir}/cockpit-ssh \
    ${datadir}/cockpit \
    ${datadir}/icons/hicolor/128x128/apps/cockpit.png \
    ${datadir}/metainfo/org.cockpit_project.cockpit.appdata.xml \
    ${datadir}/pixmaps/cockpit.png \
    ${nonarch_libdir}/tmpfiles.d \
    ${nonarch_libdir}/firewalld \
"
RDEPENDS:${PN} += "${PN}-bridge"
# Needs bash for /usr/libexec/cockpit-certificate-helper
RDEPENDS:${PN} += "bash"

do_configure:prepend() {
    PYTHON=${WORKDIR}/recipe-sysroot-native/usr/bin/python3-native/python3 sh ${S}/autogen.sh ${CONFIGUREOPTS} ${EXTRA_OECONF} $@
}

do_compile() {
    oe_runmake
    oe_runmake dist
}

do_install:append() {
    pkgdatadir=${datadir}/cockpit

    chmod 4750 ${D}${libexecdir}/cockpit-session

    # provided by firewalld
    rm -rf ${D}${libdir}/firewalld \
    ${D}${PYTHON_SITEPACKAGES_DIR}/*/__pycache__ \
    ${D}${PYTHON_SITEPACKAGES_DIR}/*/*/__pycache__ \
    ${D}${PYTHON_SITEPACKAGES_DIR}/*/*/*/__pycache__ \
    ${D}${PYTHON_SITEPACKAGES_DIR}/*/*/*/*/__pycache__ \
    ${D}${PYTHON_SITEPACKAGES_DIR}/${BP}.dist-info/direct_url.json

    if ! ${@bb.utils.contains('PACKAGECONFIG', 'storaged', 'true', 'false', d)}; then
        for filename in ${FILES:${PN}-storaged}
        do
            rm -rf ${D}$filename
        done
    fi
}
