SUMMARY = "Default netfield OEM overlay image."

inherit hilscher-oem-image

# Disable CVE check which does not work reliably for branding images
CVE_CHECK_COPY_FILES="0"
CVE_CHECK_CREATE_MANIFEST="0"

BASE_IMAGE="netfield-image-oem"

OEM_IMAGE_INSTALL = " \
	login-welcome-oem-ovl \
	os-release-oem-ovl \
	upnpd-oem-ovl \
	nginx-oem-ovl \
"

do_image[mcdepends] += "mc:${VENDOR_ID}-${MACHINE}:${MACHINE}:netfield-image-oem:do_image_complete"
