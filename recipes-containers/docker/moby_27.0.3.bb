HOMEPAGE = "http://www.docker.com"
SUMMARY = "Linux container runtime - Engine"
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

SRC_URI = "\
	git://github.com/moby/moby.git;protocol=https;branch=27.0;name=moby \
	git://github.com/docker/cli;branch=27.0;name=cli;destsuffix=git/cli;protocol=https \
	file://0001-dynbinary-use-go-cross-compiler.patch \
	file://docker.init \
	file://hi.Dockerfile \
	"

SRCREV_moby="662f78c0b1bb5114172427cfcb40491d73159be2"
SRCREV_cli="7d4bcd863a4c863e650eed02a550dfeb98560b83"

# CGO does not play well with thumb -> https://patches.openembedded.org/patch/144011/
TUNE_CCARGS:remove = "-mthumb"

# Apache-2.0 for docker
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=4859e97a9c7780e77972d989f0823f28 \
                    file://cli/LICENSE;md5=9740d093a080530b5c5c6573df9af45a"

S = "${WORKDIR}/git"

PACKAGES =+ "${PN}-contrib docker-bash-completion docker-zsh-completion"

DEPENDS:append:class-target = " libseccomp lvm2 libdevmapper btrfs-tools libtool"

#exclude_graphdriver_btrfs
DOCKER_BUILDTAGS="seccomp pkcs11 selinux"

DEPENDS:append:class-target = " ${@bb.utils.contains('DISTRO_FEATURES','apparmor','apparmor','',d)}"
DOCKER_BUILDTAGS +="${@bb.utils.contains('DISTRO_FEATURES','apparmor','apparmor','',d)}"

RDEPENDS:${PN} = "curl git util-linux iptables libseccomp \
                  ${@bb.utils.contains('DISTRO_FEATURES','systemd','','cgroup-lite',d)} \
                  docker-init containerd (>= 1.2.10) runc \
                 "

RRECOMMENDS:${PN} = "kernel-module-dm-thin-pool kernel-module-nf-nat"
RSUGGESTS:${PN} = "lxc rt-tests"
DOCKER_PKG="github.com/docker/docker"

inherit systemd update-rc.d
inherit go
inherit pkgconfig

export GOARCH="${TARGET_GOARCH}"

do_compile() {
	cd ${S}

	# Prepare go environment
	rm -rf ${WORKDIR}/.gopath
	mkdir -p ${WORKDIR}/.gopath/src/github.com/docker/
	ln -sf ${S} ${WORKDIR}/.gopath/src/github.com/docker/docker
	ln -sf ${S}/cli ${WORKDIR}/.gopath/src/github.com/docker/cli
	export GOPATH="${WORKDIR}/.gopath"

	# Build binary
	export DOCKER_BUILDTAGS="${DOCKER_BUILDTAGS}"
	export DOCKER_GITCOMMIT="${SRCREV_moby}"
	export VERSION="${PV}"
	./hack/make.sh dynbinary

	# Build cli
	cd ${S}/cli

	export DISABLE_WARN_OUTSIDE_CONTAINER="1"
	LDFLAGS='' oe_runmake VERSION='${PV}' GITCOMMIT='${SRCREV_cli}' dynbinary
}

SYSTEMD_PACKAGES = "${@bb.utils.contains('DISTRO_FEATURES','systemd','${PN}','',d)}"
SYSTEMD_SERVICE:${PN} = "${@bb.utils.contains('DISTRO_FEATURES','systemd','docker.service','',d)}"

INITSCRIPT_PACKAGES += "${@bb.utils.contains('DISTRO_FEATURES','sysvinit','${PN}','',d)}"
INITSCRIPT_NAME:${PN} = "${@bb.utils.contains('DISTRO_FEATURES','sysvinit','docker.init','',d)}"
INITSCRIPT_PARAMS:${PN} = "${OS_DEFAULT_INITSCRIPT_PARAMS}"

do_install() {
	install -d ${D}/${bindir}
	cp -L ${S}/bundles/dynbinary-daemon/dockerd ${D}/${bindir}/dockerd
	cp -L ${S}/bundles/dynbinary-daemon/docker-proxy ${D}/${bindir}/docker-proxy

	if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
		install -d ${D}${systemd_unitdir}/system
		install -m 644 ${S}/contrib/init/systemd/docker.* ${D}/${systemd_unitdir}/system
	else
		install -d ${D}${sysconfdir}/init.d
		install -m 0755 ${WORKDIR}/docker.init ${D}${sysconfdir}/init.d/docker.init
	fi

	install -d ${D}${datadir}/docker/
	cp ${WORKDIR}/hi.Dockerfile ${D}${datadir}/docker/
	install -m 0755 ${S}/contrib/check-config.sh ${D}${datadir}/docker/

	# CLI
	cp -L ${S}/cli/build/docker ${D}/${bindir}/docker

	# bash completion
	install -d ${D}${sysconfdir}/bash_completion.d/
	install -m 0644 ${S}/cli/contrib/completion/bash/docker ${D}${sysconfdir}/bash_completion.d/

	# zsh completion
	install -d ${D}${datadir}/zsh/site-functions/
	install -m 0644 ${S}/cli/contrib/completion/zsh/_docker ${D}${datadir}/zsh/site-functions/
}

inherit useradd
USERADD_PACKAGES = "${PN}"
GROUPADD_PARAM:${PN} = "-r docker"

FILES:${PN} += "${systemd_unitdir}/system \
		${datadir}"

FILES:${PN}-contrib += "${datadir}/docker/check-config.sh"
RDEPENDS:${PN}-contrib += "bash"

FILES:docker-bash-completion = "${sysconfdir}/bash_completion.d/"
RDEPENDS:docker-bash-completion += "bash"

FILES:docker-zsh-completion = "${datadir}/zsh/site-functions"
RDEPENDS:docker-zsh-completion += "zsh"

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

PROVIDES="docker"
RPROVIDES:${PN}="docker"
INSANE_SKIP:${PN}="textrel"

CVE_PRODUCT = "docker mobyproject:moby"
