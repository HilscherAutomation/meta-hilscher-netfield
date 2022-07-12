inherit sign-wrapper hilscher-image-check

NETFIELD_IMAGES ??= "recovery.zip recovery.swu"
HILSCHER_EXTRA_ZIP_OPTIONS ??= ""

DEPENDS_append += "zip-native unzip-native openssl-native squashfs-tools-native coreutils-native"
DEPENDS_append += "${@bb.utils.contains_any('NETFIELD_IMAGES', 'recovery.swu', 'cpio-native', '', d)}"

# NOTE: as long as recovery images are netfield specific we provide image creation and deploy in one step (post-image_complete)
do_image_complete[prefuncs] += "${@bb.utils.contains_any('NETFIELD_IMAGES', 'recovery.swu', 'netfield_create_recovery_swu', '', d)}"
do_image_complete[prefuncs] += "${@bb.utils.contains_any('NETFIELD_IMAGES', 'recovery.zip', 'netfield_create_recovery_zip', '', d)}"

# Make sure recovery.zip is deployed to dist directory
DEPLOY_EXT_LIST_append += "${@bb.utils.filter('NETFIELD_IMAGES', 'recovery.zip', d)}"

__generate_swu() {
  # Create hashes
  hashFirmwareImage=$(sha256sum ${tmpdir}/firmware | cut -d' ' -f1)
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
  echo "				filename = \"firmware\";"
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
  image_wic="${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.wic.bz2"

  rm -f ${IMGDEPLOYDIR}/*.recovery.swu

  if [ ! -e "${image_wic}" ]; then
    bbfatal "Error creating swu-recovery image! Base image \"${image_wic}\" does not exist."
  fi

  # Create a working directory
  tmpdir_tmp=$(mktemp -d)

  cd ${tmpdir_tmp}
  # create firmware file with runscript (see deploy/_firmware) and wic-image
  export PHYSICAL_SYSTEM_DEVICE="${PHYSICAL_SYSTEM_DEVICE}"
  export FIRMWARE_VERSION="${FULL_FW_VERSION}"

  setup_sign_wrapper_env "${PLATFORM_KEYNAME}"
  local signing_key=$(setup_sign_wrapper_env "${PLATFORM_KEYNAME}")
  case "${SIGN_WRAPPER_MODE}" in
    swtpm) engine_params="-e tpm2tss" ;;
    pkcs11) engine_params="-e pkcs11" ;;
  esac
  if [ "${PLATFORM_SIGN}" = "1" ]; then
    sign_params="-k $signing_key"
  else
    sign_params="-u"
  fi

  ${NETFIELD_BASE}/scripts/deploy/create_firmware_api_file.sh ${engine_params} -a ${image_wic} ${sign_params} -s ${NETFIELD_BASE}/scripts/deploy/_firmware -v
  cd ..
  tmpdir=$(mktemp -d)

  cp ${tmpdir_tmp}/firmware.signed ${tmpdir}/firmware
  rm -rf ${tmpdir_tmp}

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
  image_wic="${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.wic.bz2"
  image_zip="${IMGDEPLOYDIR}/${IMAGE_NAME}.recovery.zip"

  if [ ! -e "${image_wic}" ]; then
    bbfatal "Error creating zip-recovery image! Base image \"${image_wic}\" does not exist."
  fi

  rm -f ${IMGDEPLOYDIR}/*.recovery.zip

  type="recovery"

  export PHYSICAL_SYSTEM_DEVICE="${PHYSICAL_SYSTEM_DEVICE}"
  export DEPLOY_DIR_IMAGE="${DEPLOY_DIR_IMAGE}"
  export FIRMWARE_VERSION="${FULL_FW_VERSION}"

  setup_sign_wrapper_env "${PLATFORM_KEYNAME}"
  local signing_key=$(setup_sign_wrapper_env "${PLATFORM_KEYNAME}")
  case "${SIGN_WRAPPER_MODE}" in
    swtpm) engine_params="-e tpm2tss" ;;
    pkcs11) engine_params="-e pkcs11" ;;
  esac

  if [ "${PLATFORM_SIGN}" = "1" ]; then
    sign_param="-k $signing_key"
  else
    sign_param="-u"
  fi

  ${NETFIELD_BASE}/scripts/deploy/create_dist_archive.sh ${engine_params} \
    -o "${image_zip}" \
    -i ${image_wic} \
    ${sign_param} \
    -c ${BSP_DEPLOYSCRIPT_DIR} -t $type \
    ${HILSCHER_EXTRA_ZIP_OPTIONS}

  ln -sf $(basename ${image_zip}) ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.recovery.zip
}
