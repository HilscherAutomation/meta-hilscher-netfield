FILESEXTRAPATHS:prepend := "${THISDIR}/cockpit:"
SRC_URI:append = "\
    file://wifi_helper \
    file://proxy_helper \
    file://docker_network_helper \
    file://iotedge_check_helper \
    file://iotedge_get_modules \
"

inherit apparmor
APPARMOR_PROFILES="\
    wifi_helper.apparmor:usr.libexec.cockpit.wifi_helper \
    proxy_helper.apparmor:usr.libexec.cockpit.proxy_helper \
    docker_network_helper.apparmor:usr.libexec.cockpit.docker_network_helper \
    iotedge_check_helper.apparmor:usr.libexec.cockpit.iotedge_check_helper \
    iotedge_get_modules.apparmor:usr.libexec.cockpit.iotedge_get_modules \
"

do_install:append() {
    install -d ${D}/usr/libexec/cockpit/
    install -d ${D}${sysconfdir}/sudoers.d

    for helper in proxy_helper wifi_helper docker_network_helper iotedge_check_helper iotedge_get_modules; do
        install -m 0774 ${WORKDIR}/$helper ${D}/usr/libexec/cockpit/
        # Allow netadmin group do call cockpit nework helpers as sudo
        echo "%netadmin ALL=(ALL:ALL) NOPASSWD: /usr/libexec/cockpit/$helper" >> ${D}${sysconfdir}/sudoers.d/cockpit-netadmin
    done
    chmod 0640 ${D}${sysconfdir}/sudoers.d/cockpit-netadmin

    # Cockpit requires write access to timesyncd configuration and netadmin use
    install -d ${D}${sysconfdir}/systemd/timesyncd.conf.d
    install -d ${D}${libdir}/tmpfiles.d
    cat <<EOF> ${D}${libdir}/tmpfiles.d/cockpit-timesyncd.conf
d ${sysconfdir}/systemd/timesyncd.conf.d 0775 root timeadmin -
z ${sysconfdir}/systemd/timesyncd.conf.d 0775 root timeadmin
z ${sysconfdir}/systemd/timesyncd.conf.d/* 0664 root timeadmin
EOF
}

# Required to patch toml
RDEPENDS:${PN}:append = " python3-toml"
