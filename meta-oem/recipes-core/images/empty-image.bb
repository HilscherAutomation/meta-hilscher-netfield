# Creates an empty image.

SUMMARY = "An empty image."

# Disable CVE check which does not work reliably for branding images
CVE_CHECK_COPY_FILES="0"
CVE_CHECK_CREATE_MANIFEST="0"

IMAGE_FSTYPES = ""
IMAGE_LINGUAS = ""
PACKAGE_INSTALL = ""

inherit image
