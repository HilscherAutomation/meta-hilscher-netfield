FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append += " \
	file://only_allow_root.patch \
	file://enable_suricatta_hackbit.cfg \
	file://socket_paths.cfg \
	file://tmpdir.sh \
	file://sw-versions.sh \
	file://hawkbit.sh \
"

do_install_prepend() {
	if ${SWUPDATE_MONGOOSE}; then
		if [ "${@bb.utils.contains('IMAGE_FEATURES', 'debug-tweaks', 'true', 'false',d)}" = "false" ]; then
			# Disable mongoose webserver
			sed -i 's,^,#,g' ${WORKDIR}/*mongoose*
		fi
	fi
}

do_install_append () {
	install -d ${D}${libdir}/swupdate/conf.d
	install -m 0644 ${WORKDIR}/tmpdir.sh ${D}${libdir}/swupdate/conf.d/01-tmpdir.sh
	install -m 0644 ${WORKDIR}/sw-versions.sh ${D}${libdir}/swupdate/conf.d/02-sw-versions.sh

	# Due to the public-key is provided by device-data, we remove the key file and replace the link.
	if [ "${@bb.utils.contains('SWUPDATE_SIGN', '1', 'true', 'false', d)}" = "true" ]; then
		rm ${D}${sysconfdir}/ssl/${SWUPDATE_KEYNAME}.pub.key
		ln -sf /sys/device_data/publickey ${D}${sysconfdir}/ssl/swupdate.pub.key
	fi

	# Install hawkbit helper script
	install -m 644 ${WORKDIR}/hawkbit.sh ${D}${libdir}/swupdate/conf.d/20-hawkbit.sh
}

RDEPENDS_${PN}_append += "jq libconfig-lsconfig"
