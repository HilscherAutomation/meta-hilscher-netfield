do_install:append() {
    # Move kubelet to /usr/local/bin so it is replacable
    install -d ${D}/usr/local/bin
    mv ${D}${bindir}/kubelet ${D}/usr/local/bin/

    sed -e 's@/usr/bin/kubelet@/usr/local/bin/kubelet@g' \
        -i ${D}${systemd_system_unitdir}/kubelet.service
    sed -e 's@/usr/bin/kubelet@/usr/local/bin/kubelet@g' \
        -i ${D}${systemd_system_unitdir}/kubelet.service.d/10-kubeadm.conf
}

FILES:kubelet:append = " /usr/local/bin"
