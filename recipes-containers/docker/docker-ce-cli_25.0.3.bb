HOMEPAGE = "http://www.docker.com"
SUMMARY = "Linux container runtime CLI"
DESCRIPTION = "Linux container runtime \
 Docker complements kernel namespacing with a high-level API which \
 operates at the process level. It runs unix processes with strong \
 guarantees of isolation and repeatability across servers. \
 . \
 Docker is a great building block for automating distributed systems: \
 large-scale web deployments, database clusters, continuous deployment \
 systems, private PaaS, service-oriented architectures, etc. \
 . \
 This package contains the daemon and client. Using docker.io is \
 officially supported on x86_64 and arm (32-bit) hosts. \
 Other architectures are considered experimental. \
 . \
 Also, note that kernel version 3.10 or above is required for proper \
 operation of the daemon process, and that any lower versions may have \
 subtle and/or glaring issues. \
 "

SRC_URI = "git://github.com/docker/cli.git;protocol=https;branch=25.0"
SRCREV="4debf411d1e6efbd9ce65e4250718e9c529a6525"

# CGO does not play well with thumb -> https://patches.openembedded.org/patch/144011/
TUNE_CCARGS:remove = "-mthumb"

# Apache-2.0 for docker
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=9740d093a080530b5c5c6573df9af45a"

S = "${WORKDIR}/git"

PACKAGES =+ "${PN}-bash-completion ${PN}-zsh-completion"

inherit go

export GOARCH="${TARGET_GOARCH}"

do_compile() {
	cd ${S}

	# Prepare go environment
	rm -rf ${WORKDIR}/.gopath
	mkdir -p ${WORKDIR}/.gopath/src/github.com/docker
	ln -sf ${S} ${WORKDIR}/.gopath/src/github.com/docker/cli
	export GOPATH="${WORKDIR}/.gopath/"

	# Build command line client
	export DISABLE_WARN_OUTSIDE_CONTAINER="1"
	LDFLAGS='' oe_runmake VERSION='${PV}' GITCOMMIT='${SRCREV}' dynbinary
}

do_install() {
	mkdir -p ${D}/${bindir}
	cp -L ${S}/build/docker ${D}/${bindir}/docker

	# bash completion
	install -d ${D}${sysconfdir}/bash_completion.d/
	install -m 0644 ${S}/contrib/completion/bash/docker ${D}${sysconfdir}/bash_completion.d/

	# zsh completion
	install -d ${D}${datadir}/zsh/site-functions/
	install -m 0644 ${S}/contrib/completion/zsh/_docker ${D}${datadir}/zsh/site-functions/
}

FILES:${PN} += "${datadir}"

FILES:${PN}-bash-completion = "${sysconfdir}/bash_completion.d/"
RDEPENDS:${PN}-bash-completion += "bash"

FILES:${PN}-zsh-completion = "${datadir}/zsh/site-functions"
RDEPENDS:${PN}-zsh-completion += "zsh"

# go.bbclass uses own unpack routine, which tries to unpack git modules that have a destsuffix
# as directories, below main source directory, which is not what we want
python do_unpack() {
    src_uri = (d.getVar('SRC_URI') or "").split()
    if len(src_uri) == 0:
        return

    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        fetcher.unpack(d.getVar('WORKDIR'))
    except bb.fetch2.BBFetchException as e:
        bb.fatal(str(e))
}

PROVIDES="docker-cli"
RPROVIDES:${PN}="docker-cli"
