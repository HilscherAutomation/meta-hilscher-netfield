HOMEPAGE = "https://github.com/containerd/containerd"
SUMMARY = "containerd is a daemon to control runC"
DESCRIPTION = "containerd is a daemon to control runC, built for performance and density. \
               containerd leverages runC's advanced features such as seccomp and user namespace \
               support as well as checkpoint and restore for cloning and live migration of containers."

# Apache-2.0 for containerd
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://src/import/LICENSE;md5=1269f40c0d099c21a871163984590d89"

SRCREV = "2806fc1057397dbaeefbea0e4e17bddfbd388f38"
SRC_URI = "git://github.com/containerd/containerd.git;protocol=https;branch=release/1.6 \
           file://0001-Makefile-allow-GO_BUILD_FLAGS-to-be-externally-speci.patch"
S = "${WORKDIR}/git"

PV .= "+git${SRCPV}"

inherit go
inherit goarch
inherit pkgconfig
require recipes-devtools/go/fix_go_cache.inc

GO_IMPORT = "import"

CONTAINERD_PKG="github.com/containerd/containerd"

BUILDTAGS = "selinux seccomp netgo"
BUILDTAGS +="${@bb.utils.contains('DISTRO_FEATURES','apparmor','apparmor','',d)}"

DEPENDS += "btrfs-tools"

do_configure[noexec] = "1"

do_compile() {
    export GOARCH="${TARGET_GOARCH}"

    export GOPATH="${S}/src/import/.gopath:${S}/src/import/vendor:${STAGING_DIR_TARGET}/${prefix}/local/go"
    export GOROOT="${STAGING_DIR_NATIVE}/${nonarch_libdir}/${HOST_SYS}/go"

    # Pass the needed cflags/ldflags so that cgo
    # can find the needed headers files and libraries
    export CGO_ENABLED="1"
    export CGO_CFLAGS="${CFLAGS} --sysroot=${STAGING_DIR_TARGET}"
    export CGO_LDFLAGS="${LDFLAGS} --sysroot=${STAGING_DIR_TARGET}"
    export BUILDTAGS="${BUILDTAGS}"
    export CFLAGS="${CFLAGS}"
    export LDFLAGS="${LDFLAGS}"
    export SHIM_CGO_ENABLED="${CGO_ENABLED}"
    # fixes:
    # cannot find package runtime/cgo (using -importcfg)
    #        ... recipe-sysroot-native/usr/lib/aarch64-poky-linux/go/pkg/tool/linux_amd64/link:
    #        cannot open file : open : no such file or directory
    export GO_BUILD_FLAGS="-a -pkgdir dontusecurrentpkgs"

    cd ${S}/src/import
    oe_runmake binaries
}

# Note: disabled for now, since docker is launching containerd
# inherit systemd
# SYSTEMD_PACKAGES = "${@bb.utils.contains('DISTRO_FEATURES','systemd','${PN}','',d)}"
# SYSTEMD_SERVICE_${PN} = "${@bb.utils.contains('DISTRO_FEATURES','systemd','containerd.service','',d)}"

do_install() {
    mkdir -p ${D}/${bindir}

    cp ${S}/src/import/bin/containerd ${D}/${bindir}/containerd
    cp ${S}/src/import/bin/containerd-shim ${D}/${bindir}/containerd-shim
    cp ${S}/src/import/bin/containerd-shim-runc-v2 ${D}/${bindir}/containerd-shim-runc-v2
    cp ${S}/src/import/bin/ctr ${D}/${bindir}/containerd-ctr

    ln -sf containerd ${D}/${bindir}/docker-containerd
    ln -sf containerd-shim ${D}/${bindir}/docker-containerd-shim
    ln -sf containerd-shim-runc-v2 ${D}/${bindir}/docker-containerd-shim-runc-v2
    ln -sf containerd-ctr ${D}/${bindir}/docker-containerd-ctr

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_unitdir}/system
        install -m 644 ${S}/src/${GO_IMPORT}/containerd.service ${D}/${systemd_unitdir}/system
        # adjust from /usr/local/bin to /usr/bin/
        sed -e "s:/usr/local/bin/containerd:${bindir}/docker-containerd:g" -i ${D}/${systemd_unitdir}/system/containerd.service
    fi
}

FILES_${PN} += "${systemd_system_unitdir}/*"
INSANE_SKIP_${PN} += "ldflags already-stripped"
