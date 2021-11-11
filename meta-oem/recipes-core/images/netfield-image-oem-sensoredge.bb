SUMMARY = "Hilscher: netfield OEM overlay image."

require recipes-core/images/netfield-image-oem-default.bb

# Additional packages
OEM_IMAGE_INSTALL += " \
    cockpit-branding-netfield-sensoredge \
    cockpit-oem-ovl-remove-docker \
    cockpit-oem-ovl-remove-general-settings \
    cockpit-oem-ovl-remove-iotedge-docker \
    cockpit-oem-ovl-remove-networkservices \
    cockpit-oem-ovl-remove-onboarding \
    cockpit-oem-ovl-remove-terminal \
"

VENDOR_VARIANT_ID="sensoredge"
