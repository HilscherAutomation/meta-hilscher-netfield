SUMMARY = "Initrd update hooks for synchronizing system configurations."
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

S = "${WORKDIR}"

SRC_URI = " \
	file://updateuser \
	file://updateca \
"

do_install () {
	install -d ${D}${sysconfdir}/update-hooks.d
	install -m 500 ${S}/updateuser ${D}${sysconfdir}/update-hooks.d/1-updateuser
	install -m 500 ${S}/updateca ${D}${sysconfdir}/update-hooks.d/10-updateca
}

PACKAGES = " \
	${PN} \
	\
	${PN}-user \
	${PN}-ca \
"

SUMMARY_${PN}-user = "Initrd update hook for synchronizing users from update to live system."
RDEPENDS_${PN}-user += ""
FILES_${PN}-user += "${sysconfdir}/update-hooks.d/*-updateuser"

SUMMARY_${PN}-ca = "Initrd update hook for synchronizing ca certificate updates."
RDEPENDS_${PN}-ca += ""
FILES_${PN}-ca += "${sysconfdir}/update-hooks.d/*-updateca"

# This package references all other packages so that it can be used as a wrapper.
ALLOW_EMPTY_${PN} = "1"
RRECOMMENDS_${PN} += "${PACKAGES}"
FILES_${PN} = ""
