SUMMARY = "Meta recipe to build all brandings and combine them into a single SWU file"

# NOTE:
# This recipe only create a merged SWU update image containing the OEM_BASE_IMAGE
# and the OEM_BRANDING_IMAGES. The image itself is useless and should be empty.
inherit hilscher-oem-image
OEM_IMAGE_INSTALL = ""

# The OEM_BASE_IMAGE defines the base image for which the OEM overlays are intended.
OEM_BASE_IMAGE="netfield-image-oem"

OEM_BRANDING_MERGE="1"

require recipes-core/images/hdeploy_image.inc

# Make sure that all OEM_BRANDING_IMAGES are completed before they will be merge togther in a common SWU update image.
python () {
    branding_images = d.getVar('OEM_BRANDING_IMAGES') or ""
    for branding in branding_images.split():
        d.appendVarFlag('do_image_swu', 'depends', " %s:do_hilscher_deploy" % branding)
}

# Only deploy SWU update image
IMAGE_FSTYPES = "swu"
DEPLOY_EXT_LIST = "swu"
