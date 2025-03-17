inherit sign-wrapper hilscher-image-check

NETFIELD_IMAGES ??= "recovery.zip recovery.swu"
USB_BOOT_FILES ??= "boot-script-fit/fitImage-boot-recovery.scr;boot-fit.scr fitImage-${INITRAMFS_IMAGE_NAME}-${KERNEL_FIT_LINK_NAME};Image"

INITRD_API_RECOVERY ??= "initrd-api-recovery"

DEPENDS:append = " zip-native unzip-native openssl-native squashfs-tools-native coreutils-native"
DEPENDS:append = " ${@bb.utils.contains_any('NETFIELD_IMAGES', 'recovery.swu', 'cpio-native', '', d)}"

# NOTE: as long as recovery images are netfield specific we provide image creation and deploy in one step (post-image_complete)
do_image_complete[prefuncs] += "${@bb.utils.contains_any('NETFIELD_IMAGES', 'recovery.swu recovery.zip', 'create_initrd_api_recovery', '', d)}"
do_image_complete[prefuncs] += "${@bb.utils.contains_any('NETFIELD_IMAGES', 'recovery.swu', 'netfield_create_recovery_swu', '', d)}"
do_image_complete[prefuncs] += "${@bb.utils.contains_any('NETFIELD_IMAGES', 'recovery.zip', 'netfield_create_recovery_zip', '', d)}"

# Make sure recovery.zip is deployed to dist directory
DEPLOY_EXT_LIST:append = " ${@bb.utils.filter('NETFIELD_IMAGES', 'recovery.zip', d)}"

create_initrd_api_recovery() {
  image_wic="${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.wic.bz2"

  if [ ! -e "${image_wic}" ]; then
    bbfatal "Error creating recovery image! Base image \"${image_wic}\" does not exist."
  fi

  setup_sign_wrapper_env "${PLATFORM_KEYNAME}"
  local signing_key=$(setup_sign_wrapper_env "${PLATFORM_KEYNAME}")

  mkdir -p ${WORKDIR}/initrd_api_recovery/firmware
  cp ${WORKDIR}/recipe-sysroot/usr/share/initrd-api/recovery/* ${WORKDIR}/initrd_api_recovery/
  cp ${image_wic} ${WORKDIR}/initrd_api_recovery/firmware

  echo ${DATE} > ${WORKDIR}/initrd_api_recovery/firmware/timestamp
  echo ${FULL_FW_VERSION} > ${WORKDIR}/initrd_api_recovery/firmware/firmware.version

  tar -czf "${WORKDIR}/${INITRD_API_RECOVERY}" -C ${WORKDIR}/initrd_api_recovery/ .
  openssl_sign_wrapper "${PLATFORM_KEYNAME}" "sha512" "${WORKDIR}/${INITRD_API_RECOVERY}" "merge"

  cp "${WORKDIR}/${INITRD_API_RECOVERY}.signed" "${DEPLOY_DIR_IMAGE}/${INITRD_API_RECOVERY}.signed"

  rm -r ${WORKDIR}/initrd_api_recovery/
}

__generate_swu() {
  # Create hashes
  hashImage=$(sha256sum ${tmpdir}/${INITRD_API_RECOVERY} | cut -d' ' -f1)
  hashHelper=$(sha256sum ${tmpdir}/helper.lua | cut -d' ' -f1)

  if [ -z "${SWU_BOARD_SPEC}" ]; then
    SWU_BOARD_SPEC="$(echo ${MACHINE} | sed 's/-rev[0-9]*//')"
  fi
  if [ -z "${SWU_BOARD_REV_SPEC}" ]; then
    SWU_BOARD_REV_SPEC="$(echo ${MACHINE} | grep -oe "-rev[0-9]*" | sed 's/-rev//')"
    SWU_BOARD_REV_SPEC="${SWU_BOARD_REV_SPEC:-0}"
  fi

  ##########################
  # Create sw-description file
  ##########################
  echo "software ="
  echo "{"
  echo "	version = \"${FULL_FW_VERSION}\";"
  echo ""
  echo "	${SWU_BOARD_SPEC} = {"
  echo "		hardware-compatibility: [\"$(echo ${SWU_BOARD_REV_SPEC} | sed 's/ /\",\"/g')\"];"
  echo ""
  echo "		files: ("
  echo "			{"
  echo "				filename = \"${INITRD_API_RECOVERY}\";"
  echo "				path = \"/mnt/system/${INITRD_API_RECOVERY}\";"
  echo "				sha256 = \"$hashImage\";"
  echo "			}"
  echo "		);"
  echo ""
  echo "		scripts: ("
  echo "			{"
  echo "				filename = \"helper.lua\";"
  echo "				type = \"lua\";"
  echo "				sha256 = \"$hashHelper\";"
  echo "			}"
  echo "		);"
  echo "	}"
  echo "}"
}

netfield_create_recovery_swu() {
  rm -f ${IMGDEPLOYDIR}/*.recovery.swu

  tmpdir=$(mktemp -d)

  cp ${DEPLOY_DIR_IMAGE}/${INITRD_API_RECOVERY}.signed ${tmpdir}/${INITRD_API_RECOVERY}

  # Patch scripts
  sed -e "s/@FW_VERSION@/${FULL_FW_VERSION}/g" ${NETFIELD_BASE}/scripts/swupdate/helper.lua > ${tmpdir}/helper.lua

  __generate_swu > ${tmpdir}/sw-description

  # Sign sw-description file
  openssl_sign_wrapper "${PLATFORM_KEYNAME}" "sha256" "${tmpdir}/sw-description"

  # Create swu-image file with the same name as the zip archive
  cd ${tmpdir}
  swu_recovery_file="${IMGDEPLOYDIR}/${IMAGE_NAME}.recovery.swu"
  filelist="sw-description sw-description.sig $(ls -I 'sw-description*')"
  for file in ${filelist}; do
    echo ${file}
  done | cpio -ov -H crc > "${swu_recovery_file}"
  ln -sf $(basename ${swu_recovery_file}) ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.recovery.swu
  cd -

  # Clean up
  rm -rf ${tmpdir}
}

netfield_create_recovery_zip() {
  image_zip="${IMGDEPLOYDIR}/${IMAGE_NAME}.recovery.zip"

  rm -f ${IMGDEPLOYDIR}/*.recovery.zip

  mkdir -p ${WORKDIR}/usb_zip
  cp ${DEPLOY_DIR_IMAGE}/${INITRD_API_RECOVERY}.signed ${WORKDIR}/usb_zip/${INITRD_API_RECOVERY}

  local files_to_copy="${ADDITIONAL_USB_FILES} ${USB_BOOT_FILES}"
  for add_usb_file in $files_to_copy; do
    local src_file=$(echo "$add_usb_file" | cut -d ';' -f1)
    local dst_file=$(echo "$add_usb_file" | cut -d ';' -f2)
    [ -z "$dst_file" ] && dst_file=$(basename $src_file)
    mkdir -p ${WORKDIR}/usb_zip/$(dirname $dst_file)
    cp -L ${DEPLOY_DIR_IMAGE}/$src_file ${WORKDIR}/usb_zip/$dst_file
  done

  # Copy bootloader
  [ -e ${DEPLOY_DIR_IMAGE}/boot-files/bootx64.efi ] && {
    mkdir -p ${WORKDIR}/usb_zip/EFI/BOOT
    cp -L ${DEPLOY_DIR_IMAGE}/boot-files/bootx64.efi ${WORKDIR}/usb_zip/EFI/BOOT
  }

  echo ${FIRMWARE_VERSION} > ${WORKDIR}/usb_zip/VERSION

  cd ${WORKDIR}/usb_zip/

  zip -r "${image_zip}" ./*

  ln -sf $(basename ${image_zip}) ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.recovery.zip

  rm -r ${WORKDIR}/usb_zip
}
