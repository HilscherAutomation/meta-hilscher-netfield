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

 -f initrd-api-file
    e.g. firmware.20160331115330

 -k private-key-file
    e.g. : ./key.pem

 -u don't sign image

 -v
    Enable verbose mode.

 -h
    Show this help menu.

Examples:
  ${MYNAME} -f firmware.20160331115330 -k ../../keys/uefi/db.key

EOF
}

#===============================================================================
# Start Main
#===============================================================================

MYNAME=$(basename ${0})
MYVERSION="20160404"
sign_image="1"

# Parse Options
while getopts "f:k:e:vuh" opt ; do
	echo "${OPTARG}" | grep -q "^-.*" && {
		vmsg_errout "option -${opt} requires an argument!"
	}
	case ${opt} in
		f) api_file=$OPTARG;;
		k) priv_key=${OPTARG};;
		e) engine=${OPTARG};;
		u) sign_image="0";;
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

if [ -z "${api_file}" ]; then
	vmsg_errout "Invalid or missing arguments.";
fi

if [ -z "${priv_key}" ] && [ "${sign_image}" = "1" ]; then
	vmsg_errout "Invalid or missing arguments.";
fi

vmsg "Creating (${api_file}.signed)"

if [ -n "${engine}" ]; then
	swtpm_params="-engine ${engine} -keyform engine"
fi

if [ "${sign_image}" = "1" ]; then
	openssl dgst ${swtpm_params} -sha512 -sign "${priv_key}" -out ${api_file}.signature ${api_file}
else
	sha256sum ${api_file} | cut -d' ' -f1 | tr -d '\n' > ${api_file}.signature
fi

echo "== SIGNATURE START ==" > ${api_file}.signed &&
cat ${api_file}.signature >> ${api_file}.signed &&
rm ${api_file}.signature &&
echo "" >> ${api_file}.signed &&
echo "== SIGNATURE END ==" >> ${api_file}.signed &&
echo "== DATA START ==" >> ${api_file}.signed &&
dd if=${api_file} of=${api_file}.signed oflag=append conv=notrunc >/dev/null 2>&1

if [ $? -eq 0 ]; then
	vmsg -ne "\n\e[1;32mDone!\e[0m\n\n" # green
else
	vmsg_errout "Failed";
fi

exit 0
