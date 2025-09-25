FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://use_iotedge_docker.patch;patchdir=src/${GO_IMPORT}"

SYSTEMD_AUTO_ENABLE:${PN} = "disable"
