DESCRIPTION = "SPI Loopback Tool for Testing"
SECTION = "testing"
# Taken from the Linux kernel 4.9.86 tools/spi/
LICENSE = "GPL-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

SRC_URI = "\
	file://Makefile\
	file://spidev_fdx.c \
	file://spidev_test.c \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 spidev_fdx ${D}${bindir}
    install -m 0755 spidev_test ${D}${bindir}
}