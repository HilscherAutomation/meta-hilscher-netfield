# Make sure to seperate python bindings, otherwise python core is installed into initramfs
PACKAGES =+ "${PN}-python"
FILES:${PN}-python = "${PYTHON_SITEPACKAGES_DIR}"
RDEPENDS:${PN}-python = "python3-core"
RDEPENDS:${PN}:remove = "python3-core"
