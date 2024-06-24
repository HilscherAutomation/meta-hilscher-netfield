SUMMARY = "Production-Grade Container Scheduling and Management"
HOMEPAGE = "git://github.com/kubernetes/kubernetes;branch=master;protocol=https"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM="file://src/github.com/kubernetes/kubernetes/LICENSE;md5=3b83ef96387f14655fc854ddc3c6bd57"

PV = "1.30.2"
CVE_VERSION = "1.30.2"

GO_IMPORT="github.com/kubernetes/kubernetes"

SRCREV_kubernetes = "39683505b630ff2121012f3c5b16215a1449d5ed"
SRCREV_release = "6583af34183777b52070d7723331d55c588a9c45"
SRC_URI = "git://github.com/kubernetes/kubernetes;branch=release-1.30;name=kubernetes;protocol=https \
           git://github.com/kubernetes/release;branch=master;name=release;destsuffix=git/release;protocol=https"

SRC_URI:append = " \
	file://0001-build-golang.sh-convert-remaining-go-calls-to-use.patch;patchdir=src/${GO_IMPORT} \
	file://0001-cross-don-t-build-tests-by-default.patch;patchdir=src/${GO_IMPORT} \
	file://0001-hack-lib-golang.sh-use-CC-from-environment.patch;patchdir=src/${GO_IMPORT} \
	file://cni-containerd-net.conflist \
	file://k8s-init \
	file://99-kubernetes.conf \
"

DEPENDS += " \
	coreutils-native \
	go-native \
"

inherit systemd
inherit go
inherit goarch
inherit cni_networking

do_compile() {
	export GOPATH="${S}/src/import/.gopath:${S}/src/import/vendor:${STAGING_DIR_TARGET}/${prefix}/local/go:${WORKDIR}/git/"
	cd ${S}/src/${GO_IMPORT}

	export GOTOOLCHAIN="local"
	export GOARCH="${TARGET_GOARCH}"
	export CGO_ENABLED="1"
	export CGO_CFLAGS="${CFLAGS} --sysroot=${STAGING_DIR_TARGET}"
	export CGO_LDFLAGS="${LDFLAGS} --sysroot=${STAGING_DIR_TARGET}"
	export CFLAGS=""
	export LDFLAGS=""
	export CC="${CC}"
	export LD="${LD}"
	export GOBIN=""
	export GOFLAGS="-v -mod=vendor -trimpath"

	# to limit what is built, use 'WHAT', i.e. make WHAT=cmd/kubelet
	make cross GO=${GO} CGO_FLAGS=${CGO_FLAGS} GOLDFLAGS="-s -w" KUBE_BUILD_PLATFORMS=${GOOS}/${GOARCH}
}

do_install() {
    install -d ${D}${bindir}
    install -d ${D}${systemd_unitdir}/system/
    install -d ${D}${systemd_unitdir}/system/kubelet.service.d/

    install -d ${D}${sysconfdir}/kubernetes/manifests/

    if [ "${TARGET_GOARCH}" = "amd64" ]; then
        install -m 755 -D ${S}/src/${GO_IMPORT}/_output/local/go/bin/* ${D}/${bindir}
    else
        install -m 755 -D ${S}/src/${GO_IMPORT}/_output/local/go/bin/${TARGET_GOOS}_${TARGET_GOARCH}/* ${D}/${bindir}
    fi

    install -m 0644 ${WORKDIR}/git/release/cmd/krel/templates/latest/kubelet/kubelet.service ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/git/release/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf ${D}${systemd_unitdir}/system/kubelet.service.d/

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
	install -d "${D}${BIN_PREFIX}${base_bindir}"
	install -m 755 "${WORKDIR}/k8s-init" "${D}${BIN_PREFIX}${base_bindir}"

	install -d ${D}${sysconfdir}/sysctl.d
	install -m 0644 "${WORKDIR}/99-kubernetes.conf" "${D}${sysconfdir}/sysctl.d"
    fi
}

CNI_NETWORKING_FILES ?= "${WORKDIR}/cni-containerd-net.conflist"

PACKAGES =+ "kubeadm kubectl kubelet kube-proxy ${PN}-misc ${PN}-host"

ALLOW_EMPTY:${PN} = "1"
INSANE_SKIP:${PN} += "ldflags already-stripped"
INSANE_SKIP:${PN}-misc += "ldflags already-stripped textrel"
INSANE_SKIP:${MLPREFIX}kubelet += "ldflags already-stripped textrel"

# Note: we are explicitly *not* adding docker to the rdepends, since we allow
#       backends like cri-o to be used.
RDEPENDS:${PN} += "kubeadm \
                   kubectl \
                   kubelet \
                   kubernetes-cni"

RDEPENDS:kubeadm = "kubelet kubectl cri-tools conntrack-tools"
FILES:kubeadm = "${bindir}/kubeadm ${systemd_unitdir}/system/kubelet.service.d/*"

RDEPENDS:kubelet = "iptables socat util-linux ethtool iproute2 ebtables iproute2-tc"
FILES:kubelet = "${bindir}/kubelet ${systemd_unitdir}/system/kubelet.service ${sysconfdir}/kubernetes/manifests/"

SYSTEMD_PACKAGES = "${@bb.utils.contains('DISTRO_FEATURES','systemd','kubelet','',d)}"
SYSTEMD_SERVICE:kubelet = "${@bb.utils.contains('DISTRO_FEATURES','systemd','kubelet.service','',d)}"
SYSTEMD_AUTO_ENABLE:kubelet = "enable"

FILES:kubectl = "${bindir}/kubectl"
FILES:kube-proxy = "${bindir}/kube-proxy"
FILES:${PN}-misc = "${bindir} ${sysconfdir}/sysctl.d"

ALLOW_EMPTY:${PN}-host = "1"
FILES:${PN}-host = "${BIN_PREFIX}${base_bindir}/k8s-init"
RDEPENDS:${PN}-host = "${PN}"

RRECOMMENDS:${PN} = "\
                     kernel-module-xt-addrtype \
                     kernel-module-xt-nat \
                     kernel-module-xt-multiport \
                     kernel-module-xt-conntrack \
                     kernel-module-xt-comment \
                     kernel-module-xt-mark \
                     kernel-module-xt-connmark \
                     kernel-module-vxlan \
                     kernel-module-xt-masquerade \
                     kernel-module-xt-statistic \
                     kernel-module-xt-physdev \
                     kernel-module-xt-nflog \
                     kernel-module-xt-limit \
                     kernel-module-nfnetlink-log \
                     "

COMPATIBLE_HOST = '(x86_64.*|arm.*|aarch64.*)-linux'

deltask compile_ptest_base
