FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append += "file://updatenetworks"

do_install_append () {
  install -d ${D}${sysconfdir}/update-hooks.d
  install -m 500 ${S}/updatenetworks ${D}${sysconfdir}/update-hooks.d/90-updatenetworks
}

PACKAGES_append += " \
	${PN}-networks \
"

SUMMARY_${PN}-networks = "Initrd update hook for updating Network Manager connections"
RDEPENDS_${PN}-networks += "gawk"
FILES_${PN}-networks += "${sysconfdir}/update-hooks.d/*-updatenetworks"
