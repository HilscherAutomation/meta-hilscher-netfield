SUMMARY = "Hilscher: netfield OEM base image."

require recipes-core/images/netfield-image.bb

IMAGE_INSTALL_append += "swupdate-oem upnpd-oem"

# oem base defines
VENDOR_NAME ??= "TBD-by-OEM"
VENDOR_OUI ??= "TBD-by-OEM"
VENDOR_URL ??= "TBD-by-OEM"

VENDOR_DEVICE_NAME ??= "TBD-by-OEM"
VENDOR_DEVICE_DESC ??= "TBD-by-OEM"
VENDOR_DEVICE_PN ??= "TBD-by-OEM"
VENDOR_DEVICE_REV ?= "TBD-by-OEM"
VENDOR_DEVICE_URL ??= "TBD-by-OEM"

VENDOR_UPNP_DEVICE_TYPE ??= "TBD-by-OEM"

VENDOR_OS_ID ??= "TBD-by-OEM"
VENDOR_OS_NAME ??= "TBD-by-OEM"

require oem.inc
