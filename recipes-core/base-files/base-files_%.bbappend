FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://mqtt-config.json"

do_install:append() {
    install -d ${D}${sysconfdir}/gateway
    install -m0644 ${WORKDIR}/mqtt-config.json ${D}${sysconfdir}/gateway/

    # Install tmpfiles.d fragment to adjust user rights on gateway setting files
    install -d ${D}${libdir}/tmpfiles.d/
    cat <<EOF> ${D}${libdir}/tmpfiles.d/gateway-settings.conf
d ${sysconfdir}/gateway/  0775 root netadmin -
z ${sysconfdir}/gateway/  0775 root netadmin
z ${sysconfdir}/gateway/* 0664 root netadmin
EOF
}

do_install_basefilesissue () {
    # Symlink /etc/issue to /usr/lib/issue to make sure the read only variant
    # is used which contains the real distro name and firmware version
    ln -s ${libdir}/issue ${D}${sysconfdir}/issue
    touch ${D}${sysconfdir}/issue.net
    chmod 0644 ${D}${sysconfdir}/issue.net
}
