# Per default it writes leases to /var/db/dhcpcd which is not writable and causes the following error:
#  Jan 26 08:27:31 ntdca632e4f057 dhcpcd[1391]: dhcp_bind: Read-only file system
EXTRA_OECONF_append += "--dbdir=${localstatedir}/lib/db/dhcpcd"

# Switch to MAC address as dhcp identificer. Default is DUID
do_install_append() {
    sed -i -e 's/^duid/#duid/g' -e 's/^#clientid$/clientid/g' ${D}${sysconfdir}/dhcpcd.conf
}
