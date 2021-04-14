# Make sure swupdate-usb is not pulled in (it's requested by swupdate-tools meta package)
RDEPENDS_packagegroup-hilscher-base_remove += "swupdate-tools"
# Include client and progress tool, which is now dropped as swupdate-tools is removed)
RDEPENDS_packagegroup-hilscher-base_append += "swupdate-client swupdate-progress"
