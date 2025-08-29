########################################################################################
### The class deploys all files within $HDEPLOYDIR into $HILSCHER_DEPLOY_ROOT_DIR.   ###
########################################################################################

# to be able to access $FULL_FW_VERSION
inherit hilscher-firmware-version

# source directory
HDEPLOYDIR ?= "${WORKDIR}/hilscher-deploy-${PN}"

DISTRO_NAME_SLUG = "${@d.getVar('DISTRO_NAME').replace(' ','-')}"

# helper variables
HDEPLOY_PATH_MACHINE = "${HDEPLOYDIR}/${ORGANIZATION}/${DISTRO_NAME_SLUG}/${FULL_FW_VERSION}/${MACHINE}"
HDEPLOY_PATH_EXTRAS  = "${HDEPLOY_PATH_MACHINE}/extras"
HDEPLOY_PATH_IMAGE   = "${HDEPLOYDIR}/${ORGANIZATION}/${DISTRO_NAME_SLUG}/${FULL_FW_VERSION}/${MACHINE}-${IMAGE_BASENAME}"

SSTATETASKS += "do_hilscher_deploy"

do_hilscher_deploy[sstate-inputdirs] = "${HDEPLOYDIR}"
do_hilscher_deploy[sstate-outputdirs] = "${HILSCHER_DEPLOY_ROOT_DIR}"
python do_hilscher_deploy_setscene () {
    sstate_setscene(d)
}
addtask do_hilscher_deploy_setscene

do_hilscher_deploy[cleandirs] = "${HDEPLOY_PATH_MACHINE}"
do_hilscher_deploy[stamp-extra-info] = "${MACHINE_ARCH}"

do_build[recrdeptask] += "do_hilscher_deploy"
