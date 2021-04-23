inherit kernel-artifact-names

HILSCHER_RESCUE_IMAGE_LINK_NAME ??= "${HILSCHER_RESCUE_IMAGE}-${MACHINE}"
INITRAMFS_IMAGE ??= ""

########################################
# Anonymous python function for firmware version handling
########################################
inherit hilscher-firmware-version

# Add firmware version to image name
IMAGE_VERSION_SUFFIX =. "-${FULL_FW_VERSION}"

########################################
# Anonymous python function to fix ROOTFS_POSTPROCESS_COMMAND_remove
########################################
python () {
    # Because 'ROOTFS_POSTPROCESS_COMMAND' list is very ugly constructed, it isn't possible
    # to remove some commands in a use of 'ROOTFS_POSTPROCESS_COMMAND_remove'.
    # Therfore we implemented a further way to remove commands from list.
    # Use 'ROOTFS_POSTPROCESS_COMMAND_removeFix' instead of 'ROOTFS_POSTPROCESS_COMMAND_remove'!

    cmdList = d.getVar('ROOTFS_POSTPROCESS_COMMAND') or ""
    cmdRemoveList = d.getVar('ROOTFS_POSTPROCESS_COMMAND_removeFix') or ""

    cmdList = cmdList.replace(' ', '')

    for cmdRemove in cmdRemoveList.split():
        cmdList = cmdList.replace(cmdRemove, '')

    cmdList = cmdList.replace(';', '; ')
    d.setVar('ROOTFS_POSTPROCESS_COMMAND', cmdList)
}
ROOTFS_POSTPROCESS_COMMAND_removeFix += "rootfs_update_timestamp;"

# Mark the following line as comment to support the yocto test framework!
#ROOTFS_POSTPROCESS_COMMAND_removeFix += "write_image_test_data;"

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
ROOTFS_POSTUNINSTALL_COMMAND_append += "do_install_firmware_manifest;"

do_install_firmware_version() {
   echo ${FULL_FW_VERSION} > ${IMAGE_ROOTFS}/firmware.version
   echo ${IMAGE_NAME} > ${IMAGE_ROOTFS}/firmware.image_name
   chmod 0444 ${IMAGE_ROOTFS}/firmware.version ${IMAGE_ROOTFS}/firmware.image_name
}
ROOTFS_POSTUNINSTALL_COMMAND_append += "do_install_firmware_version;"

create_boot_cfg_file() {
	local dir="$1"
	local dst="$2"

	# Query for real image name of kernel and rootfs
	kernel=$(ls $dir | grep -E "fitImage|Image$")
	root=$(ls $dir | grep ".squashfs$")

	# Create boot configuration
	echo "description='$(echo $root | sed 's/-${MACHINE}-/ /' | cut -d' ' -f1) - ${FULL_FW_VERSION}'" > $dst
	echo "kernel='$kernel'" >> $dst
	echo "root='$root'" >> $dst
	case "$(basename $dst)" in
		"rboot.cfg")
			echo "overlay=''" >> $dst
			echo "overlaytargets='rootfs'" >> $dst
			;;
		*)
			echo "overlay='${HILSCHER_OVERLAY}'" >> $dst
			echo "overlaytargets='${HILSCHER_OVERLAYTARGETS}'" >> $dst
			;;
	esac

	# Signing $dst
	priv_key=""
	if [ "${@bb.utils.contains('PLATFORM_SIGN', '1', 'true', 'false', d)}" = "true" ]; then
		priv_key="${PLATFORM_KEYDIR}/${PLATFORM_KEYNAME}.key"
		[ ! -e "$priv_key" ] && bbfatal "Signing key $priv_key not found"
	fi
	sign_file $dst $priv_key
	rm $dst.signed
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

	priv_key=""
	if [ "${@bb.utils.contains('PLATFORM_SIGN', '1', 'true', 'false', d)}" = "true" ]; then
		priv_key="${PLATFORM_KEYDIR}/${PLATFORM_KEYNAME}.key"
		[ ! -e "$priv_key" ] && bbfatal "Signing key $priv_key not found"
	fi

	sign_file ${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.$ext $priv_key
	ln -sf ${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.$ext.sig ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.$ext.sig
	ln -sf ${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.$ext.signed ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.$ext.signed
}

IMAGE_TYPEDEP_squashfs_signed += "squashfs"
do_image_squashfs_signed[depends] += "file-signature-native:do_populate_sysroot"
do_image_squashfs_signed[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"
IMAGE_CMD_squashfs_signed () {
	sign_squashfs_image squashfs
}

IMAGE_TYPEDEP_squashfs_xz_signed += "squashfs_xz"
do_image_squashfs_signed_xz[depends] += "file-signature-native:do_populate_sysroot"
do_image_squashfs_signed_xz[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"
IMAGE_CMD_squashfs_xz_signed () {
	sign_squashfs_image squashfs_xz
}

IMAGE_TYPEDEP_squashfs_lzo_signed += "squashfs_lzo"
do_image_squashfs_signed_lzo[depends] += "file-signature-native:do_populate_sysroot"
do_image_squashfs_signed_lzo[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"
IMAGE_CMD_squashfs_lzo_signed () {
	sign_squashfs_image squashfs_lzo
}

IMAGE_TYPEDEP_squashfs_lz4_signed += "squashfs_lz4"
do_image_squashfs_signed_lz4[depends] += "file-signature-native:do_populate_sysroot"
do_image_squashfs_signed_lz4[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"
IMAGE_CMD_squashfs_lz4_signed () {
	sign_squashfs_image squashfs_lz4
}

########################################
# WIC Image
########################################

IMAGE_TYPEDEP_wic += "squashfs_signed"

WIC_TMPDIR = "${WORKDIR}/${IMAGE_BASENAME}.wic.tmpdir"
WIC_BOOT_TMPDIR = "${WIC_TMPDIR}/boot"
WIC_RESCUE_TMPDIR = "${WIC_TMPDIR}/rescue"
WIC_SYSTEM_TMPDIR = "${WIC_TMPDIR}/system"

WIC_BOOT_PART_BASE_CONTENT ??= ""
WIC_RESCUE_PART_BASE_CONTENT ??= "${HILSCHER_RESCUE_IMAGE_LINK_NAME}.squashfs"
WIC_SYSTEM_PART_BASE_CONTENT ??= "${IMAGE_LINK_NAME}.squashfs"

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
		copy_part_content "${WIC_BOOT_PART_BASE_CONTENT} ${WIC_BOOT_PART_EXTRA_CONTENT}" ${WIC_BOOT_TMPDIR}
	}
	mkdir -p ${WIC_RESCUE_TMPDIR} && {
		copy_part_content "${WIC_RESCUE_PART_BASE_CONTENT} ${WIC_RESCUE_PART_EXTRA_CONTENT}" ${WIC_RESCUE_TMPDIR}
	}
	mkdir -p ${WIC_SYSTEM_TMPDIR} && {
		copy_part_content "${WIC_SYSTEM_PART_BASE_CONTENT} ${WIC_SYSTEM_PART_EXTRA_CONTENT}" ${WIC_SYSTEM_TMPDIR}
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

IMAGE_TYPEDEP_swu += "wic"

SWUPDATE_SIGN_ENFORCE ??= "${PLATFORM_SIGN}"
SWUPDATE_KEYDIR ??= "${PLATFORM_KEYDIR}"
SWUPDATE_KEYNAME ??= "${PLATFORM_KEYNAME}"

SWU_TMPDIR = "${WORKDIR}/${IMAGE_BASENAME}.swu.tmpdir"

SWU_BOOT_PART_BASE_CONTENT ??= "${WIC_BOOT_PART_BASE_CONTENT}"
SWU_SYSTEM_PART_BASE_CONTENT ??= "${WIC_SYSTEM_PART_BASE_CONTENT}"

__create_sw_description_file() {
	local fileList="$(find . -type f ! -name 'sw-description*' ! -name *.lua ! -name '*.sh' | sed 's,^./,,' | sort)"
	local scriptList="$(find . -name '*.lua' -o -name '*.sh' | sed 's,^./,,' | sort)"

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
	[ -n "$fileList" ] && {
		echo "		files: ("
		for f in $fileList; do
			filename="$f"
			path="/media/system/$f"
			for fattr in $(echo "${SWU_FILE_ATTRIBUTES}"); do
				[ "$(echo $fattr';' | cut -d';' -f1)" != "$f" ] && continue
				for attr in $(echo $fattr | cut -d';' -f2- | tr ';' ' '); do
					attr=$(echo $attr | sed 's,=, = ,')
					echo "$attr" | grep -q path && { path="$(echo $attr | cut -d'"' -f2)"; continue; }
				done
			done
			echo "			{"
			echo "				filename = \"$filename\";"
			echo "				sha256 = \"$(sha256sum $f | cut -d' ' -f1)\";"
			case "$f" in
				"boot.squashfs" | "system.squashfs")
					# Set path to /dev/null so file is not copied to disk if tmpdir and path is different
					# Copying is done after running preinstall step
					echo "				path = \"/dev/null\";"
					;;
				*)
					echo "				path = \"$path\";"
					;;
			esac

			for fattr in $(echo "${SWU_FILE_ATTRIBUTES}"); do
				[ "$(echo $fattr';' | cut -d';' -f1)" != "$f" ] && continue
				for attr in $(echo $fattr | cut -d';' -f2- | tr ';' ' '); do
					attr=$(echo $attr | sed 's,=, = ,')
					echo "$attr" | grep -q path && continue
					[ "$attr" = "version" ] && attr="$attr = \"$(sha256sum $f | cut -d' ' -f1)\""
					echo "				$attr;"
				done
			done

			echo "			},"
		done
		echo "		);"
	}
	[ -n "$scriptList" ] && {
		echo ""
		echo "		scripts: ("
		for f in $scriptList; do
			echo "			{"
			echo "				filename = \"$f\";"
			echo $f | grep -q ".lua$" && echo "				type = \"lua\";"
			echo $f | grep -q ".sh$" && echo "				type = \"shellscript\";"
			echo "				sha256 = \"$(sha256sum $f | cut -d' ' -f1)\";"
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

inherit hilscher-helpers
SWUPDATE_DIRS = "${TOPDIR}/../meta-hilscher-netfield/files/swupdate"
SWUPDATE_HELPER_FILES = "${@dir_dep_hash(d, d.getVar('SWUPDATE_DIRS'))}"
do_image_swu[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME SWUPDATE_HELPER_FILES"

IMAGE_CMD_swu() {
	tmpdir=${SWU_TMPDIR}
	[ -e "$tmpdir" ] && {
		bbwarn "Removing leftover temporary directory $tmpdir from old build!"
		rm -rf $tmpdir
	}
	mkdir -p $tmpdir
	cd $tmpdir

	for dir in ${SWUPDATE_DIRS}; do
		[ -e "$dir/default" ] && default_swudir=${default_swudir:-"$dir/default"}
		[ -e "$dir/${PART_SCHEME}" ] && swudir=${swudir:-"$dir/${PART_SCHEME}"}
	done
	swudir=${swudir:-$default_swudir}
	bbnote "SWU image creation uses directory: $swudir"

	if [ -z "${SWU_RSYNC_PART_UPDATE}" ]; then
		# Populate temporary directory
		cp -r $swudir/* ./
		copy_part_content "${SWU_SYSTEM_PART_BASE_CONTENT}" ./
		copy_part_content "${SWU_SYSTEM_PART_EXTRA_CONTENT}" ./
	else
		# Populate temporary directory
		cp -r $swudir/* ./
		for p in $(echo ${SWU_RSYNC_PART_UPDATE}); do
			case "$p" in
			"boot")
				mkdir -p $tmpdir/boot
				copy_part_content "${SWU_BOOT_PART_BASE_CONTENT}" ./boot
				copy_part_content "${SWU_BOOT_PART_EXTRA_CONTENT}" ./boot
				mksquashfs ./boot boot.squashfs
				rm -rf $tmpdir/boot
				;;
			"system")
				mkdir -p $tmpdir/system
				copy_part_content "${SWU_SYSTEM_PART_BASE_CONTENT}" ./system
				copy_part_content "${SWU_SYSTEM_PART_EXTRA_CONTENT}" ./system
				mksquashfs ./system system.squashfs
				rm -rf $tmpdir/system
				;;
			*)
				bbwarn "Skip unsupported '$p' in SWU_RSYNC_PART_UPDATE!"
				;;
			esac
		done
		copy_part_content "${SWU_FILES}" ./
	fi

	# If necessary create a sw-description file
	[ ! -e sw-description ] && create_sw_description_file

	# Create file list for SWU image content
	fileList="sw-description"
	[ "${SWUPDATE_SIGN_ENFORCE}" != "0" ] && {
		# If necessary sign sw-description file
		openssl dgst -sha256 -sign ${SWUPDATE_KEYDIR}/${SWUPDATE_KEYNAME}.key sw-description > sw-description.sig
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

IMAGE_CMD_licenses.tar() {
    # create archived licenses
    cd ${DEPLOY_DIR}
    find licenses -maxdepth 1 ! -path licenses ! -name '*-native' -exec tar uf ${IMGDEPLOYDIR}/${IMAGE_NAME}.rootfs.licenses.tar {} \;
}

########################################
# FASTBOOT Image
########################################

IMAGE_TYPEDEP_fastboot += "wic"

SIMG_BLOCK_SIZE = "1024"

do_image_fastboot[depends] += "android-tools-native:do_populate_sysroot"
IMAGE_CMD_fastboot() {
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

########################################
# Hilscher Deploy
########################################

HILSCHER_DEPLOY_ROOT_DIR ??= "${DEPLOY_DIR}/dist/"
DEPLOY_EXT_LIST ??= "${IMAGE_FSTYPES}"

do_image_complete[postfuncs] += "do_hilscher_deploy"
do_hilscher_deploy() {
	[ "${IMAGE_BASENAME}" = "${INITRAMFS_IMAGE}" ] && return 0
	[ "${IMAGE_BASENAME}" = "${HILSCHER_RESCUE_IMAGE}" ] && return 0

	hilscherDeployRootDir="${@d.getVar('HILSCHER_DEPLOY_ROOT_DIR')}"

	deploydir="${hilscherDeployRootDir}/${MACHINE}/${IMAGE_BASENAME}/${FULL_FW_VERSION}"

	mkdir -p $deploydir
	cd $deploydir

	extList="${DEPLOY_EXT_LIST}"
	for ext in $extList; do
		# Delete old image typs
		rm -f $deploydir/*.$ext

		# Deploy images
		for file in $(find ${IMGDEPLOYDIR} -type l -name "*.$ext"); do
			cp -a $(readlink -f $file) .
			ln -sf $(readlink $file) ./$(basename $file)
		done
	done

	HILSCHER_DISTRO_BASE="${TOPDIR}/../meta-hilscher-netfield"
	# Install script for easy deploying wic.bz2 images
	[ -n "$(find -name '*.wic.bz2')" ] && install -m 755 ${HILSCHER_DISTRO_BASE}/scripts/deploy-wic-bz2 ./

	# Install script for easy deploying fastboot images
	[ -n "$(find -name '*.fastboot')" ] && install -m 755 ${HILSCHER_DISTRO_BASE}/scripts/deploy-fastboot ./

	cd -
}
