FILESEXTRAPATHS_append := "${THISDIR}/u-boot:"

RDEPENDS_${PN}_append += " boot-script-fit "

# generic platform specific setup
SRC_URI_append += "file://netiot_distro_config.h \
                   ${@bb.utils.contains('IMAGE_FEATURES', 'debug-tweaks', '', 'file://force_autoboot.cfg' ,d)} \
                   ${@bb.utils.contains('MACHINE_FEATURES', 'u-boot-netconsole', 'file://netconsole.cfg', '' ,d)} \
                  "

do_configure_prepend() {
	cp ${WORKDIR}/netiot_distro_config.h ${S}/include/configs/
}
