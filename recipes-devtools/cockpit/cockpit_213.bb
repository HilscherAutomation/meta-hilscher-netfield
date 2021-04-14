SRC_URI="https://github.com/cockpit-project/cockpit/releases/download/${PV}/${PN}-${PV}.tar.xz;name=main \
         https://github.com/cockpit-project/cockpit/releases/download/${PV}/${PN}-cache-${PV}.tar.xz;name=cache"

SRC_URI[main.md5sum] = "37a5419f70300b9dd7811455bb5f80cb"
SRC_URI[main.sha256sum] = "f3a5465f767a90790b78ce8ccc285c5bf162e9d20c283f49d06d4cb89a9196f0"
SRC_URI[cache.md5sum] = "fd026da621b62471e0d27c48d7548d38"
SRC_URI[cache.sha256sum] = "73b902f5d47ade420c56113c8f8922e7ecbb24f2113dab293f83dd39070be3b3"

LIC_FILES_CHKSUM="file://COPYING;md5=4fbd65380cdd255951079008b364516c"

EXTRA_OECONF_append += "${@bb.utils.contains("IMAGE_FEATURES", "debug-tweaks", "--enable-debug", "" ,d)}"

require cockpit.inc

ALLOW_EMPTY_${PN}-iotedge-docker="1"
ALLOW_EMPTY_${PN}-general-settings="1"

# Don't select this per default
DEFAULT_PREFERENCE = "-1"
