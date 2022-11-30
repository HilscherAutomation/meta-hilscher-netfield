inherit sign-wrapper hilscher-image-check

NETFIELD_IMAGES ??= "recovery.zip recovery.swu"
HILSCHER_EXTRA_ZIP_OPTIONS ??= ""

RECOVERY_INITRD_API ??= "initrd-api-firmware"

DEPENDS_append += "zip-native unzip-native openssl-native squashfs-tools-native coreutils-native"
DEPENDS_append += "${@bb.utils.contains_any('NETFIELD_IMAGES', 'recovery.swu', 'cpio-native', '', d)}"

# NOTE: as long as recovery images are netfield specific we provide image creation and deploy in one step (post-image_complete)
do_image_complete[prefuncs] += "${@bb.utils.contains_any('NETFIELD_IMAGES', 'recovery.swu recovery.zip', 'create_recovery_initrd_api', '', d)}"
do_image_complete[prefuncs] += "${@bb.utils.contains_any('NETFIELD_IMAGES', 'recovery.swu', 'netfield_create_recovery_swu', '', d)}"
do_image_complete[prefuncs] += "${@bb.utils.contains_any('NETFIELD_IMAGES', 'recovery.zip', 'netfield_create_recovery_zip', '', d)}"

# Make sure recovery.zip is deployed to dist directory
DEPLOY_EXT_LIST_append += "${@bb.utils.filter('NETFIELD_IMAGES', 'recovery.zip', d)}"

create_recovery_initrd_api() {
  image_wic="${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.wic.bz2"

  if [ ! -e "${image_wic}" ]; then
    bbfatal "Error creating recovery image! Base image \"${image_wic}\" does not exist."
  fi

  setup_sign_wrapper_env "${PLATFORM_KEYNAME}"
  local signing_key=$(setup_sign_wrapper_env "${PLATFORM_KEYNAME}")

  mkdir -p ${WORKDIR}/firmware_api/firmware
  cp ${WORKDIR}/recipe-sysroot-native/usr/share/initrd-api/recovery/* ${WORKDIR}/firmware_api/
  cp ${image_wic} ${WORKDIR}/firmware_api/firmware

  echo ${DATE} > ${WORKDIR}/firmware_api/firmware/timestamp
  echo ${FULL_FW_VERSION} > ${WORKDIR}/firmware_api/firmware.version

  tar -czf "${WORKDIR}/${RECOVERY_INITRD_API}" -C ${WORKDIR}/firmware_api/ .
  openssl_sign_wrapper "${PLATFORM_KEYNAME}" "sha512" "${WORKDIR}/${RECOVERY_INITRD_API}" "merge"

  cp "${WORKDIR}/${RECOVERY_INITRD_API}.signed" "${DEPLOY_DIR_IMAGE}/recovery-initrd-api.signed"

  rm -r ${WORKDIR}/firmware_api/
}

__generate_swu() {
  # Create hashes
  hashFirmwareImage=$(sha256sum ${tmpdir}/initrd-api-firmware | cut -d' ' -f1)
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
  echo "				filename = \"initrd-api-firmware\";"
  echo "				path = \"/mnt/system/initrd-api\";"
  echo "				sha256 = \"$hashFirmwareImage\";"
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

  cp ${DEPLOY_DIR_IMAGE}/recovery-initrd-api.signed ${tmpdir}/${RECOVERY_INITRD_API}

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
  cp ${DEPLOY_DIR_IMAGE}/recovery-initrd-api.signed ${WORKDIR}/usb_zip/${RECOVERY_INITRD_API}
  cp ${DEPLOY_DIR_IMAGE}/boot-script-fit/fitImage-boot-recovery.scr ${WORKDIR}/usb_zip/boot-fit.scr
  cp ${DEPLOY_DIR_IMAGE}/fitImage-core-image-minimal-initramfs*.bin ${WORKDIR}/usb_zip/Image

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
