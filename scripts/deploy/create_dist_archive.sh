#!/bin/bash

MYNAME=$(basename ${0})
SCRIPTDIR=$(dirname ${0})
SCRIPTDIR=$(readlink -f ${SCRIPTDIR})
MYVERSION="20161108"

function usage() {
  echo "${MYNAME} [options]"
  echo ""
  echo "-o --out <img.tar.bz2>   Output tarball name (supported extensions: tar, tar.gz, tgz, tar.bz2, zip)"
  echo "-i --image <imgname>     Input image name (default: hilscher-iotgw-image)"
  echo "-k --keys <key>          Signing key (default: db.key)"
  echo "-c --custom_scripts      path to user defined scripts (create_boot_part)"
  echo "-t --image_type          Valid types are 'production', 'production_scan', 'recovery' and 'update'"
}

# Show welcome message
echo
echo "==========================================================="
echo " Application: ${MYNAME} (${MYVERSION})"
echo "==========================================================="

# Default values
signing_key="db.key"
input_image="hilscher-iotgw-image"
debug=0

while [ "$1" != "" ]; do
    case $1 in
        -o | --out )            shift
                                output_image=$1
                                ;;
        -i | --image )          shift
                                input_image=$1
                                ;;
        -k | --keys )           shift
                                signing_key=$1
                                ;;
        -c | --custom-scripts ) shift
                                custom_scripts=$1
                                ;;
        -t | --image-type )     shift
                                image_type=$1
                                ;;
        -v | --verbose )        debug="1"
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [ -z "$output_image" ]; then
    echo "Missing output image file name. Please provide -o <img>"
    exit 1
fi

if [ -z "$input_image" ]; then
    echo "Missing input image file name. Please provide -i <img>"
    exit 1
fi

if [ -z "$signing_key" ]; then
    echo "Missing signing key. Please provide -k <key>"
    exit 1
fi

if [ -z "$custom_scripts" ]; then
   echo "Missing scripts directory. Please provide -c <dir>"
   exit 1
fi

input_image=`realpath ${input_image}`
signing_key=`realpath ${signing_key}`

[ ! -e "$input_image" ] && echo "Input image ${input_image} cannot be found" && exit 1
[ ! -e "$signing_key" ] && echo "Signing key ${signing_key} cannot be found" && exit 1

if [ -z "$image_type" ]; then
    echo "Missing image type. Please provide -t <type>"
    exit 1
fi

echo "Creation settings: "
echo " Output                     : ${output_image}"
echo " Input                      : ${input_image}"
echo " Key                        : ${signing_key}"
if [ x${custom_scripts} != "x" ]; then
  custom_scripts=$(readlink -f ${custom_scripts})
  echo " Target specific script dir : ${custom_scripts}"
fi

cwd="$(pwd)"

tmpdir=`mktemp -d --tmpdir=${PWD}`

pushd ${tmpdir}

add_image_params="-a ${input_image}"
if [ "${image_type}" == "production" ] ; then
  user_script_arg="-s ${SCRIPTDIR}/_production"
elif [ "${image_type}" == "production_scan" ] ; then
  user_script_arg="-s ${SCRIPTDIR}/_production_scan"
  # Don't add recovery image
  add_image_params=""
elif [ "${image_type}" == "recovery"  ] ; then
  user_script_arg="-s ${SCRIPTDIR}/_firmware"
elif [ "${image_type}" == "update" ] ; then
  user_script_arg="-s ${SCRIPTDIR}/_update"
fi

firmware_api_file="${SCRIPTDIR}/create_firmware_api_file.sh"
${firmware_api_file} ${add_image_params} -k ${signing_key} ${user_script_arg} ${update_param} -v || exit 1
rm -rf _firmware_api tmp_repo
if [ -e "firmware.signed" ]; then
  realfirmware=$(basename $(readlink firmware.signed))
  rm firmware.signed
  mv ${realfirmware} firmware
fi

prepare_boot_part="${custom_scripts}/prepare_boot_partition.sh"
source ${prepare_boot_part} ${prepare_boot_part}

popd

# create archive for placing on USB stick
echo "Creating archive ${output_image}"

# Create different archive types depending on given extension
case "$output_image" in
  *.tar.gz | *.tgz ) 
    # Create tarball
    tar czf ${output_image} -C ${tmpdir} .
    ;;
  *.tar.bz2 ) 
    # Create bzipped tar archive
    tar cjf ${output_image} -C ${tmpdir} .
    ;;
  *.zip )
    [ -e "$output_image" ] && rm $output_image
    pushd $tmpdir > /dev/null
    zip ${output_image} -r *
    popd > /dev/null
    ;;
  *.tar )
    # Create uncompressed tar archive
    tar cf ${output_image} -C ${tmpdir} .
    ;;
  * )
    # Create uncompressed tar archive
    tar cf ${output_image}.tar -C ${tmpdir} .
    ;;
esac

echo "Removing temporary files"
rm -rf ${tmpdir}

echo "Done"
