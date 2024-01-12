FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Move policies to /usr/share (read-only area)
EXTRA_OECONF:append = " --with-dbus-sys-dir=${datadir}/dbus-1/system.d"

SRC_URI:append = " file://networkmanager_readline5.patch \
                   file://balena-client-id.patch \
                   file://remove_cifx_tun_persistance.patch \
"

RDEPENDS:${PN}:append = " networkmanager-conf"
