SUMMARY = "Handle provisioning startup process for production purpose."
HOMEPAGE = "http://www.hilscher.com"

LICENSE = "CLOSED"

inherit allarch

SRC_URI = " \
           file://provisioning \
           file://functions \
"

RDEPENDS_${PN} = "nfs-utils-mount"
PACKAGES = "${PN}"

do_install () {
	install -d ${D}/init.d
	install -m 500 ${WORKDIR}/provisioning ${D}/init.d/11-provisioning
	install -m 500 ${WORKDIR}/functions ${D}/init.d/functions
}

FILES_${PN} = "/init.d/11-provisioning \
               /init.d/functions \
               "
