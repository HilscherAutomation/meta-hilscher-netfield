
inherit hilscher-deploy

DEPLOY_EXT_LIST ??= "${IMAGE_FSTYPES}"

# skip sstate creation since image size will blow up sstate very fast
SSTATE_SKIP_CREATION = "1"

do_hilscher_deploy() {
	for ext in ${DEPLOY_EXT_LIST}; do
		# Deploy images
		for file in $(find ${IMGDEPLOYDIR} -type l -name "*.$ext"); do
			cp -a $(readlink -f $file) ${HDEPLOY_PATH_IMAGE}/
		done
		if [ ! -h "${HDEPLOY_PATH_IMAGE}/deploy-wic-bz2" ] && [ "${ext}" = "wic.bz2" ]; then
			ln -s ../extras/deploy-wic-bz2 ${HDEPLOY_PATH_IMAGE}/deploy-wic-bz2
		fi
		if [ ! -h "${HDEPLOY_PATH_IMAGE}/deploy-fastboot" ] && [ "${ext}" = "fastboot" ]; then
			ln -s ../extras/deploy-fastboot ${HDEPLOY_PATH_IMAGE}/deploy-fastboot
		fi
	done
}
do_hilscher_deploy[cleandirs] = "${HDEPLOY_PATH_IMAGE}/"
addtask hilscher_deploy before do_build after do_image_complete

