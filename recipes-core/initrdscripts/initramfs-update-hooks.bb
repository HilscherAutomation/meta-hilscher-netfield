SUMMARY = "Initrd update hooks for synchronizing system configurations."
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

S = "${WORKDIR}"

SRC_URI = " \
	file://updateuser \
	file://updateca \
	file://updatefstab \
	file://updateapparmor \
"

do_install () {
	install -d ${D}${sysconfdir}/update-hooks.d
	install -m 500 ${S}/updateuser ${D}${sysconfdir}/update-hooks.d/1-updateuser
	install -m 500 ${S}/updateca ${D}${sysconfdir}/update-hooks.d/10-updateca
	install -m 500 ${S}/updatefstab ${D}${sysconfdir}/update-hooks.d/11-updatefstab
	install -m 500 ${S}/updateapparmor ${D}${sysconfdir}/update-hooks.d/12-updateapparmor
}

PACKAGES = " \
	${PN} \
	\
	${PN}-user \
	${PN}-ca \
	${PN}-fstab \
	${PN}-apparmor \
"

SUMMARY:${PN}-user = "Initrd update hook for synchronizing users from update to live system."
RDEPENDS:${PN}-user += ""
FILES:${PN}-user += "${sysconfdir}/update-hooks.d/*-updateuser"

SUMMARY:${PN}-ca = "Initrd update hook for synchronizing ca certificate updates."
RDEPENDS:${PN}-ca += ""
FILES:${PN}-ca += "${sysconfdir}/update-hooks.d/*-updateca"

SUMMARY:${PN}-fstab = "Initrd update hook for synchronizing the /etc/fstab."
RDEPENDS:${PN}-fstab += ""
FILES:${PN}-fstab += "${sysconfdir}/update-hooks.d/*-updatefstab"

SUMMARY:${PN}-apparmor = "Initrd update hook for synchronizing /etc/apparmor.d"
RDEPENDS:${PN}-apparmor += ""
FILES:${PN}-apparmor += "${sysconfdir}/update-hooks.d/*-updateapparmor"

# This package references all other packages so that it can be used as a wrapper.
ALLOW_EMPTY:${PN} = "1"
RRECOMMENDS:${PN} += "${PACKAGES}"
FILES:${PN} = ""
