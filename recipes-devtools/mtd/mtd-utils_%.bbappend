# meta-swupdate changed the SRCREV of mtd-utils from poky: https://github.com/sbabic/meta-swupdate/commit/ece400ed52c36b2712bef98b0360b9136c9b9467
# This makes the patch provided by poky obsolete and fail, so remove it
SRC_URI_remove += "${@ 'file://0001-mtd-utils-Fix-return-value-of-ubiformat.patch' if d.getVar("SRCREV") == "639b871fe3d2cb3e73d21363e8c13ede2bbd9f99" else ''}"
