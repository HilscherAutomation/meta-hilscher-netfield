FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://updatenetworks"

do_install:append () {
  install -d ${D}${sysconfdir}/update-hooks.d
  install -m 500 ${S}/updatenetworks ${D}${sysconfdir}/update-hooks.d/90-updatenetworks
}

PACKAGES:append = " \
	${PN}-networks \
"

SUMMARY:${PN}-networks = "Initrd update hook for updating Network Manager connections"
RDEPENDS:${PN}-networks += "gawk"
FILES:${PN}-networks += "${sysconfdir}/update-hooks.d/*-updatenetworks"
