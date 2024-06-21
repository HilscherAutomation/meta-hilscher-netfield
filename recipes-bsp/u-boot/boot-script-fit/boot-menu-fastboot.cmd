# Generic boot menu script providing boot image selection and fastboot.

# menu index count
setexpr mi 0

# Create a bootmenu based on boot.cfg files
for part in ${plat_system_part}; do
	for conf in boot.cfg aboot.cfg; do
		if load ${plat_dev_if} ${plat_dev}:${part} ${loadaddr} ${conf}; then
			env import ${loadaddr}
			test -z "${description}" && description="unknown"
			test "${conf}" = "boot.cfg" && type=" "
			test "${conf}" = "aboot.cfg" && type="(ALTERNATIVE)"
			setenv bootmenu_${mi} ${plat_dev_if}${plat_dev}: ${description} ${type} = "
				setenv bootargs ${basebootargs} bootCfg=${plat_dev_linux}${part}/${conf} @BOOT_OPTIONS@;
				load ${plat_dev_if} ${plat_dev}:${part} ${loadaddr} ${kernel};
				bootm ${loadaddr} ${loadaddr} ${fdt_addr}
			"
			setexpr mi ${mi} + 1
		fi
	done
done

setenv bootmenu_${mi} FastBoot = "run fastboot"

# Execute gpio-based menu, if available
setenv boot_menu_max ${mi}
run get_menu
setenv bootmenu_default $boot_menu

bootmenu 3

exit $?
