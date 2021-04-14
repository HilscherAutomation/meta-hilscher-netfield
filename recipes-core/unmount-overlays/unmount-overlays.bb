SUMMARY="Service to unmount all overlays on shutdown"
LICENSE="CLOSED"

inherit allarch
PACKAGES="${PN}"

SRC_URI="file://unmount-template.mount"

do_install() {
	install -d ${D}${systemd_system_unitdir}
	for overlay in ${NETIOT_OVERLAY_DIRS}; do
		overlayname=$(echo ${overlay} | tr '/' '-')
		install -m 0644 ${WORKDIR}/unmount-template.mount ${D}${systemd_system_unitdir}/$overlayname.mount
		sed -i -e "s;@OVERLAY@;/${overlay};g" \
			${D}${systemd_system_unitdir}/${overlayname}.mount

		install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants/
		ln -s ${systemd_system_unitdir}/${overlayname}.mount ${D}/etc/systemd/system/multi-user.target.wants/${overlayname}.mount
	done
}


FILES_${PN} = "${systemd_system_unitdir} ${sysconfdir}"
