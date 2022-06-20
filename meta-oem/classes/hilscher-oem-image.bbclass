# This class can be used to create vendor specific rootfs overlays for OEM base images.

IMAGE_FSTYPES = "squashfs_signed swu wic.bz2 ${@'fastboot' if d.getVar('FASTBOOT_SUPPORT')=='1' else ''}"
DEPLOY_EXT_LIST = "squashfs squashfs.sig swu wic.bz2 ${@'fastboot' if d.getVar('FASTBOOT_SUPPORT')=='1' else ''} ${@bb.utils.contains('NETFIELD_IMAGES', 'recovery.zip', 'zip', '', d)}"

IMAGE_LINGUAS = ""
PACKAGE_INSTALL = "${OEM_IMAGE_INSTALL}"

inherit image hilscher_image_types sign-wrapper

# Creates an image without the rootfs stuff.
do_cleanup[depends] += "empty-image:do_rootfs"
fakeroot do_cleanup () {
	cd ${WORKDIR}

	for f in $(find ../../empty-image/*/rootfs -type f | cut -d'/' -f6-); do
		rm -f rootfs/$f
	done

	for d in $(find ../../empty-image/*/rootfs -type d | cut -d'/' -f6- | sort -r); do 
		[ -d rootfs/$d ] && rmdir --ignore-fail-on-non-empty rootfs/$d
	done
}
addtask do_cleanup after do_rootfs before do_image_qa

# Install vendor_specific files
do_install_vendor_specific_files() {
	echo "${IMAGE_BASENAME}" > ${IMAGE_ROOTFS}/firmware.vendor_id
	echo "${IMAGE_NAME}" > ${IMAGE_ROOTFS}/firmware.vendor_image_name
	chmod 0444 ${IMAGE_ROOTFS}/firmware.vendor_id ${IMAGE_ROOTFS}/firmware.vendor_image_name
}
ROOTFS_POSTUNINSTALL_COMMAND_append += "do_install_vendor_specific_files;"

########################################
# SWU Image
########################################

# Create a SWU image based on OEM base images.
IMAGE_TYPEDEP_swu = "squashfs_signed"
do_image_swu[nostamp] = "1"
do_image_swu[depends] = ""
do_image_swu[vardeps] = "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"
DEPENDS += "libconfig-native"

TMPDIR_SWU = "${WORKDIR}/tmpdir_swu"
TMPDIR_DATA_OEM = "${WORKDIR}/tmpdir_data_oem"

IMAGE_CMD_swu() {
	# Create a squashfs file which contains the data-oem partition contents.
	# ======================================================================

	if [ ! -e "${IMGDEPLOYDIR}/${IMAGE_NAME}.data-oem.squashfs" ]; then
		tmpdir=${TMPDIR_DATA_OEM}
		[ -e "$tmpdir" ] && {
			bbwarn "Removing leftover temporary directory $tmpdir from old build!"
			rm -rf $tmpdir
		}
		mkdir -p $tmpdir
		cp $(readlink -f ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.squashfs) $tmpdir
		cp $(readlink -f ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.squashfs.sig) $tmpdir
		mksquashfs $tmpdir ${IMGDEPLOYDIR}/${IMAGE_NAME}.data-oem.squashfs
		ln -sf ${IMAGE_NAME}.data-oem.squashfs ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.data-oem.squashfs
		rm -rf $tmpdir
	fi

	# Use base image as reference
	swu_src_link="${DEPLOY_DIR_IMAGE}/${OEM_BASE_IMAGE}-${MACHINE}.update.swu"

	if [ "${OEM_BRANDING_MERGE}" = "1" ]; then
		# Merged vendor/machine specific swu-images (and set unknown section, if requested)
		# =================================================================================

		create_swu "$swu_src_link" "${OEM_BRANDING_IMAGES}"
	else

	# Vendor/machine/image specific swu-image
	# =======================================

	# Create a new swu-image based on ...
		create_swu "$swu_src_link" "${PN}" "forced-customization"
	fi
}

ls_config_copy() {
	src_file=$(echo $1 | cut -d':' -f1)
	src=$(echo $1 | cut -d':' -f2)
	dst_file=$(echo $2 | cut -d':' -f1)
	dst=$(echo $2 | cut -d':' -f2)

	# Get the highest index number of source section.
	elements_count=$(ls-config -f "$src_file" -g "$src" -q -c)
	idx_max=$(expr $elements_count - 1) || true

	# Add an empty list (for files, scripts ...) to destination section.
	ls-config -f "$dst_file" -g "$dst" ||
		ls-config -f "$dst_file" -s "$dst" -p list -d empty

	for idx in $(seq 0 $idx_max); do
		# Readout a list of elements from source.
		element_list=$(ls-config -f "$src_file" -g "$src.[$idx]" -q -v | tr ';' ' ')

		# Add an empty group (e.g. files, scripts ...) to destination.
		new_idx=$(ls-config -f "$dst_file" -s "$dst" -p group -d empty -q)

		# Copy all elements from source to the recently created group.
		for element in $element_list; do
			element_value=$(ls-config -f "$src_file" -g "$src.[$idx].$element" -q -v)
			ls-config -f "$dst_file" -s "$dst.[$new_idx].$element" -p string -d "$element_value"
		done
	done

}

create_swu() {
	swu_file=$1 # image which should be used as base image
	brandings_to_include=$2 # list of image names which should be included
	default_link=$3 # if configured, the resulting image can be used for (re)branding

	[ -z "$swu_file" -o ! -e $swu_file ] && bberror "Invalid or missing SWU source image ($swu_file)!"

	swu_file="$(readlink -f $swu_file)"
	swu_type="$(echo $swu_file | rev | cut -d. -f-2 | rev)"

	# Extract the board name an hardware revision form machine name.
	# NOTE:
	#   Copied from meta-hilscher-distro/recipes-support/swupdate/swupdate_%.bbappend
	board="$(echo ${MACHINE} | sed 's/-rev[0-9]*//')"
	rev="$(echo ${MACHINE} | grep -oe "-rev[0-9]*" | sed 's/-rev//')"
	rev="${rev:-0}"

	# Create a temporary working directory.
	tmpdir=${TMPDIR_SWU}
	[ -e "$tmpdir" ] && {
		bbwarn "Removing leftover temporary directory $tmpdir from old build!"
		rm -rf $tmpdir
	}
	mkdir -p $tmpdir

	# Extract the swu-base-image.
	cd $tmpdir; cpio -i <$swu_file; cd -

	# Create a list of oem overlay images which should be included.
	oem_ovl_images=""
	for tmp_brand in $brandings_to_include; do
		tmp_file="$(readlink -f ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.data-oem.squashfs)"
		[ "${OEM_BRANDING_MERGE}" = "1" ] &&
			tmp_file=$(find "${HILSCHER_DEPLOY_ROOT_DIR}/${MACHINE}" -name "$tmp_brand-*.data-oem.squashfs")
		if [ ! -r "$tmp_file" ]; then
			bbfatal "Missing branding file $tmp_file for $tmp_brand (using find \"${HILSCHER_DEPLOY_ROOT_DIR}/${MACHINE}\" -name \"$tmp_brand-*.data-oem.squashfs\")"
		fi
		oem_ovl_images="$oem_ovl_images $tmp_file:$tmp_brand"
	done

	# Create a working copy of sw-description file.
	cp "$tmpdir/sw-description" "$tmpdir/sw-description.new"

	# Remove unneeded stuff from board section.
	# NOTE:
	#   This prevents accidental vendor specific oem updates and brandings.
	ls-config -f "$tmpdir/sw-description.new" -s "software.$board.hardware-compatibility" -u
	ls-config -f "$tmpdir/sw-description.new" -s "software.$board.files" -u
	ls-config -f "$tmpdir/sw-description.new" -s "software.$board.scripts" -u

	# If necessary, add a link to enable a forced vendor specific OEM update/branding.
	# NOTE:
	#   This enables a customization of unbranded OEM devices.
	if [ -n "$default_link" ]; then
		ls-config -f "$tmpdir/sw-description.new" -s "software.$board.ref" -p string -d "#./$board/oem/${PN}"
	fi

	# OEM section
	for oem_ovl_image in $oem_ovl_images; do
		vendor_id=$(echo $oem_ovl_image | cut -d':' -f2)
		oem_ovl_image=$(echo $oem_ovl_image | cut -d':' -f1)
		cp -L $oem_ovl_image $tmpdir

		# Add an oem section.
		ls-config -f "$tmpdir/sw-description.new" -g "software.$board.oem" ||
			ls-config -f "$tmpdir/sw-description.new" -s "software.$board.oem" -p group -d empty

		# Add a vendor specific oem section.
		ls-config -f "$tmpdir/sw-description.new" -s "software.$board.oem.$vendor_id" -p group -d empty

		# Copy hardware-compatibility from original board section to vendor specific oem section.
		if ! ls-config -f "$tmpdir/sw-description.new" -g "software.$board.oem.$vendor_id.hardware-compatibility"; then
			ls-config -f "$tmpdir/sw-description.new" -s s"oftware.$board.oem.$vendor_id.hardware-compatibility" -p array -d empty
			array_values=$(ls-config -f "$tmpdir/sw-description" -g "software.$board.hardware-compatibility" -q -v | tr ';' ' ')
			for value in $array_values; do
				ls-config -f "$tmpdir/sw-description.new" -s "software.$board.oem.$vendor_id.hardware-compatibility" -p string -d $value
			done
		fi

		# Copy all files/scripts from original board section to vendor specific oem section.
		ls_config_copy "$tmpdir/sw-description:software.$board.files" "$tmpdir/sw-description.new:software.$board.oem.$vendor_id.files"
		ls_config_copy "$tmpdir/sw-description:software.$board.scripts" "$tmpdir/sw-description.new:software.$board.oem.$vendor_id.scripts"

		# Add a new group member to vendor specific oem section containing the vendor specific oem overlay data.
		new_idx=$(ls-config -f "$tmpdir/sw-description.new" -s "software.$board.oem.$vendor_id.files" -p group -d empty -q)
		ls-config -f "$tmpdir/sw-description.new" -s "software.$board.oem.$vendor_id.files.[$new_idx].filename" -p string -d "$(basename $oem_ovl_image)"
		ls-config -f "$tmpdir/sw-description.new" -s "software.$board.oem.$vendor_id.files.[$new_idx].sha256" -p string -d "$(sha256sum $oem_ovl_image | cut -d' ' -f1)"
		ls-config -f "$tmpdir/sw-description.new" -s "software.$board.oem.$vendor_id.files.[$new_idx].path" -p string -d "/dev/null"
	done

	# Replace origianl sw-description file
	mv $tmpdir/sw-description.new $tmpdir/sw-description

	# Create file list for new SWU image content
	cd $tmpdir
	fileList="sw-description"
	[ "${SWUPDATE_SIGN_ENFORCE}" != "0" ] && {
		# If necessary sign sw-description file
		SIGN_WRAPPER_KEY_SRC="${SWUPDATE_KEYDIR}"
		openssl_sign_wrapper ${SWUPDATE_KEYNAME} "sha256" sw-description
		fileList="$fileList sw-description.sig"
	}
	for file in $(find ./ -type f ! -name 'sw-description*'); do
		fileList="$fileList $file"
	done

	# Create new swu-image file
	for file in $fileList; do
		echo $file
	done | cpio -ov -H crc > ${IMGDEPLOYDIR}/${IMAGE_NAME}.$swu_type
	ln -sf ${IMAGE_NAME}.$swu_type ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.$swu_type

	cd -

	# Cleanup
	rm -rf $tmpdir
}
