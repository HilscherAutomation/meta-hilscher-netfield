SUMMARY = "Default netfield OEM overlay image."

inherit hilscher-oem-image

# Inherits hilscher-images to create recovery.zip and/or recovery.swu.
inherit hilscher-images

# The OEM_BASE_IMAGE defines the base image for which the OEM overlay is intended.
OEM_BASE_IMAGE="netfield-image-oem"
OEM_IMAGE_INSTALL = " \
	login-welcome \
	os-release \
	nginx-conf \
	upnpd-conf \
	upnpd-oem-${VENDOR_ID} \
"
require oem-base.inc

do_image[depends] += "${OEM_BASE_IMAGE}:do_image_complete"

# Add OEM_BASE_IMAGE to wic image
WIC_SYSTEM_PART_CONTENT_append += "${OEM_BASE_IMAGE}-${MACHINE}.squashfs"

# Move vendor specific OEM overlay image to /oem directory
WIC_SYSTEM_PART_CONTENT_remove += "${IMAGE_LINK_NAME}.squashfs"
WIC_SYSTEM_PART_CONTENT_append += "${IMAGE_LINK_NAME}.squashfs;oem/${IMAGE_LINK_NAME}.squashfs"

# Disable CVE check which does not work reliably for branding images
CVE_CHECK_COPY_FILES = "0"
CVE_CHECK_CREATE_MANIFEST = "0"
