SUMMARY = "Handles signing/verifying files."
HOMEPAGE = "http://www.hilscher.com"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit allarch

SRC_URI = " \
	file://verify_file \
	file://sign_file \
"
PACKAGES = "${PN}"

DEPENDS += "${@bb.utils.contains('PLATFORM_SIGN', '1', 'openssl-native', '', d)}"
do_compile[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"
do_compile() {
	if [ "${@bb.utils.contains('PLATFORM_SIGN', '1', 'true', 'false', d)}" = "true" ]; then
		priv_key="${PLATFORM_KEYDIR}/${PLATFORM_KEYNAME}.key"
		[ ! -e "$priv_key" ] && bbfatal "Signing key $priv_key not found"

		openssl rsa -in $priv_key -pubout > ${WORKDIR}/${PLATFORM_KEYNAME}.pub.key
	fi
}

# real grep is required for splitting in-line signatures in a fast way (required for large files)
RDEPENDS_${PN} = "grep"
RDEPENDS_${PN} += "${@bb.utils.contains('PLATFORM_SIGN', '1', 'openssl-bin', '', d)}"
do_install() {
	install -d ${D}/${sbindir}
	install -m 744 ${WORKDIR}/verify_file ${D}/${sbindir}

	if [ "${@bb.utils.contains('PLATFORM_SIGN', '1', 'true', 'false', d)}" = "true" ]; then
		install -d ${D}${sysconfdir}/ssl
		install -m 0644 ${WORKDIR}/${PLATFORM_KEYNAME}.pub.key ${D}${sysconfdir}/ssl
		ln -s ${PLATFORM_KEYNAME}.pub.key ${D}${sysconfdir}/ssl/platform.pub.key
	fi
}

FILES_${PN} = "${sysconfdir} ${sbindir}"

BBCLASSEXTEND = "native"

RDEPENDS_${PN}_class-native = "${@bb.utils.contains('PLATFORM_SIGN', '1', 'openssl-native', '', d)}"
do_install_class-native () {
	install -d ${D}/${sbindir}
	install -m 744 ${WORKDIR}/sign_file ${D}/${sbindir}
}
