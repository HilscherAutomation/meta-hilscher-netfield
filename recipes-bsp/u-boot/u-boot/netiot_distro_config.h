/*********************************************************************************************/
/*** NOTE: This file contains all generic definitions required for netFIELD OS bootloader. ***/
/***       To overwrite settings see inlcuded file machine_config.h.                       ***/
/*********************************************************************************************/
#include <linux/sizes.h>

#define xstr(a) str(a)
#define str(a) #a

/* max size of image for boot command */
#ifdef CONFIG_SYS_BOOTM_LEN
	#undef CONFIG_SYS_BOOTM_LEN
#endif
#define CONFIG_SYS_BOOTM_LEN SZ_32M

/* max number of arguments */
#define CONFIG_SYS_MAXARGS 64

/* environment variables, variables may be overwritten via machine_config.h */
#define NETIOT_CONFIG_EXTRA_ENV_SETTINGS \
	"autoload="AUTOLOAD"\0" \
	"initrd_high="INITRD_HIGH"\0" \
	"fdt_high="FDT_HIGH"\0" \
	"loadaddr=" xstr(CONFIG_LOADADDR) "\0" \
	"script=boot.scr\0" \
	"scriptaddr=" xstr(CONFIG_LOADADDR) "\0" \
	"fitscript=script@1\0" \
	"mmcdev=0\0" \
	"mmc_parts=0 1\0" \
	"usb_parts=1\0" \
	"bootcmd_mmc="MMCBOOT_COMMAND"\0" \
	"bootcmd_usb0="USBBOOT_COMMAND"\0" \
	"pxe_setup="PXEBOOT_SETUP"\0" \
	"bootcmd_pxe="PXEBOOT_COMMAND"\0" \
	"fastboot="FASTBOOT_SETUP"\0" \
	"setup_console="SETUP_CONSOLE"\0" \
	"platform_init="PLATFORM_INIT"\0" \
	"netcon_ip="NETCON_IP"\0" \
	"netcon_cl="NETCON_CL"\0" \
	"netcon_up="NETCON_ENABLE"\0" \
	"netcon_down="SERIALCON_ENABLE"\0" \
	"bootmenu_default="BOOT_MENU_DEFAULT"\0" \
	"boot_menu="BOOT_MENU_DEFAULT"\0" \
	"start_pxe=1\0" \
	BOARD_CONFIG_EXTRA_ENV_SETTINGS

#ifdef CONFIG_BOOTCOMMAND
	#undef CONFIG_BOOTCOMMAND
#endif
/* boot procedure */
#define CONFIG_BOOTCOMMAND \
	"run platform_init; " \
	"run bootcmd_usb0; " \
	"run bootcmd_mmc; " \
	"if test $start_pxe != 0; then " \
		"while true; do " \
			"run pxe_setup; " \
			"run bootcmd_pxe; " \
		"done; " \
	"fi; "

/* include device specific setup; if necessary the following parameter may be defined here */
#include "machine_config.h"

#ifndef AUTOLOAD
	#define AUTOLOAD "yes"
#endif

#ifndef INITRD_HIGH
	#error Error INITRD_HIGH not defined!
#endif

#ifndef FDT_HIGH
	#error Error FDT_HIGH not defined!
#endif

#ifndef NETCON_IP
	#define NETCON_IP "192.168.253.1"
#endif

#ifndef NETCON_CL
	#define NETCON_CL "192.168.253.2"
#endif

#ifndef BOOT_MENU_DEFAULT
	#define BOOT_MENU_DEFAULT "0"
#endif

#ifndef START_SCRIPT
	/* verify script before starting it */
	#define START_SCRIPT \
		"fdt addr ${scriptaddr} && fdt check && source ${scriptaddr}:${fitscript}; "
#endif

#ifndef USB_LOAD_BOOT_SCRIPT
	#define USB_LOAD_BOOT_SCRIPT \
		"load usb ${0}:${part} ${scriptaddr} ${script} && "START_SCRIPT"; "
#endif

#ifndef USBBOOT_COMMAND
	#define USBBOOT_COMMAND  \
		"if usb reset && usb dev; then " \
			"for part in ${usb_parts}; do " \
				"if test -e usb 0:${part} ${script}; then " \
					"echo Found U-Boot script ${script}; " \
					USB_LOAD_BOOT_SCRIPT \
					"if test $? != 0; then " \
						"echo SCRIPT FAILED: continuing...; " \
					"fi; " \
				"fi; " \
			"done; " \
		"fi;"
#endif

#ifndef MMC_LOAD_BOOT_SCRIPT
	#define MMC_LOAD_BOOT_SCRIPT \
		"fatload mmc ${mmcdev}:${mmcpart} ${scriptaddr} ${script} && "START_SCRIPT"; "
#endif

#ifndef MMCBOOT_COMMAND
	#define MMCBOOT_COMMAND  \
		"for part in ${mmc_parts}; do " \
			"if test -e mmc ${mmcdev}:${part} ${script}; then " \
				"echo Found U-Boot script ${script}; " \
				MMC_LOAD_BOOT_SCRIPT \
				"if test $? != 0; then " \
					"echo SCRIPT FAILED: continuing...; " \
				"fi; " \
			"fi; " \
		"done;"
#endif

#ifndef PXEBOOT_SETUP
	#define PXEBOOT_SETUP \
		"setenv kernel_addr_r ${loadaddr};setenv ramdisk_addr_r ${loadaddr};setenv fdt_addr ${loadaddr};setenv pxefile_addr_r ${loadaddr};setenv bootargs console=$console"
#endif

#ifndef PXEBOOT_COMMAND
	#define PXEBOOT_COMMAND \
		"dhcp && pxe boot; "
#endif

#ifndef NETCON_ENABLE
	#define NETCON_ENABLE \
		"echo switching to netconsole...;" \
		"echo IP: $netcon_ip;" \
		"setenv ipaddr $netcon_ip;setenv ncip $netcon_cl;setenv stdout nc; setenv stdin nc;"
#endif

/* set SETUP_CONSOLE to NETCON_ENABLE for devices without serial interface */
#ifndef SERIALCON_ENABLE
	#define SERIALCON_ENABLE \
		"setenv stdout serial; setenv stdin serial;"
#endif

/* #################################################################### */
/* NOTE: console setup will be only available in case of a debug image  */
/* #################################################################### */
#if defined(CONFIG_NETCONSOLE)
	#ifndef SETUP_CONSOLE
		#define SETUP_CONSOLE \
			NETCON_ENABLE \
			"setenv start_pxe 0\0" \
			"exit; "
	#endif

	#ifndef FASTBOOT_SETUP
		#define FASTBOOT_SETUP \
			"echo IP: 192.168.253.1;" \
			"echo Disabling netconsole...;" \
			"run netcon_down;" \
			"sleep 2;" \
			"while true; do setenv ipaddr 192.168.253.1; fastboot udp; done;"
	#endif
#else
	#ifndef SETUP_CONSOLE
		#define SETUP_CONSOLE \
			"setenv start_pxe 0\0" \
			"exit; "
	#endif

	#ifndef FASTBOOT_SETUP
		#define FASTBOOT_SETUP \
			"echo IP: 192.168.253.1;" \
			"while true; do setenv ipaddr 192.168.253.1; fastboot udp; done;"
	#endif
#endif
