SUMMARY = "Meta recipe to build all brandings and combine them into a single SWU file"

require netfield-image-oem-netfield.bb

OEM_BRANDING_MERGE="1"

python () {
    branding_images = d.getVar('OEM_BRANDING_IMAGES') or ""
    for branding in branding_images.split():
        d.appendVarFlag('do_image_swu', 'depends', " %s:do_image_complete" % branding)
}

# Don't create recovery zip/swu
NETFIELD_IMAGES=""

# Only deploy update SWU
IMAGE_FSTYPES="swu"
DEPLOY_EXT_LIST="swu"
