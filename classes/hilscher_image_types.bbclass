inherit kernel-artifact-names sign-wrapper

DEPENDS:append = " ${@bb.utils.contains_any('IMAGE_FSTYPES', 'wic.bz2 fastboot', 'deploy-scripts-native', '', d)}"

HILSCHER_RESCUE_IMAGE_LINK_NAME ??= "${HILSCHER_RESCUE_IMAGE}-${MACHINE}"
INITRAMFS_IMAGE_NAME ?= "${@['${INITRAMFS_IMAGE}-${MACHINE}', ''][d.getVar('INITRAMFS_IMAGE') == '']}"

########################################
# Anonymous python function for firmware version handling
########################################
inherit hilscher-firmware-version

# Add firmware version to image name
IMAGE_VERSION_SUFFIX =. "-${FULL_FW_VERSION}"

########################################
# Anonymous python function to fix ROOTFS_POSTPROCESS_COMMAND:remove
########################################
python () {
    # Because 'ROOTFS_POSTPROCESS_COMMAND' list is very ugly constructed, it isn't possible
    # to remove some commands in a use of 'ROOTFS_POSTPROCESS_COMMAND:remove'.
    # Therfore we implemented a further way to remove commands from list.
    # Use 'ROOTFS_POSTPROCESS_COMMAND:removeFix' instead of 'ROOTFS_POSTPROCESS_COMMAND:remove'!

    cmdList = d.getVar('ROOTFS_POSTPROCESS_COMMAND') or ""
    cmdRemoveList = d.getVar('ROOTFS_POSTPROCESS_COMMAND:removeFix') or ""

    cmdList = cmdList.replace(' ', '')

    for cmdRemove in cmdRemoveList.split():
        cmdList = cmdList.replace(cmdRemove, '')

    cmdList = cmdList.replace(';', '; ')
    d.setVar('ROOTFS_POSTPROCESS_COMMAND', cmdList)
}
ROOTFS_POSTPROCESS_COMMAND:removeFix += "rootfs_update_timestamp;"

# Mark the following line as comment to support the yocto test framework!
#ROOTFS_POSTPROCESS_COMMAND:removeFix += "write_image_test_data;"

########################################
# Anonymous python function for image handling
########################################

# Additional dependencies for creating a wic image.
# usually this is done inside image recipes, but for convenience do it here in an easy way
WIC_IMAGE_DEPENDENCIES ??= "initrd-api-part-cfg"

python() {
    # To prevent circular dependency, remove all wic types from ${IMAGE_FSTYPES} of ${HILSCHER_RESCUE_IMAGE}
    if d.getVar('IMAGE_BASENAME') in (d.getVar('INITRAMFS_IMAGE'), d.getVar('HILSCHER_RESCUE_IMAGE')):
        image_fstypes = d.getVar('IMAGE_FSTYPES') or ""

        for fstype in (' '.join('wic.%s' % c for c in d.getVar('CONVERSIONTYPES').split()) + ' wic' + ' swu' + ' fastboot').split():
            if fstype in (image_fstypes):
                bb.debug(1, "Remove %s for %s" % (fstype, d.getVar('IMAGE_BASENAME')))
                image_fstypes = image_fstypes.replace(fstype, '')
                if "squashfs_signed" not in (image_fstypes):
                    image_fstypes += " squashfs_signed"
                d.setVar('IMAGE_FSTYPES', image_fstypes)

    for dep in d.getVar('WIC_IMAGE_DEPENDENCIES').split():
        d.appendVarFlag('do_image_wic', 'depends', ' %s:do_deploy' % dep)
}

########################################
# Helpers
########################################

do_install_firmware_manifest() {
   install -m 0444 "${IMAGE_MANIFEST}" ${IMAGE_ROOTFS}/firmware.manifest
}
ROOTFS_POSTUNINSTALL_COMMAND:append = " do_install_firmware_manifest;"

do_install_firmware_version() {
   echo ${FULL_FW_VERSION} > ${IMAGE_ROOTFS}/firmware.version
   echo ${IMAGE_NAME} > ${IMAGE_ROOTFS}/firmware.image_name
   chmod 0444 ${IMAGE_ROOTFS}/firmware.version ${IMAGE_ROOTFS}/firmware.image_name
}
ROOTFS_POSTUNINSTALL_COMMAND:append = " do_install_firmware_version;"

create_boot_cfg_file() {
	local dir="$1"
	local dst="$2"

	# Query for real image name of kernel and rootfs
	kernel=$(ls $dir | grep -E "fitImage|Image$")
	root=$(ls $dir | grep -E ".squashfs($|.xz$|.lz4$|.lzo$)")

	# Create boot configuration
	echo "description='$(echo $root | sed 's/-${MACHINE}-/ /' | cut -d' ' -f1) - ${FULL_FW_VERSION}'" > $dst
	echo "kernel='$kernel'" >> $dst
	echo "root='$root'" >> $dst
	case "$(basename $dst)" in
		"rboot.cfg")
			echo "overlaytargets='rootfs'" >> $dst
			;;
		*)
			echo "overlaytargets='${HILSCHER_OVERLAYTARGETS}'" >> $dst
			;;
	esac

	# Signing $dst
	openssl_sign_wrapper ${PLATFORM_KEYNAME} "sha512" ${dst}
}

copy_part_content() {
	local files="$1"
	local dir="$2"

	# Move boot.cfg files to end of file list.
	fileList="$(for f in $files; do echo $f | grep -qv boot.cfg && echo -n "$f " || true; done;)"
	fileList="$fileList$(for f in $files; do echo -n $f | grep -q boot.cfg && echo -n "$f " || true; done;)"

	for file in $fileList; do
		src=$(echo "$file;" | cut -d';' -f1)
		dst=$(echo "$file;" | cut -d';' -f2)

		# Support for special handling of some contents
		if [ "$src" = "fitImage" ]; then
			if [ -n "${INITRAMFS_IMAGE}" ]; then
				src="fitImage-${INITRAMFS_IMAGE_NAME}-${KERNEL_FIT_LINK_NAME}"
			else
				src="fitImage-linux.bin-${KERNEL_FIT_LINK_NAME}"
			fi
		fi
		echo $src | grep -q "boot.cfg$" && create_boot_cfg_file $dir ${WORKDIR}/$src

		if ls ${WORKDIR}/$src 2> /dev/null ; then
			src=$(ls -d ${WORKDIR}/$src | xargs readlink -f)
		elif ls ${IMGDEPLOYDIR}/$src 2> /dev/null ; then
			src=$(ls -d ${IMGDEPLOYDIR}/$src | xargs readlink -f)
		elif ls ${DEPLOY_DIR_IMAGE}/$src 2> /dev/null ; then
			src=$(ls -d ${DEPLOY_DIR_IMAGE}/$src | xargs readlink -f)
		else
			bbfatal "$src: No such file or directory"
		fi

		for tmp_src in $src; do
			tmp_dst="$dir/${dst:-$(basename $tmp_src)}"

			echo "Copying $tmp_src -> $tmp_dst"
			mkdir -p $(dirname $tmp_dst)
			cp -r $tmp_src $tmp_dst
			[ -e "$tmp_src.sig" ] && cp $tmp_src.sig $tmp_dst.sig || true
		done
	done
}

########################################
# Signed squashfs Images
########################################

sign_squashfs_image() {
	local ext="$1"

	openssl_sign_wrapper ${PLATFORM_KEYNAME} "sha512" ${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${ext} "merge"
	ln -sf ${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.$ext.sig ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.$ext.sig
	ln -sf ${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.$ext.signed ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.$ext.signed
}

IMAGE_TYPEDEP:squashfs_signed += "squashfs"
do_image_squashfs_signed[depends] += "file-signature-native:do_populate_sysroot"
do_image_squashfs_signed[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"
IMAGE_CMD:squashfs_signed () {
	sign_squashfs_image squashfs
}

IMAGE_TYPEDEP:squashfs_xz_signed += "squashfs-xz"
do_image_squashfs_signed_xz[depends] += "file-signature-native:do_populate_sysroot"
do_image_squashfs_signed_xz[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"
IMAGE_CMD:squashfs_xz_signed () {
	sign_squashfs_image squashfs-xz
}

IMAGE_TYPEDEP:squashfs_lzo_signed += "squashfs-lzo"
do_image_squashfs_signed_lzo[depends] += "file-signature-native:do_populate_sysroot"
do_image_squashfs_signed_lzo[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"
IMAGE_CMD:squashfs_lzo_signed () {
	sign_squashfs_image squashfs-lzo
}

IMAGE_TYPEDEP:squashfs_lz4_signed += "squashfs-lz4"
do_image_squashfs_signed_lz4[depends] += "file-signature-native:do_populate_sysroot"
do_image_squashfs_signed_lz4[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"
IMAGE_CMD:squashfs_lz4_signed () {
	sign_squashfs_image squashfs-lz4
}

########################################
# WIC Image
########################################

IMAGE_TYPEDEP:wic += "squashfs_signed"

WIC_TMPDIR = "${WORKDIR}/${IMAGE_BASENAME}.wic.tmpdir"
WIC_BOOT_TMPDIR = "${WIC_TMPDIR}/boot"
WIC_RESCUE_TMPDIR = "${WIC_TMPDIR}/rescue"
WIC_SYSTEM_TMPDIR = "${WIC_TMPDIR}/system"

# For compatibility reasons, as the V2.3.x supports initrd-api files only with a prefix add a copy of initrd-api-part-cfg.
WIC_SYSTEM_PART_CONTENT:append = " ${IMAGE_LINK_NAME}.squashfs boot.cfg fitImage initrd-api-part-cfg initrd-api-part-cfg;part-cfg-initrd-api"
WIC_BOOT_PART_CONTENT:append = " ${IMAGE_BOOT_FILES}"

do_image_wic[depends] += "${HILSCHER_RESCUE_IMAGE}:do_image_complete"
do_image_wic[depends] += "file-signature-native:do_populate_sysroot"
do_image_wic[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"

do_image_wic[prefuncs] += "do_image_wic_prefunc"
do_image_wic_prefunc() {
	tmpdir=${WIC_TMPDIR}
	[ -e "$tmpdir" ] && {
		bbwarn "Removing leftover temporary directory $tmpdir from old build!"
		rm -rf $tmpdir
	}

	mkdir -p ${WIC_BOOT_TMPDIR} && {
		copy_part_content "${WIC_BOOT_PART_CONTENT}" ${WIC_BOOT_TMPDIR}
	}
	mkdir -p ${WIC_RESCUE_TMPDIR} && {
		copy_part_content "${WIC_RESCUE_PART_CONTENT}" ${WIC_RESCUE_TMPDIR}
	}
	mkdir -p ${WIC_SYSTEM_TMPDIR} && {
		copy_part_content "${WIC_SYSTEM_PART_CONTENT}" ${WIC_SYSTEM_TMPDIR}
	}
}

do_image_wic[postfuncs] += "do_image_wic_postfunc"
do_image_wic_postfunc() {
	tmpdir=${WIC_TMPDIR}

	# Clean up
	rm -rf $tmpdir
}

########################################
# SWU Image
########################################

IMAGE_TYPEDEP:swu += "wic"

SWUPDATE_SIGN_ENFORCE ??= "${PLATFORM_SIGN}"
SWUPDATE_KEYDIR ??= "${PLATFORM_KEYDIR}"
SWUPDATE_KEYNAME ??= "${PLATFORM_KEYNAME}"

SWU_TMPDIR = "${WORKDIR}/${IMAGE_BASENAME}.swu.tmpdir"

__create_sw_description_file() {
	if [ -z "${SWU_BOARD_SPEC}" ]; then
		SWU_BOARD_SPEC="$(echo ${MACHINE} | sed 's/-rev[0-9]*//')"
	fi
	if [ -z "${SWU_BOARD_REV_SPEC}" ]; then
		SWU_BOARD_REV_SPEC="$(echo ${MACHINE} | grep -oe "-rev[0-9]*" | sed 's/-rev//')"
		SWU_BOARD_REV_SPEC="${SWU_BOARD_REV_SPEC:-0}"
	fi

	echo "software ="
	echo "{"
	echo "	version = \"${FULL_FW_VERSION}\";"
	echo ""
	echo "	${SWU_BOARD_SPEC} = {"
	echo "		hardware-compatibility: [\"$(echo ${SWU_BOARD_REV_SPEC} | sed 's/ /\",\"/g')\"];"
	echo ""

	[ -n "$swu_files" ] && {
		echo "		files: ("
		for f in $swu_files; do
			# extract real filename
			f=$(echo "$f" | cut -d';' -f2)
			echo "			{"
			echo "				filename = \"$f\";"
			echo "				sha256 = \"$(sha256sum $f | cut -d' ' -f1)\";"

			# search for file attributes and separate these by spaces
			for fattr in $swu_file_attributes dummy; do
				[ "$(echo $fattr';' | cut -d';' -f1)" = "$f" ] && break
				fattr=""
			done
			fattr="$(echo $fattr | cut -d';' -f2- | tr ';' ' ')"

			# add mandatory default path if not available
			echo $fattr | grep -q path || fattr="$fattr path=\"/media/system/$f\""

			# add attributes to sw-description file
			for attr in $fattr; do
				attr=$(echo $attr | sed 's,=, = ,')
				[ "$attr" = "version" ] && attr="$attr = \"$(sha256sum $f | cut -d' ' -f1)\""
				echo "				$attr;"
			done
			echo "			},"
		done
		echo "		);"
	}
	[ -n "$swu_images" ] && {
		echo ""
		echo "		images: ("
		for f in $swu_images; do
			# extract real filename
			f=$(echo "$f" | cut -d';' -f2)
			echo "			{"
			echo "				filename = \"$f\";"
			echo "				sha256 = \"$(sha256sum $f | cut -d' ' -f1)\";"

			# search for image attributes and separate these by spaces
			for fattr in $swu_image_attributes dummy; do
				[ "$(echo $fattr';' | cut -d';' -f1)" = "$f" ] && break
				fattr=""
			done
			fattr="$(echo $fattr | cut -d';' -f2- | tr ';' ' ')"

			# add attributes to sw-description file
			for attr in $fattr; do
				attr=$(echo $attr | sed 's,=, = ,')
				[ "$attr" = "version" ] && attr="$attr = \"$(sha256sum $f | cut -d' ' -f1)\""
				echo "				$attr;"
			done
			echo "			},"
		done
		echo "		);"
	}
	[ -n "$swu_scripts" ] && {
		echo ""
		echo "		scripts: ("
		for f in $swu_scripts; do
			# extract real filename
			f=$(echo "$f" | cut -d';' -f2)
			echo "			{"
			echo "				filename = \"$f\";"
			echo "				sha256 = \"$(sha256sum $f | cut -d' ' -f1)\";"

			# search for script attributes and separate these by spaces
			for fattr in $swu_script_attributes dummy; do
				[ "$(echo $fattr';' | cut -d';' -f1)" = "$f" ] && break
				fattr=""
			done
			fattr="$(echo $fattr | cut -d';' -f2- | tr ';' ' ')"

			# add script type if not available
			echo $fattr | grep type || {
				echo $f | grep -q ".lua$" && fattr="$fattr type=\"lua\""
				echo $f | grep -q ".sh$" && fattr="$fattr type=\"shellscript\""
			}

			# add attributes to sw-description file
			for attr in $fattr; do
				attr=$(echo $attr | sed 's,=, = ,')
				echo "				$attr;"
			done
			echo "			},"
		done
		echo "		);"
	}
	echo "	}"
	echo "}"
}

create_sw_description_file() {
	local dir="${1:-$PWD}"
	local dst="${2:-$dir/sw-description}"

	cd $dir
	__create_sw_description_file > $dst
	cd -
}

do_image_swu[depends] += "${HILSCHER_RESCUE_IMAGE}:do_image_complete"
do_image_swu[depends] += "file-signature-native:do_populate_sysroot"
do_image_swu[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME SWUPDATE_HELPER_FILES"

IMAGE_CMD:swu() {
	swu_files="${SWU_FILES}"
	swu_file_attributes="${SWU_FILE_ATTRIBUTES}"
	swu_images="${SWU_IMAGES}"
	swu_image_attributes="${SWU_IMAGE_ATTRIBUTES}"
	swu_scripts="${SWU_SCRIPTS}"
	swu_script_attributes="${SWU_SCRIPT_ATTRIBUTES}"

	tmpdir=${SWU_TMPDIR}
	[ -e "$tmpdir" ] && {
		bbwarn "Removing leftover temporary directory $tmpdir from old build!"
		rm -rf $tmpdir
	}
	mkdir -p $tmpdir
	cd $tmpdir

	if [ -z "${SWU_RSYNC_PART_UPDATE}" ]; then
		# Populate temporary directory
		copy_part_content "$swu_files $swu_images $swu_scripts" ./
		copy_part_content "${SWU_SYSTEM_PART_CONTENT}" ./
		swu_files="$swu_files ${SWU_SYSTEM_PART_CONTENT}"
	else
		# Populate temporary directory
		copy_part_content "$swu_files $swu_images $swu_scripts" ./
		for p in $(echo ${SWU_RSYNC_PART_UPDATE}); do
			case "$p" in
			"boot")
				mkdir -p $tmpdir/boot
				copy_part_content "${SWU_BOOT_PART_CONTENT}" ./boot
				mksquashfs ./boot boot.squashfs
				rm -rf $tmpdir/boot
				swu_files="$swu_files boot.squashfs"
				swu_file_attributes="$swu_file_attributes boot.squashfs;path=\"/dev/null\""
				;;
			"system")
				mkdir -p $tmpdir/system
				copy_part_content "${SWU_SYSTEM_PART_CONTENT}" ./system
				mksquashfs ./system system.squashfs
				rm -rf $tmpdir/system
				swu_files="$swu_files system.squashfs"
				swu_file_attributes="$swu_file_attributes system.squashfs;path=\"/dev/null\""
				;;
			*)
				bbwarn "Skip unsupported '$p' in SWU_RSYNC_PART_UPDATE!"
				;;
			esac
		done
	fi

	# If necessary create a sw-description file
	[ ! -e sw-description ] && create_sw_description_file

	# Create file list for SWU image content
	fileList="sw-description"
	[ "${SWUPDATE_SIGN_ENFORCE}" != "0" ] && {
		# If necessary sign sw-description file
		SIGN_WRAPPER_KEY_SRC="${SWUPDATE_KEYDIR}"
		openssl_sign_wrapper "${SWUPDATE_KEYNAME}" "sha256" "sw-description"
		fileList="$fileList sw-description.sig"
	}
	for file in $(find . -type f ! -name 'sw-description*'); do
		fileList="$fileList $file"
	done

	# Create swu-image file
	for file in $fileList; do
		echo $file
	done | cpio -ov -H crc > ${IMGDEPLOYDIR}/${IMAGE_NAME}.update.swu
	ln -sf ${IMAGE_NAME}.update.swu ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.update.swu

	# Clean up
	cd -
	rm -rf $tmpdir
}

########################################
# Licenses Image
########################################

IMAGE_CMD:licenses.tar() {
    # create archived licenses
    cd ${DEPLOY_DIR}
    find licenses -maxdepth 1 ! -path licenses ! -name '*-native' -exec tar uf ${IMGDEPLOYDIR}/${IMAGE_NAME}.rootfs.licenses.tar {} \;
}

########################################
# FASTBOOT Image
########################################

IMAGE_TYPEDEP:fastboot += "wic"

SIMG_BLOCK_SIZE = "1024"

do_image_fastboot[depends] += "android-tools-native:do_populate_sysroot"
IMAGE_CMD:fastboot() {
	wic_image="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.wic"

	# Read signatur of GPT header: 512 (MBR) + 0 (Offset in GPT header).
	part_signature="$(od $wic_image -j 512 -N 8 -t c | head -n1 | cut -d' ' -f2- | sed 's, ,,g')"
	if [ "$part_signature" = "EFIPART" ]; then
		# Read the first usable LBA for partitions: 512 (MBR) + 40 (Offset in GPT header).
		part_start_lba="$(od $wic_image -j 552 -N 8 -t u8 | head -n1 | cut -d' ' -f2- | sed 's, ,,g')"

		# Extract the GPT + MBR
		dd if=$wic_image of=${IMGDEPLOYDIR}/${IMAGE_NAME}.gpt.raw.fastboot bs=512 count=$part_start_lba

		# Create symlink
		ln -sf ${IMAGE_NAME}.gpt.raw.fastboot ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.gpt.raw.fastboot
	else
		bbfatal "Error: No GUID Partition Table (GPT) found in WIC image!"
		exit 1
	fi

	for part in $(parted -sm $wic_image unit B print | grep ^[0-9] | cut -d':' -f2,3,4,6); do
		# Extract the partition information.
		pstart="$(echo $part | cut -d':' -f1 | sed 's,B,,')"
		psize="$(echo $part | cut -d':' -f3 | sed 's,B,,')"
		pname="$(echo $part | cut -d':' -f4)"

		# Extract the partition image.
		dd if=$wic_image of=${IMGDEPLOYDIR}/${IMAGE_NAME}.$pname.raw.fastboot iflag=skip_bytes,count_bytes skip=$pstart bs=1M count=$psize
		# Create symlink
		ln -sf ${IMAGE_NAME}.$pname.raw.fastboot ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.$pname.raw.fastboot

		if [ "$pname" != "boot" ]; then
			# Pad up and create a fastboot sparse file.
			truncate -s %${SIMG_BLOCK_SIZE} ${IMGDEPLOYDIR}/${IMAGE_NAME}.$pname.raw.fastboot
			img2simg ${IMGDEPLOYDIR}/${IMAGE_NAME}.$pname.raw.fastboot ${IMGDEPLOYDIR}/${IMAGE_NAME}.$pname.sparse.fastboot ${SIMG_BLOCK_SIZE}

			# Remove raw files and create new sparse symlink
			rm ${IMGDEPLOYDIR}/${IMAGE_NAME}.$pname.raw.fastboot
			rm ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.$pname.raw.fastboot
			ln -sf ${IMAGE_NAME}.$pname.sparse.fastboot ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.$pname.sparse.fastboot
		fi
	done
}
