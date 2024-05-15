PACKAGECONFIG = " \
    ${@bb.utils.filter('DISTRO_FEATURES', 'polkit', d)} \
"

inherit useradd

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "--system --no-create-home --home-dir /var/lib/cockpit --shell /sbin/nologin --user-group cockpit-ws"

COCKPIT_WS_USER_GROUP = "cockpit-ws"
