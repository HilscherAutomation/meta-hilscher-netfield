SUMMARY = "Hilscher: netfield OEM base image."

require recipes-core/images/netfield-image.bb
require oem-base.inc

# NOTE: Used by cockpit for cloud connecting.
VENDOR_VARIANT_ID=""

IMAGE_INSTALL_append += "swupdate-oem upnpd-oem"
