require recipes-devtools/go/fix_go_cache.inc

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI_append += "file://docker.rules"

SRC_URI_append += "\
   file://0001-hack-Add-reading-of-user-credentials-from-socket.patch \
   file://0002-Allow-docker-readonly-group-to-access-docker-socket.patch \
"

DOCKER_BUILDTAGS_append += "exclude_graphdriver_devicemapper exclude_graphdriver_aufs exclude_graphdriver_zfs exclude_graphdriver_overlay"
DEPENDS_remove_class-target += "libdevmapper"

do_install_append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -d ${D}${libdir}/tmpfiles.d/
        cat <<EOF>> ${D}${libdir}/tmpfiles.d/docker_overlay.conf
d /run/overlay/docker 0755 root root -
L+ /var/lib/docker - - - - /run/overlay/docker
EOF

        cat <<EOF>> ${D}${libdir}/tmpfiles.d/docker_netadmin.conf
d ${sysconfdir}/docker/ 0775 root netadmin -
z ${sysconfdir}/docker/ 0775 root netadmin
z ${sysconfdir}/docker/daemon.json 0664 root netadmin
EOF

        # Use journald as logging driver, which supports log rotation
        install -d ${D}${sysconfdir}/docker
        echo '{' > ${D}${sysconfdir}/docker/daemon.json
        echo '  "log-driver": "journald",' >> ${D}${sysconfdir}/docker/daemon.json
        echo '  "bip": "10.252.254.1/24",' >> ${D}${sysconfdir}/docker/daemon.json
        echo '  "default-address-pools": [' >> ${D}${sysconfdir}/docker/daemon.json
        echo '    {' >> ${D}${sysconfdir}/docker/daemon.json
        echo '      "base": "10.254.0.1/16",' >> ${D}${sysconfdir}/docker/daemon.json
        echo '      "size": 24' >> ${D}${sysconfdir}/docker/daemon.json
        echo '    }' >> ${D}${sysconfdir}/docker/daemon.json
        echo '  ]' >> ${D}${sysconfdir}/docker/daemon.json
        echo '}' >> ${D}${sysconfdir}/docker/daemon.json
    else
        install -d ${D}${sysconfdir}/default/volatiles
        cat <<EOF>> ${D}${sysconfdir}/default/volatiles/docker_overlay
d root root 0755 /run/overlay/docker none
l root root 0755 /var/lib/docker /run/overlay/docker
EOF
    fi

    install -d ${D}${base_libdir}/udev/rules.d/
    install -m 0644 ${WORKDIR}/docker.rules ${D}${base_libdir}/udev/rules.d/80-docker.rules
}

# acl is required to apply ACL on socket startup
RDEPENDS_${PN}_append += "acl"
FILES_${PN}_append += "${base_libdir}/udev/rules.d/ \
                       ${libdir}/tmpfiles.d"
