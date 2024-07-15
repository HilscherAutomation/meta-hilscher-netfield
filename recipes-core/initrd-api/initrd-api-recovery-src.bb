DESCRIPTION = "Deploy source required for initrd-api file. Will be referenced at 'recovery.zip/swu' creation."
HOMEPAGE = "http://www.hilscher.com"
LICENSE = "CLOSED"

PACKAGE_ARCH = "${MACHINE_ARCH}"

# generic platform specific setup
SRC_URI = "file://common \
           file://recovery.sh \
           file://runscript.sh \
          "

do_install() {
	[ -z "${PHYSICAL_SYSTEM_DEVICE}" ] && bbfatal "Error PHYSICAL_SYSTEM_DEVICE not defined!"

	mkdir -p "${D}/${datadir}/initrd-api/recovery/"
	cp ${WORKDIR}/common       "${D}/${datadir}/initrd-api/recovery/"
	cp ${WORKDIR}/recovery.sh  "${D}/${datadir}/initrd-api/recovery/"
	sed -e "s;@PHYSICAL_SYSTEM_DEVICE@;${PHYSICAL_SYSTEM_DEVICE};g" ${WORKDIR}/runscript.sh > "${D}/${datadir}/initrd-api/recovery/runscript.sh"
	chmod +x "${D}/${datadir}/initrd-api/recovery/runscript.sh"
}

FILES:${PN} = "${datadir}/initrd-api/recovery/*"
