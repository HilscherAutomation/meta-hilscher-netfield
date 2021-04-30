SUMMARY = "Create a initrd.api file for system repartitioning."
HOMEPAGE = "www.hilscher.com"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

PACKAGE_ARCH="${MACHINE_ARCH}"

SRC_URI = " \
	file://runscript.sh \
"

# Fetch supported WKS_FILE dependent part.cfg files.
PART_SCHEMES  = "boot-rescue-system-lvm"
PART_SCHEMES += " boot-system-system-lvm"    
do_fetch[vardeps] += "WKS_FILE PHYSICAL_SYSTEM_DEVICE IMAGE_PART_BOOT_SIZE IMAGE_PART_RESCUE_SIZE IMAGE_PART_SYSTEM_SIZE IMAGE_PART_DATA_SIZE PART_DATA_LV_DATA_SIZE PART_DATA_LV_BACKUP_SIZE"
do_fetch_append() {
    from shutil import copyfile

    part_schemes = d.getVar('PART_SCHEMES')
    wks_file = d.getVar('WKS_FILE')
    for ps in part_schemes.split():
        if wks_file.endswith(ps+'.wks.in'):
            src = os.path.join(d.getVar('THISDIR')+"/part-schemes", ps+".cfg")
            dst = os.path.join(d.getVar('WORKDIR'), "part.cfg")
            copyfile(src, dst)
}

do_configure() {
	sed -i 's|#PHYSICAL_SYSTEM_DEVICE#|${PHYSICAL_SYSTEM_DEVICE}|g' ${WORKDIR}/part.cfg

	sed -i 's|#IMAGE_PART_BOOT_SIZE#|${IMAGE_PART_BOOT_SIZE}|g' ${WORKDIR}/part.cfg
	sed -i 's|#IMAGE_PART_RESCUE_SIZE#|${IMAGE_PART_RESCUE_SIZE}|g' ${WORKDIR}/part.cfg
	sed -i 's|#IMAGE_PART_SYSTEM_SIZE#|${IMAGE_PART_SYSTEM_SIZE}|g' ${WORKDIR}/part.cfg
	sed -i 's|#IMAGE_PART_DATA_SIZE#|${IMAGE_PART_DATA_SIZE}|g' ${WORKDIR}/part.cfg

	sed -i 's|#PART_DATA_LV_DATA_SIZE#|${PART_DATA_LV_DATA_SIZE}|g' ${WORKDIR}/part.cfg
	sed -i 's|#PART_DATA_LV_BACKUP_SIZE#|${PART_DATA_LV_BACKUP_SIZE}|g' ${WORKDIR}/part.cfg
}

do_compile() {
	chmod 744 ${WORKDIR}/runscript.sh
	tar czf ${WORKDIR}/${PN} -C ${WORKDIR} part.cfg runscript.sh
}

do_install() {
	install -d ${D}${datadir}/${PN}
	install ${WORKDIR}/${PN} ${D}${datadir}/${PN}
}

do_sign[depends] += "file-signature-native:do_populate_sysroot"
do_sign[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"
do_sign() {
	priv_key=""
	if [ "${@bb.utils.contains('PLATFORM_SIGN', '1', 'true', 'false', d)}" = "true" ]; then
		priv_key="${PLATFORM_KEYDIR}/${PLATFORM_KEYNAME}.key"
		[ ! -e "$priv_key" ] && bbfatal "Signing key $priv_key not found"
	fi

	for file in ${PN}; do
		sign_file ${WORKDIR}/$file $priv_key
	done
}
addtask sign after do_compile

inherit deploy
do_deploy() {
	for file in ${PN}; do
		install -m 644 ${WORKDIR}/${file}.signed ${DEPLOYDIR}/${file}
	done
}
addtask deploy after do_sign

FILES_${PN} = "${datadir}"
