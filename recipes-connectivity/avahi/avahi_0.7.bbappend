FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append += "file://start_after_network_online.patch"
