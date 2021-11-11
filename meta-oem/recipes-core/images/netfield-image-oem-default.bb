SUMMARY = "Default netfield OEM overlay image."

inherit hilscher-oem-image hilscher-images
NETFIELD_IMAGES ?= ""

# Disable CVE check which does not work reliably for branding images
CVE_CHECK_COPY_FILES="0"
CVE_CHECK_CREATE_MANIFEST="0"

BASE_IMAGE="netfield-image-oem"

OEM_IMAGE_INSTALL = " \
	login-welcome \
	os-release \
	nginx-conf \
	upnpd-conf \
	upnpd-oem-${VENDOR_ID} \
"

do_image[depends] += "${BASE_IMAGE}:do_image_complete"

require oem-hilscher.inc
require oem.inc

WIC_SYSTEM_PART_CONTENT ?= "${BASE_IMAGE}-${MACHINE}.squashfs ${IMAGE_LINK_NAME}.squashfs;oem/${IMAGE_LINK_NAME}.data-oem.squashfs boot.cfg fitImage"
