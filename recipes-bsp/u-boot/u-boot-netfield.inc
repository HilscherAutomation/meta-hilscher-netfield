FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot:"

DEPENDS:append = " boot-script-fit"

# generic platform specific setup
SRC_URI:append = " file://netiot_distro_config.h \
                   ${@bb.utils.contains('IMAGE_FEATURES', 'debug-tweaks', 'file://boot_interrupt.cfg', 'file://force_autoboot.cfg' ,d)} \
                   ${@bb.utils.contains('MACHINE_FEATURES', 'u-boot-netconsole', 'file://netconsole.cfg', '' ,d)} \
                  "

SRC_URI:append = " \
	file://Change-the-output-of-shell-command-part-number-from-.patch \
"

do_configure:prepend() {
	cp ${WORKDIR}/netiot_distro_config.h ${S}/include/configs/
}
