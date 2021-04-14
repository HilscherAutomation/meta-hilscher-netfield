# Make sure to seperate python bindings, otherwise python core is installed into initramfs
PACKAGES =+ "${PN}-python"
FILES_${PN}-python = "${PYTHON_SITEPACKAGES_DIR}"
RDEPENDS_${PN}-python = "python3-core"
RDEPENDS_${PN}_remove += "python3-core"
