FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://0001-Revert-windows-fix-as-upstream-on-crazy-max-is-gone.patch;patchdir=src/${GO_IMPORT}"
