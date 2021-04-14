HOMEPAGE = "https://github.com/opencontainers/runc"
SUMMARY = "runc container cli tools"
DESCRIPTION = "runc is a CLI tool for spawning and running containers according to the OCI specification."

SRCREV = "12644e614e25b05da6fd08a38ffa0cfe1903fdec"
SRC_URI = "git://github.com/opencontainers/runc;protocol=https;branch=master \
           file://0001-Makefile-respect-GOBUILDFLAGS-for-runc-and-remove-re.patch \
"

# Apache-2.0 for runc
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://src/import/LICENSE;md5=435b266b3899aa8a959f17d41c56def8"

S = "${WORKDIR}/git"

PV .= "+git${SRCPV}"

inherit go
inherit goarch
require recipes-devtools/go/fix_go_cache.inc
inherit pkgconfig

PACKAGECONFIG ??= "seccomp"
PACKAGECONFIG[seccomp] = "seccomp,,libseccomp"
# This PACKAGECONFIG serves the purpose of whether building runc as static or not
PACKAGECONFIG[static] = ""

# apparmor and selinux are always build in runc 1.0.0-rc93+
DEPENDS = "apparmor"

GO_IMPORT = "import"

LIBCONTAINER_PACKAGE="github.com/opencontainers/runc/libcontainer"

do_configure[noexec] = "1"
EXTRA_OEMAKE="BUILDTAGS='${PACKAGECONFIG_CONFARGS}' GO=${GO}"

do_compile() {
    # Set GOPATH. See 'PACKAGERS.md'. Don't rely on
    # docker to download its dependencies but rather
    # use dependencies packaged independently.
    cd ${S}/src/import
    rm -rf .gopath

    dpath=".gopath/src/github.com/opencontainers/runc/"
    mkdir -p $dpath
    for package in libcontainer types; do
        ln -sf ../../../../../$package $dpath/$package
    done
    export GOPATH="${S}/src/import/.gopath:${S}/src/import/vendor:${STAGING_DIR_TARGET}/${prefix}/local/go"

    # Fix up symlink for go-cross compiler
    rm -f ${S}/src/import/vendor/src
    ln -sf ./ ${S}/src/import/vendor/src

    # Pass the needed cflags/ldflags so that cgo
    # can find the needed headers files and libraries
    export CGO_ENABLED="1"
    export CGO_CFLAGS="${CFLAGS} --sysroot=${STAGING_DIR_TARGET}"
    export CGO_LDFLAGS="${LDFLAGS} --sysroot=${STAGING_DIR_TARGET}"
    export GO=${GO}
    export COMMIT="${SRCREV}"

    export CFLAGS=""
    export LDFLAGS=""

    if ${@bb.utils.contains('PACKAGECONFIG', 'static', 'true', 'false', d)}; then
        oe_runmake static
    else
        oe_runmake runc
    fi
}

do_install() {
    mkdir -p ${D}/${bindir}

    cp ${S}/src/import/runc ${D}/${bindir}/runc
    ln -sf runc ${D}/${bindir}/docker-runc
}
