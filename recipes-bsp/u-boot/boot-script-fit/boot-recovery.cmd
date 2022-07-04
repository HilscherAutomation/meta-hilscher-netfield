# Generic boot script used by a USB recovery stick.

if load ${usb_dev_if} ${usb_dev}:${usb_recovery_part} ${loadaddr} Image; then
	echo "booting recovery-image from usb"
	setenv bootargs "$basebootargs root=LABEL=RECOVERY loglevel=7"
	bootm ${loadaddr} ${loadaddr} ${fdt_addr}
fi
