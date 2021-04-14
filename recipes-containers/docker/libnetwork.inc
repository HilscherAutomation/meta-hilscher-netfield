FILESEXTRAPATHS_prepend := "${THISDIR}/libnetwork:"
SRCREV_libnetwork="${LIBNETWORK_COMMIT}"
SRC_URI_append += "git://github.com/docker/libnetwork.git;name=libnetwork;destsuffix=libnetwork;nobranch=1 \
                   file://0001-libnetwork-use-GO-instead-of-go.patch;patchdir=../"

S_LIBNETWORK = "${WORKDIR}/libnetwork"

export GOOS="linux"

do_compile_append() {
    # build the proxy
    cd ${S_LIBNETWORK}
    export GOPATH="${S_LIBNETWORK}/go/"
    rm -rf ${S_LIBNETWORK}/go/
    mkdir -p go/src/github.com/docker/
    ln -sf ${S_LIBNETWORK} go/src/github.com/docker/libnetwork
    cd go/src/github.com/docker/libnetwork

    oe_runmake cross-local
}

do_install_append() {
    cp ${S_LIBNETWORK}/bin/docker-proxy-$GOOS-$GOARCH ${D}/${bindir}/docker-proxy
}
