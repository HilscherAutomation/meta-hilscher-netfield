SUMMARY="dockerd as a compliant Container Runtime Interface for Kubernetes"
HOMEPAGE="https://github.com/Mirantis/cri-dockerd"
LICENSE="Apache-2.0"

LIC_FILES_CHKSUM="file://src/${GO_IMPORT}/LICENSE;md5=3b83ef96387f14655fc854ddc3c6bd57"

GO_IMPORT = "github.com/Mirantis/cri-dockerd"
GO_INSTALL = "${GO_IMPORT}"

SRC_URI="git://${GO_IMPORT};protocol=https;branch=release/0.3"
SRCREV="683f70f69901e66d49dfac802841ff843171f131"

inherit go-mod systemd

SYSTEMD_PACKAGES="${PN}"
SYSTEMD_SERVICE:${PN} = "cri-docker.service cri-docker.socket"

export CRI_DOCKERD_LDFLAGS="-ldflags '-s -w -buildid=${SRCREV} \
        -X github.com/Mirantis/cri-dockerd/cmd/version.Version=${PV} \
        -X github.com/Mirantis/cri-dockerd/cmd/version.GitCommit=${SRCREV}'"

do_compile() {
    export GOARCH="${TARGET_GOARCH}"

    go build -mod=vendor -trimpath ${CRI_DOCKERD_LDFLAGS} -o ${B}/cri-dockerd
}

do_install() {
    install -d ${D}${bindir}
    install ${B}/cri-dockerd ${D}${bindir}/

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/src/${GO_IMPORT}/packaging/systemd/cri-docker.service ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/src/${GO_IMPORT}/packaging/systemd/cri-docker.socket ${D}${systemd_system_unitdir}
}

INSANE_SKIP:${PN} += "already-stripped textrel"
