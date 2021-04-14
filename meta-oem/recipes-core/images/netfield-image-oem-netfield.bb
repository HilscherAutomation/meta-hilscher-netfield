SUMMARY = "Hilscher: netfield OEM overlay image."

require recipes-core/images/netfield-image-oem-default.bb

# Additional packages
# NOTE: cockpit-branding-default is included in base image and can be left out here
OEM_IMAGE_INSTALL += " \
"
