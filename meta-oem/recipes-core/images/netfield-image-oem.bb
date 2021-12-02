SUMMARY = "Hilscher: netfield OEM base image."

require recipes-core/images/netfield-image.bb
require oem-base.inc

IMAGE_INSTALL_append += "swupdate-oem upnpd-oem"
