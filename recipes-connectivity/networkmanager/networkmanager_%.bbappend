FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append += "file://networkmanager_readline5.patch \
                   file://balena-client-id.patch \
                   file://remove_cifx_tun_persistance.patch"

RDEPENDS_${PN}_append += "networkmanager-conf"

# Enable link-local fallback if DHCP server is unreachable by switching to
# dhcpcd and applying a patch as mentioned here: https://mail.gnome.org/archives/networkmanager-list/2009-April/msg00097.html
SRC_URI_append += "file://dhcpcd_enable_zeroconf.patch"
PACKAGECONFIG_append += "dhcpcd"
PACKAGECONFIG_remove += "dhclient"
PACKAGECONFIG[dhcpcd] = "--with-dhcpcd=${sbindir}/dhcpcd --with-config-dhcp-default=dhcpcd,,,dhcpcd"
