DESCRIPTION = "Deploy source required for initrd-api file. Will be referenced at 'recovery.zip/swu' creation."
HOMEPAGE = "http://www.hilscher.com"
LICENSE = "CLOSED"

inherit native

BBCLASSEXTEND = "native"

# generic platform specific setup
SRC_URI = "file://common \
           file://recovery.sh \
           file://runscript.sh \
          "

do_configure() {
	[ -z "${PHYSICAL_SYSTEM_DEVICE}" ] && bbfatal "Error PHYSICAL_SYSTEM_DEVICE not defined!"

	sed -i -e "s;@PHYSICAL_SYSTEM_DEVICE@;${PHYSICAL_SYSTEM_DEVICE};g" ${WORKDIR}/runscript.sh
}

do_install() {
	mkdir -p "${D}/${datadir}/initrd-api/recovery/"
	cp ${WORKDIR}/common       "${D}/${datadir}/initrd-api/recovery/"
	cp ${WORKDIR}/recovery.sh  "${D}/${datadir}/initrd-api/recovery/"
	cp ${WORKDIR}/runscript.sh "${D}/${datadir}/initrd-api/recovery/"
}

FILES_${PN} = "${datadir}/initrd-api/recovery/*"
