FILESEXTRAPATHS:prepend := "${THISDIR}/kubelet:"

SRC_URI:append = " \
    file://kubelet_use_config_dropins.patch;patchdir=${WORKDIR}/git/release \
    file://00-kubelet-allow-swap.conf \
"

do_install:append() {
    # Move kubelet to /usr/local/bin so it is replacable
    install -d ${D}/usr/local/bin
    mv ${D}${bindir}/kubelet ${D}/usr/local/bin/

    sed -e 's@/usr/bin/kubelet@/usr/local/bin/kubelet@g' \
        -i ${D}${systemd_system_unitdir}/kubelet.service
    sed -e 's@/usr/bin/kubelet@/usr/local/bin/kubelet@g' \
        -i ${D}${systemd_system_unitdir}/kubelet.service.d/10-kubeadm.conf

    install -d ${D}${sysconfdir}/kubernetes/kubelet.conf.d
    install -m 0640 ${WORKDIR}/00-kubelet-allow-swap.conf ${D}${sysconfdir}/kubernetes/kubelet.conf.d

    # Add plugin directory, as kubelet tries to create it, if not existing and it's read-only
    install -d ${D}/usr/libexec/kubernetes
}

pkg_postinst:kubelet () {
    # linux-loader is expected in /lib64 but yocto provides it in /lib per default (newer/mainline kubelets)
    if [ "${TARGET_ARCH}" = "x86_64" ]; then
        install -d $D/lib64
        ln -s "${@get_glibc_loader(d)}" $D/lib64/ld-linux-x86-64.so.2
    fi
}

# Disable kubelet, as we have no valid configuration
SYSTEMD_AUTO_ENABLE:kubelet = "disable"

FILES:kubelet:append = " \
    /usr/local/bin \
    ${sysconfdir}/kubernetes/kubelet.conf.d \
    /usr/libexec/kubernetes \
"
