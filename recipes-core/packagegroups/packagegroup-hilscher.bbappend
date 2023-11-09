# Make sure swupdate-usb is not pulled in (it's requested by swupdate-tools meta package)
RDEPENDS:packagegroup-hilscher-base:remove = "swupdate-tools"
# Include client and progress tool, which is now dropped as swupdate-tools is removed)
RDEPENDS:packagegroup-hilscher-base:append = " swupdate-client swupdate-progress"
