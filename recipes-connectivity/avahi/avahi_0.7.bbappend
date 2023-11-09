FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://start_after_network_online.patch"
