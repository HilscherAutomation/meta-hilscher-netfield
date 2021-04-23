FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append += " \
	file://90-dhcp-default.network \
	file://90-usb0-dhcpd-default.network \
"

do_install_append() {
	install -d ${D}${systemd_unitdir}/network/
	for file in $(find ${WORKDIR} -maxdepth 1 -type f -name *.network); do
		install -m 0644 "$file" ${D}${systemd_unitdir}/network/
	done
}

FILES_${PN}_append += "${systemd_unitdir}"
