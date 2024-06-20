DESCRIPTON="cifX / netX Helper tools to read sdpm and cifx PCI cards"
LICENSE="CLOSED"

SRC_URI = "file://netx_sdpm_read.c \
           file://cifx_read_hwinfo.c \
           file://cifx_find_pci.sh"

do_compile() {
    ${CC} ${LDFLAGS} ${WORKDIR}/netx_sdpm_read.c -o ${B}/netx_sdpm_read
    ${CC} ${LDFLAGS} ${WORKDIR}/cifx_read_hwinfo.c -I=/usr/include/cifx -lcifx -lpthread -lnl-cli-3 -o ${B}/cifx_read_hwinfo
}

do_install() {
    install -d ${D}/opt/cifx/examples
    install ${B}/netx_sdpm_read ${D}/opt/cifx/examples/
    install ${B}/cifx_read_hwinfo ${D}/opt/cifx/examples/
    install ${WORKDIR}/cifx_find_pci.sh ${D}/opt/cifx/examples/cifx_find_pci
}

PACKAGES =+ "${PN}-read-hwinfo"
DEPENDS = "libcifx libnl"
RDEPENDS:${PN}-read-hwinfo = "libcifx libnl"
RDEPENDS:${PN} = "kernel-module-spidev"

FILES:${PN} = "/opt/cifx/examples/"
FILES:${PN}-read-hwinfo = "/opt/cifx/examples/cifx_read_hwinfo"
