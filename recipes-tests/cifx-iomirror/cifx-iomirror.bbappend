FILESEXTRAPATHS:prepend := "${THISDIR}/config:"

SRC_URI:append = " \
    file://C010D000.nxf \
    file://config.nxd   \
    file://nwid.nxd \
"

do_install:append() {
    install -d ${D}/opt/cifx/deviceconfig/FW/channel0
    install ${WORKDIR}/C010D000.nxf ${D}/opt/cifx/deviceconfig/FW/channel0
    install ${WORKDIR}/nwid.nxd ${D}/opt/cifx/deviceconfig/FW/channel0
    install ${WORKDIR}/config.nxd ${D}/opt/cifx/deviceconfig/FW/channel0
}
