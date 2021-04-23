FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# As hwrevision is machine specific, swupdate package must be machine specific
PACKAGE_ARCH = "${MACHINE_ARCH}"

# helper.lua is using rsync, so make sure it is available
RDEPENDS_${PN}_append += "rsync"

SWUPDATE_SIGN ??= "${PLATFORM_SIGN}"
SWUPDATE_KEYDIR ??= "${PLATFORM_KEYDIR}"
SWUPDATE_KEYNAME ??= "${PLATFORM_KEYNAME}"

SRC_URI_append += " \
	${@bb.utils.contains('SWUPDATE_SIGN', '1', 'file://enable_signed_images.cfg', '', d)} \
	file://enable_download.cfg \
	file://swupdate-args.sh \
	${@bb.utils.contains('SWUPDATE_SIGN', '1', 'file://public-key.sh', '', d)} \
	file://oom-score-adjust.patch;patchdir=../ \
"

DEPENDS_append += "${@bb.utils.contains('SWUPDATE_SIGN', '1', 'openssl-native', '', d)}"

do_compile[vardeps] += "SWUPDATE_SIGN SWUPDATE_KEYDIR SWUPDATE_KEYNAME"
do_compile_append() {
	if [ "${@bb.utils.contains('SWUPDATE_SIGN', '1', 'true', 'false', d)}" = "true" ]; then
		priv_key="${SWUPDATE_KEYDIR}/${SWUPDATE_KEYNAME}.key"
		[ ! -e "$priv_key" ] && bbfatal "Signing key $priv_key not found"

		openssl rsa -in $priv_key -pubout > ${WORKDIR}/${SWUPDATE_KEYNAME}.pub.key
	fi
}

do_install_append () {
	board="$(echo ${MACHINE} | sed 's/-rev[0-9]*//')"
	rev="$(echo ${MACHINE} | grep -oe "-rev[0-9]*" | sed 's/-rev//')"
	rev="${rev:-0}"

	# Create a hardware revision file.
	echo "$board $rev" > ${WORKDIR}/hwrevision
	install -d ${D}${sysconfdir}
	install -m 0644 ${WORKDIR}/hwrevision ${D}${sysconfdir}

	# Install an override script for generic swupdate configuration.
	install -d ${D}${libdir}/swupdate/conf.d
	install -m 0644 ${WORKDIR}/swupdate-args.sh ${D}${libdir}/swupdate/conf.d/10-swupdate-args.sh

	# Install an override script to enable the public key.
	if [ "${@bb.utils.contains('SWUPDATE_SIGN', '1', 'true', 'false', d)}" = "true" ]; then
		install -d ${D}${sysconfdir}/ssl
		install -m 0644 ${WORKDIR}/${SWUPDATE_KEYNAME}.pub.key ${D}${sysconfdir}/ssl
		ln -s ${SWUPDATE_KEYNAME}.pub.key ${D}${sysconfdir}/ssl/swupdate.pub.key

		install -m 0644 ${WORKDIR}/public-key.sh ${D}${libdir}/swupdate/conf.d/11-public-key.sh
	fi

	# Allow uploaded files to be up to 1GB
	sed -i -e 's/maxFilesize:256/maxFilesize:1024/g' ${D}/www/js/dropzone.min.js
}

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
