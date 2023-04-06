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
	git://github.com/moby/moby.git;protocol=https;branch=23.0 \
	file://docker.init \
	file://hi.Dockerfile \
	"

SRCREV="59118bff500fc0d95d0560a9788735a8d89568ce"

# CGO does not play well with thumb -> https://patches.openembedded.org/patch/144011/
TUNE_CCARGS_remove += "-mthumb"

# Apache-2.0 for docker
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=4859e97a9c7780e77972d989f0823f28"

S = "${WORKDIR}/git"

PACKAGES =+ "${PN}-contrib ${PN}-bash-completion ${PN}-zsh-completion"

DEPENDS_append_class-target += "libseccomp lvm2 libdevmapper btrfs-tools libtool"

#exclude_graphdriver_btrfs
DOCKER_BUILDTAGS="seccomp pkcs11 selinux"

DEPENDS_append_class-target += "${@bb.utils.contains('DISTRO_FEATURES','apparmor','apparmor','',d)}"
DOCKER_BUILDTAGS +="${@bb.utils.contains('DISTRO_FEATURES','apparmor','apparmor','',d)}"

RDEPENDS_${PN} = "curl git util-linux iptables libseccomp \
                  ${@bb.utils.contains('DISTRO_FEATURES','systemd','','cgroup-lite',d)} \
                  docker-cli docker-init containerd (>= 1.2.10) runc \
                 "

RRECOMMENDS_${PN} = "kernel-module-dm-thin-pool kernel-module-nf-nat"
RSUGGESTS_${PN} = "lxc rt-tests"
DOCKER_PKG="github.com/docker/docker"

inherit systemd update-rc.d
inherit go
inherit pkgconfig

export GOARCH="${TARGET_GOARCH}"
# Prevent following error:
#  | no required module provides package github.com/docker/docker/cmd/dockerd: go.mod file not found in current directory or any parent directory; see 'go help modules' 
# See https://www.linuxquestions.org/questions/slackware-14/help-to-install-docker%5Berror-says-go-mod-not-found-4175693908/
export GO111MODULE="auto"

do_compile() {
	cd ${S}

	# Prepare go environment
	rm -rf ${WORKDIR}/.gopath
	mkdir -p ${WORKDIR}/.gopath/src/github.com/docker/
	ln -sf ${S} ${WORKDIR}/.gopath/src/github.com/docker/docker
	export GOPATH="${WORKDIR}/.gopath"

	# Build binary
	export DOCKER_BUILDTAGS="${DOCKER_BUILDTAGS}"
	export DOCKER_GITCOMMIT="${SRCREV}"
	export VERSION="${PV}"
	./hack/make.sh dynbinary
}

SYSTEMD_PACKAGES = "${@bb.utils.contains('DISTRO_FEATURES','systemd','${PN}','',d)}"
SYSTEMD_SERVICE_${PN} = "${@bb.utils.contains('DISTRO_FEATURES','systemd','docker.service','',d)}"

INITSCRIPT_PACKAGES += "${@bb.utils.contains('DISTRO_FEATURES','sysvinit','${PN}','',d)}"
INITSCRIPT_NAME_${PN} = "${@bb.utils.contains('DISTRO_FEATURES','sysvinit','docker.init','',d)}"
INITSCRIPT_PARAMS_${PN} = "${OS_DEFAULT_INITSCRIPT_PARAMS}"

do_install() {
	mkdir -p ${D}/${bindir}
	cp -L ${S}/bundles/dynbinary-daemon/dockerd ${D}/${bindir}/dockerd

	if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
		install -d ${D}${systemd_unitdir}/system
		install -m 644 ${S}/contrib/init/systemd/docker.* ${D}/${systemd_unitdir}/system
	else
		install -d ${D}${sysconfdir}/init.d
		install -m 0755 ${WORKDIR}/docker.init ${D}${sysconfdir}/init.d/docker.init
	fi

	mkdir -p ${D}${datadir}/docker/
	cp ${WORKDIR}/hi.Dockerfile ${D}${datadir}/docker/
	install -m 0755 ${S}/contrib/check-config.sh ${D}${datadir}/docker/
}

inherit useradd
USERADD_PACKAGES = "${PN}"
GROUPADD_PARAM_${PN} = "-r docker"

FILES_${PN} += "${systemd_unitdir}/system \
		${datadir}"

FILES_${PN}-contrib += "${datadir}/docker/check-config.sh"
RDEPENDS_${PN}-contrib += "bash"

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
RPROVIDES_${PN}="docker"
