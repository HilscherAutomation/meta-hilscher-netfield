FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# As hwrevision is machine specific, swupdate package must be machine specific
PACKAGE_ARCH = "${MACHINE_ARCH}"

# helper.lua is using rsync, so make sure it is available
RDEPENDS:${PN}:append = " rsync"

# Required by hawkbit.sh
RDEPENDS:${PN}:append = " jq libconfig-lsconfig"

SWUPDATE_SIGN ??= "${PLATFORM_SIGN}"
SWUPDATE_KEYDIR ??= "${PLATFORM_KEYDIR}"
SWUPDATE_KEYNAME ??= "${PLATFORM_KEYNAME}"

export SWU_VER="${PV}"

SRC_URI:append = " \
	file://raw_file_skip_dev_null.patch \
	file://pass_swupdate_version.patch \
	${@bb.utils.contains('SWUPDATE_SIGN', '1', 'file://enable_signed_images.cfg', 'file://enable_hashed_images.cfg', d)} \
	file://enable_download.cfg \
	file://swupdate-args.sh \
	${@bb.utils.contains('SWUPDATE_SIGN', '1', 'file://public-key.sh', '', d)} \
	file://oom-score-adjust.patch;patchdir=../ \
	file://only_allow_root.patch \
	file://enable_suricatta_hackbit.cfg \
	file://socket_paths.cfg \
	file://tmpdir.sh \
	file://sw-versions.sh \
	file://hawkbit.sh \
	file://helper.lua \
"

do_install[vardeps] += "SWUPDATE_SIGN IMAGE_FEATURES"
do_install:append () {
	board="$(echo ${MACHINE} | sed 's/-rev[0-9]*//')"
	rev="$(echo ${MACHINE} | grep -oe "-rev[0-9]*" | sed 's/-rev//')"
	rev="${rev:-0}"

	# Create a hardware revision file.
	echo "$board $rev" > ${WORKDIR}/hwrevision
	install -d ${D}${sysconfdir}
	install -m 0644 ${WORKDIR}/hwrevision ${D}${sysconfdir}

	install -m 0644 ${WORKDIR}/tmpdir.sh ${D}${libdir}/swupdate/conf.d/01-tmpdir.sh
	install -m 0644 ${WORKDIR}/sw-versions.sh ${D}${libdir}/swupdate/conf.d/02-sw-versions.sh

	# Install an override script for generic swupdate configuration.
	install -d ${D}${libdir}/swupdate/conf.d
	install -m 0644 ${WORKDIR}/swupdate-args.sh ${D}${libdir}/swupdate/conf.d/10-swupdate-args.sh

	# Install an override script to enable the public key.
	if [ "${@bb.utils.contains('SWUPDATE_SIGN', '1', 'true', 'false', d)}" = "true" ]; then
		install -d ${D}${sysconfdir}/ssl

		# Due to the public-key is provided by device-data, we create link to this.
		ln -sf /sys/device_data/publickey ${D}${sysconfdir}/ssl/swupdate.pub.key

		install -m 0644 ${WORKDIR}/public-key.sh ${D}${libdir}/swupdate/conf.d/11-public-key.sh
	fi

	# Install hawkbit helper script
	install -m 644 ${WORKDIR}/hawkbit.sh ${D}${libdir}/swupdate/conf.d/20-hawkbit.sh

	# Allow uploaded files to be up to 1GB
	sed -i -e 's/maxFilesize:256/maxFilesize:1024/g' ${D}/www/js/dropzone.min.js

	if ${SWUPDATE_MONGOOSE}; then
		if [ "${@bb.utils.contains('IMAGE_FEATURES', 'debug-tweaks', 'true', 'false',d)}" = "false" ]; then
			# Disable mongoose webserver
			rm ${D}${libdir}/swupdate/conf.d/*mongoose*
		else
			bbwarn "Keeping mongoose webserver enabled as debug image is requested"
		fi
	fi
}

inherit deploy
do_deploy() {
	install -d ${DEPLOYDIR}/${PN}
	install -m 644 ${WORKDIR}/helper.lua ${DEPLOYDIR}/${PN}/
	bbwarn "path: ${DEPLOYDIR}/${PN}"
}
addtask deploy after do_compile
