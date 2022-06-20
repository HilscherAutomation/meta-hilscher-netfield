########################################################################################
### The class deploys all files within $HDEPLOYDIR into $HILSCHER_DEPLOY_ROOT_DIR.   ###
########################################################################################

# to be able to access $FULL_FW_VERSION
inherit hilscher-firmware-version

# source directory
HDEPLOYDIR ?= "${WORKDIR}/hilscher-deploy-${PN}"

# helper variables
HDEPLOY_PATH_MACHINE = "${HDEPLOYDIR}/${MACHINE}/${FULL_FW_VERSION}"
HDEPLOY_PATH_EXTRAS  = "${HDEPLOY_PATH_MACHINE}/extras"
HDEPLOY_PATH_IMAGE   = "${HDEPLOY_PATH_MACHINE}/${IMAGE_BASENAME}"

SSTATETASKS += "do_hilscher_deploy"

do_hilscher_deploy[sstate-inputdirs] = "${HDEPLOYDIR}"
do_hilscher_deploy[sstate-outputdirs] = "${HILSCHER_DEPLOY_ROOT_DIR}"
python do_hilscher_deploy_setscene () {
    sstate_setscene(d)
}
addtask do_hilscher_deploy_setscene

do_hilscher_deploy[cleandirs] = "${HDEPLOY_PATH_MACHINE}"
do_hilscher_deploy[stamp-extra-info] = "${MACHINE_ARCH}"
