
inherit hilscher-deploy

DEPLOY_EXT_LIST ??= "${IMAGE_FSTYPES}"

# skip sstate creation since image size will blow up sstate very fast
SSTATE_SKIP_CREATION = "1"

do_hilscher_deploy() {
	for ext in ${DEPLOY_EXT_LIST}; do
		install -d "${HDEPLOY_PATH_IMAGE}"
		# Deploy images
		for file in $(find ${IMGDEPLOYDIR} -type l -name "*.$ext"); do
			# Get the real file path and extract part after FULL_FW_VERSION
			real_file_path=$(readlink -f "$file")
			real_file=$(basename $real_file_path)
			part_after_version="${real_file#*${FULL_FW_VERSION}}"
			# Get everything after the first dot
			extensions="${part_after_version#*.}"
			hd_filename="${DISTRO_NAME_SLUG}_${FULL_FW_VERSION}_${MACHINE}-${IMAGE_BASENAME}.${extensions}"
			cp -a $(readlink -f $file) "${HDEPLOY_PATH_IMAGE}/${hd_filename}"
			if [ ${ext} == "squashfs" ] && [ -e "${file}.sig" ]; then
				cp -a $(readlink -f "${file}.sig") "${HDEPLOY_PATH_IMAGE}/${hd_filename}.sig"
			fi
		done
	done
	# collect sbom if it exists
	sbom=$(find ${IMGDEPLOYDIR} -type l -name "*.sbom.cdx.json")
	if [ -n "${sbom}" ]; then
		hd_sbom_filename="${DISTRO_NAME_SLUG}_${FULL_FW_VERSION}_${MACHINE}-${IMAGE_BASENAME}.sbom.cdx.json"
		cp -a $(readlink -f ${sbom}) "${HDEPLOY_PATH_IMAGE}/${hd_sbom_filename}"
	fi
}
do_hilscher_deploy[cleandirs] = "${HDEPLOY_PATH_IMAGE}/"
addtask hilscher_deploy before do_build after do_image_complete

do_archive_extras() {
	archive_location="${HILSCHER_DEPLOY_ROOT_DIR}/${ORGANIZATION}/${DISTRO_NAME_SLUG}/${FULL_FW_VERSION}/${MACHINE}"

	if [ -d "${archive_location}/extras" ]; then
		tar zcf "${archive_location}/${DISTRO_NAME_SLUG}_${FULL_FW_VERSION}_${MACHINE}_extras.tar.gz" -C "${archive_location}/extras" $(ls "${archive_location}/extras")
		rm -rf "${archive_location}/extras"
	fi
}
addtask archive_extras before do_build after do_hilscher_deploy