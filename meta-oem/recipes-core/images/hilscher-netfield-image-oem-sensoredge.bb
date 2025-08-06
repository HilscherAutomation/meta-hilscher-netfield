SUMMARY = "Hilscher: netfield OEM overlay image."

require netfield-image-oem-default-ovl.bb

# ------------------------------------------------------------------------------
# NOTE: Preconfigured in oem-base.inc
VENDOR_NAME = "Hilscher Gesellschaft fuer Systemautomation mbH"
VENDOR_URL = "http://www.hilscher.com"

VENDOR_DEVICE_NAME = "netIOT Edge Gateway"
VENDOR_DEVICE_DESC = "netIOT Edge Gateway"
VENDOR_DEVICE_REV = "1.0"
VENDOR_DEVICE_URL = "TBD"

VENDOR_UPNP_DEVICE_TYPE = "TBD"

VENDOR_OS_ID = "netfield"
VENDOR_OS_NAME = "netFIELD OS"

# NOTE: Currently unused
VENDOR_OUI = "TBD"
VENDOR_DEVICE_PN = "TBD"
# ------------------------------------------------------------------------------

# NOTE: VENDOR_ID is still required by netfield-image-oem-default-ovl.bb
VENDOR_ID = "hilscher"

# NOTE: Used by cockpit for cloud connecting.
VENDOR_VARIANT_ID="sensoredge"

# Additional packages
OEM_IMAGE_INSTALL += " \
	cockpit-oem-ovl-remove-docker \
	cockpit-oem-ovl-remove-general-settings \
	cockpit-oem-ovl-remove-iotedge-docker \
	cockpit-oem-ovl-remove-networkservices \
	cockpit-oem-ovl-remove-onboarding \
	cockpit-oem-ovl-remove-terminal \
"

require recipes-core/images/hdeploy_image.inc
