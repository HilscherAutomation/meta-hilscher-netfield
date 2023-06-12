SUMMARY = "FIT formatted shell files for u-boot verified boot"
DESCRIPTION = "FIT formatted shell files for u-boot verified boot"
LICENSE = "CLOSED"

inherit sign-wrapper boot-script-fitimage deploy

DEPENDS = "u-boot-mkimage-native dtc-native"

PACKAGE_ARCH = "${MACHINE_ARCH}"

# Note: The boot-menu* files need to be provided via the platform specific layer
SRC_URI_append += "file://boot-menu-fastboot.cmd \
                   file://boot-menu-debug.cmd \
                   file://boot-recovery.cmd \
                  "

BOOT_SCRIPTS = "boot-menu-fastboot.cmd boot-menu-debug.cmd boot-recovery.cmd"

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
		file)   export UBOOT_MKIMAGE_PARAMS="-k ${UBOOT_SIGN_KEYDIR}"
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
