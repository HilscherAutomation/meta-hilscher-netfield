FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
	file://90-dhcp-default.network \
	file://90-usb0-dhcpd-default.network \
"

do_install:append() {
	install -d ${D}${systemd_unitdir}/network/
	for file in $(find ${WORKDIR} -maxdepth 1 -type f -name *.network); do
		install -m 0644 "$file" ${D}${systemd_unitdir}/network/
	done
}

FILES:${PN}:append = " ${systemd_unitdir}"
