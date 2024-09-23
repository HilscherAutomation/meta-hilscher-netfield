DESCRIPTION = "Hilscher Package Groups"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit packagegroup

PROVIDES = "${PACKAGES}"

PACKAGE_ARCH = "${MACHINE_ARCH}"
PACKAGES = " \
	packagegroup-hilscher-base \
	packagegroup-hilscher-debug \
"

RDEPENDS:packagegroup-hilscher-base = " \
	tzdata tzdata-europe \
	lvm2 \
	swupdate swupdate-www swupdate-tools \
"

RDEPENDS:packagegroup-hilscher-debug = " \
	canutils \
"
