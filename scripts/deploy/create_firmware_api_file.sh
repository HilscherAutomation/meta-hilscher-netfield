#!/bin/bash

#===============================================================================
# Help Functions
#===============================================================================
vmsg ()
{
	[ "$verbose" = "1" ] && echo "$@"
  return 0
}

vmsg_errout ()
{
	[ "$verbose" = "1" ] && echo -ne "\n\e[1;31m$@\e[0m\n\n" # red
  exit 1
}

show_help ()
{
	cat <<EOF

Usage: $MYNAME options

 -a firmware-archive-file
    e.g. intel-quark-fs-hilscher-iotgw-standard-dist-srm.tar.bz2

 -k private-key-file
    e.g. : ./key.pem

 -u don't sign image

 -v
    Enable verbose mode.

 -h
    Show this help menu.

Examples:
  ${MYNAME} -a intel-quark-fs-hilscher-iotgw-standard-dist-srm.tar.bz2 -k ../../keys/uefi/db.key

EOF
}

#===============================================================================
# Start Main
#===============================================================================

MYNAME=$(basename ${0})
MYVERSION="20160404"

DATE=`date +%Y%m%d%H%M%S`
SCRIPTDIR=$(dirname "$0")
sign_image="1"

# Parse Options
while getopts "a:k:s:p:e:vuh" opt ; do
	echo "${OPTARG}" | grep -q "^-.*" && {
		echo "option -${opt} requires an argument!"
    exit 1
	}
	case ${opt} in
		a) fw_image=$OPTARG;;
		k) priv_key=${OPTARG};;
		u) sign_image="0";;
		s) user_script_dir=${OPTARG};;
		e) engine=${OPTARG};;
		v) verbose=1;;
		h) show_help && exit 0;;
		?) show_help && exit 1;;
	esac
done

# Show welcome message
vmsg
vmsg "==========================================================="
vmsg " Application: ${MYNAME} (${MYVERSION})"
vmsg "==========================================================="

if [ -z "${priv_key}" ] && [ "${sign_image}" = "1" ]; then
  echo "Invalid or missing arguments."
  exit 1
fi

if [ ! -z "${user_script_dir}" ]; then
  echo "NOTE: Creating custom API image with scripts in $user_script_dir"
else
  if [ -z "${fw_image}" ]; then
    echo "Invalid or missing arguments."
    exit 1
  fi
fi

vmsg "Creating a initrd_api file (firmware.signed)"

#
vmsg -n "- Prepare the initrd_api directory (_firmware_api) ... "
rm -rf _firmware_api
mkdir -p _firmware_api/firmware
[ $? -eq 0 ] && vmsg "done" || vmsg_errout "failed!"

#
vmsg -n "- Add the firmware archiv and create a timestamp file ... "
echo ${DATE} > _firmware_api/firmware/timestamp &&
if [ -e "${fw_image}" ]; then
  mkdir -p _firmware_api/firmware
  if [ -d "${fw_image}" ]; then
    cp -r ${fw_image}/* _firmware_api/firmware
  else
    cp ${fw_image} _firmware_api/firmware

    if [ -n "${engine}" ]; then
      engine_param="-engine ${engine} -keyform engine"
    fi
    if [ "${sign_image}" = "1" ]; then
      openssl dgst $engine_param -sha512 -sign "${priv_key}" -out _firmware_api/firmware/$(basename $fw_image).sig ${fw_image}
    else
      sha256sum ${fw_image} | cut -d' ' -f1 | tr -d '\n' > _firmware_api/firmware/$(basename $fw_image).sig
    fi
  fi
fi
[ $? -eq 0 ] && vmsg "done" || vmsg_errout "failed!"

#
vmsg -n "- Add specific contents (e.g. runscript_1.sh) ... "

echo $FIRMWARE_VERSION > _firmware_api/firmware.version
if [ ! -z "${user_script_dir}" ]; then
  cp ${user_script_dir}/* _firmware_api
else
  cp ${SCRIPTDIR}/_firmware/* _firmware_api
fi
[ $? -eq 0 ] && vmsg "done" || vmsg_errout "failed!"

[ -z "${PHYSICAL_SYSTEM_DEVICE}" ] && PHYSICAL_SYSTEM_DEVICE="/dev/mmcblk0 /dev/sda"
sed -i -e "s;@PHYSICAL_SYSTEM_DEVICE@;${PHYSICAL_SYSTEM_DEVICE};g" _firmware_api/runscript.sh

deployscript=${SCRIPTDIR}/deploy.sh

vmsg -n "- Add the deploy script and replace the shell ... "
cp "${deployscript}" _firmware_api/deploy.sh &&
sed -i 's/bash/sh/' _firmware_api/deploy.sh
[ $? -eq 0 ] && vmsg "done" || vmsg_errout "failed!"

#mark as executable since initrd_api will check this
chmod 775 _firmware_api/*.sh

#
[ -n "${engine}" ] && engine_param="-e $engine"
vmsg -n "- Create an initrd_api file and sign it (firmware.${DATE}.signed) ... "
tar czfC firmware.${DATE} _firmware_api ./ &&
if [ "${sign_image}" = "1" ]; then
  sign_params="-k ${priv_key} $engine_param"
else
  sign_params="-u"
fi
${SCRIPTDIR}/sign_api_file.sh -f firmware.${DATE} ${sign_params}
[ $? -eq 0 ] && vmsg "done" || vmsg_errout "failed!"

#
vmsg -n "- Remove the unsigned initrd_api file and create a link for simple use ... "
rm firmware.${DATE} &&
ln -sf firmware.${DATE}.signed firmware.signed
[ $? -eq 0 ] && vmsg "done" || vmsg_errout "failed!"

#
if [ $? -eq 0 ]; then
	vmsg -ne "\n\e[1;32mDone!\e[0m\n\n" # green
else
	vmsg_errout "Failed";
fi

exit 0

