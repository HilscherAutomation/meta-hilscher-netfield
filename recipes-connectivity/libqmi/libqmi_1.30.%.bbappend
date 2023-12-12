FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://fix-path-for-old-bash-complete.patch"
