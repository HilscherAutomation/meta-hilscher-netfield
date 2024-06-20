SUMMARY = "FIT formatted shell files for u-boot verified boot"
DESCRIPTION = "FIT formatted shell files for u-boot verified boot"
LICENSE = "CLOSED"

inherit sign-wrapper boot-script-fitimage deploy

DEPENDS = "u-boot-mkimage-native dtc-native"

PACKAGE_ARCH = "${MACHINE_ARCH}"

# boot-menu:
#   The 'common' boot menu allows switching between installed images. If debug-tweaks
#   is set, the u-boot autoboot process can be interrupted and the console will be entered.
#   In contrast to that in a release build boot process can not be stopped and the console
#   can not be entered.
# boot-menu-fastboot:
#   Same as 'boot-menu' + fastboot menu option.
# boot-menu-fastboot-console:
#   Same as boot-menu-fastboot + console option. Special use case: Some devices may
#   not have a common user interface (to abort booting to drop to console)
#   but it is possible to control the boot menu (e.g. via gpio). The 'console' menu
#   entry handles the custom console setup (e.g. netconsole) as well.
SRC_URI_append += "file://boot-menu.cmd \
                   file://boot-menu-fastboot.cmd \
                   file://boot-menu-fastboot-console.cmd \
                   file://boot-recovery.cmd \
                  "

BOOT_SCRIPTS = "boot-menu.cmd boot-menu-fastboot.cmd boot-menu-fastboot-console.cmd boot-recovery.cmd"

do_patch[vardeps] += "IMAGE_FEATURES"
do_patch() {
	generic_boot_options=""
	if [ "${@bb.utils.contains('IMAGE_FEATURES', 'debug-tweaks', 'true', 'false',d)}" = "true" ]; then
		generic_boot_options=" loglevel=7"
	fi
	for BOOT_SCRIPT in ${BOOT_SCRIPTS}; do
		sed -i -e 's,@BOOT_OPTIONS@,'"${generic_boot_options}"',g' ${BOOT_SCRIPT}
	done
}

do_deploy[vardepsexclude] += "DATETIME"
do_deploy() {
	# Update deploy directory
	if echo ${KERNEL_IMAGETYPES} | grep -wq "fitImage"; then
		install -d ${DEPLOYDIR}/${PN}
		cd ${B}
		for BOOT_SCRIPT in ${BOOT_SCRIPTS}; do
			echo installing $(basename "${BOOT_SCRIPT%.cmd}.scr") to ${DEPLOYDIR}/${PN}/fitImage-${BOOT_SCRIPT%.cmd}.scr
			install -m 0644 $(basename "${BOOT_SCRIPT%.cmd}.scr") ${DEPLOYDIR}/${PN}/fitImage-${BOOT_SCRIPT%.cmd}.scr
		done
	fi
}
addtask deploy before do_build after do_install
do_deploy[dirs] += "${DEPLOYDIR}/${PN}"

do_assemble_boot_script_fitimage_prepend() {
	# scripts will be signed at assemble_boot_script_fitimage (boot-script-fitimage.bbclass)
	setup_sign_wrapper_env "${PLATFORM_KEYNAME}"
	sign_key=$(setup_sign_wrapper_env "${PLATFORM_KEYNAME}")

	case ${SIGN_WRAPPER_MODE} in
		file)   export UBOOT_MKIMAGE_PARAMS="-k UBOOT_SIGN_KEYDIR}"
			;;
		pkcs11) #u-boot mkimage expects URL without leading pkcs11:
			sign_key=$(echo $sign_key | sed -e 's/^pkcs11://')
			export UBOOT_MKIMAGE_PARAMS="-k ${sign_key} -N pkcs11"
			;;
	esac
}

inherit hilscher-deploy

hd_path = "${HDEPLOY_PATH_EXTRAS}/boot-scripts"

do_hilscher_deploy() {
	cp -r ${DEPLOYDIR}/${PN}/* "${hd_path}/"
}
do_hilscher_deploy[cleandirs] = "${hd_path}/"
addtask hilscher_deploy before do_build after do_deploy
