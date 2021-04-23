DESCRIPTION = "Hilscher rescue image."

require recipes-core/images/core-image-minimal.bb

IMAGE_INSTALL_append += "\
	packagegroup-hilscher-base \
"
