FILESEXTRAPATHS_prepend := "${THISDIR}/cockpit:"
SRC_URI_append += "\
    file://wifi_helper \
    file://proxy_helper \
"

inherit apparmor
APPARMOR_PROFILES="\
    wifi_helper.apparmor:usr.libexec.cockpit.wifi_helper \
    proxy_helper.apparmor:usr.libexec.cockpit.proxy_helper \
"

do_install_append() {
    install -d ${D}/usr/libexec/cockpit/
    install -d ${D}${sysconfdir}/sudoers.d

    for helper in proxy_helper wifi_helper; do
        install -m 0774 ${WORKDIR}/$helper ${D}/usr/libexec/cockpit/
        # Allow netadmin group do call cockpit nework helpers as sudo
        echo "%netadmin ALL=(ALL:ALL) NOPASSWD: /usr/libexec/cockpit/$helper" >> ${D}${sysconfdir}/sudoers.d/cockpit-netadmin
    done
}
