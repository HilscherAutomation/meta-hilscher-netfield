#!/bin/bash -e

SCRIPTDIR=$(readlink -f ${0})
SCRIPTDIR=$(dirname ${SCRIPTDIR})

if [ -z "${PLATFORMS}" ]; then
    PLATFORMS="meta-intel:niot-e-tijcx-gb,niot-e-vm-en meta-raspberrypi:niot-e-tpi51-en-re meta-freescale:mc:hilscher-netfield-iolink-edge-gw-rev2:netfield-image-oem-all"
    # Dont build netx4000 per default as it is currently unused
    #meta-hilscher-netx4000:nxhx4000-jtag-plus-rev4,nanl-base-4000-re-rev2
fi

# Make sure to share as much as possible between builds
if [ -d "/opt/shared/yocto" ]; then
    export SSTATE_DIR=/opt/shared/yocto/sstate-cache/netiot/2.0
    export DL_DIR=/opt/shared/yocto/downloads
else
    export SSTATE_DIR=$(pwd)/sstate-cache
    export DL_DIR=$(pwd)/downloads
    mkdir -p ${SSTATE_DIR}
    mkdir -p ${DL_DIR}
fi

buildimage="netfield-image"
base_build_folder="build"
version_suffix=""
base_dist_dir="dist"
firmware_version="2.0.0.0"
extra_image_features=""
extra_image_packages=""

usage() {
  echo "Usage: $0 [-i <image>] [-b <build folder>] [-s <version suffix>] [-d <dist dir>] [-f <version>] [-e <extra_img_features>] [-p <extra_img_packages>] [-c] [-t]" 1>&2; exit 1;
}

while getopts ":i:b:s:d:f:e:p:ct" o; do
    case "${o}" in
        t)  # Include test configuration/data
            test="1"
            ;;
        c)  cve_check="1"
            ;;
        p)
            extra_image_packages=${OPTARG}
            ;;
        e)
            extra_image_features=${OPTARG}
            ;;
        f)
            firmware_version=${OPTARG}
            ;;
        i)
            buildimage=${OPTARG}
            ;;
        b)
            base_build_folder=${OPTARG}
            ;;
        s)
            version_suffix=${OPTARG}
            ;;
        d)
            base_dist_dir=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ ! "$base_dist_dir" = /* ]]; then
  # Relative path, convert to absolute path
  base_dist_dir="${PWD}/${base_dist_dir}"
fi

# Provide FIRMWARE_VERSION in environment
export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE FIRMWARE_VERSION HILSCHER_DEPLOY_ROOT_DIR EXTRA_IMAGE_FEATURES EXTRA_IMAGE_PACKAGES SSTATE_DIR DL_DIR"

# Strip leading tags/ from RELEASE_VERSION
export FIRMWARE_VERSION="${firmware_version}${version_suffix}"
export HILSCHER_DEPLOY_ROOT_DIR="${base_dist_dir}"
export EXTRA_IMAGE_FEATURES="${extra_image_features}"
export EXTRA_IMAGE_PACKAGES="${extra_image_packages}"

rm -rf ${base_dist_dir}

for platform in $PLATFORMS; do
	layer=$(echo $platform | cut -d: -f1)
	machines=$(echo $platform | cut -d: -f2- | tr "," " ")

	build_folder=${base_build_folder}_$(echo $layer | sed 's,meta-,,')
	mkdir -p ${build_folder}/conf
	cp $SCRIPTDIR/$layer/* ${build_folder}/conf

	if [ "${cve_check}" = "1" ]; then
		echo 'INHERIT += "cve-check"' >> ${build_folder}/conf/local.conf
	fi

	if [ "${test}" = "1" ]; then
		echo 'include local.test.overrides.conf' >> ${build_folder}/conf/local.conf
	fi

	echo "" >> ${build_folder}/conf/local.conf
	echo "FIRMWARE_VERSION=\"${FIRMWARE_VERSION}\"" >> ${build_folder}/conf/local.conf

	for machine in $machines; do
		source ./poky/oe-init-build-env ${build_folder}
		if echo "$machine" | grep -q "^mc:"; then
			# NOTE:
			# The new machine format (machine="mc:hilscher-netfield-iolink-edge-gw-rev2:netfield-image-oem-hilscher[:nt0001c027d617.local])
			# may contain an optional IP address of a DUT. Therefore the machine name must be
			# split from the address.
			#dut=$(echo $machine: | cut -d: -f4) # This variable is not required in this script!

			mcimage="$(echo $machine | cut -d: -f-3)"
			mcmachine="$(echo $machine | cut -d: -f2)"
			mcdirs="$(find ../meta-* -name multiconfig -type d)"
			mcconf="$(find $mcdirs -name $mcmachine.conf)"
			case $(echo $mcconf | wc -w) in
				0) echo "Error: multiconfig: $mcmachine.conf not found!"; exit 1;;
				1) ;;
				*) echo "Error: multiconfig: Multiple $mcmachine.conf files found!"; exit 1;;
			esac
			image="$(echo $machine | cut -d: -f3)"
			machine="$(grep "MACHINE *=" $mcconf | cut -d\" -f2)"
			tmpdir="$(dirname $(grep "TMPDIR *=" $mcconf | cut -d\" -f2 | cut -d'/' -f2-))/$machine"
			MACHINE="${machine}" bitbake ${mcimage}
		else
			# NOTE:
			# The new machine format (machine="netfield-iolink-edge-gw-rev2[:nt0001c027d617.local])
			# may contain an optional IP address of a DUT. Therefore the machine name must be
			# split from the address.
			#dut=$(echo $machine: | cut -d: -f2) # This variable is not required in this script!
			mcmachine=""
			image="$buildimage"
			machine="$(echo $machine: | cut -d: -f1)"
			MACHINE="${machine}" bitbake ${image}
		fi

		# Delete duplicate sstate cache entries to save space
		# sstate-cache-management.sh -d -y --cache-dir=sstate-cache
		# NOTE: sstate-cache-management does not clean TUNEARCHS automatically, so
		#       call it another time with possible tunearchs
		# sstate-cache-management.sh -d -y --cache-dir=sstate-cache --extra-arch=corei7-64-intel-common,corei7-64,cortexa7t2hf-neon-vfpv4,cortexa9hf-neon,aarch64-mx8mm,aarch64

		if [ "${cve_check}" = "1" ]; then
			if [ -n "$mcmachine" ]; then
				# Dist directory prepends vendor to image name
				vendor=$(echo $mcmachine | cut -d '-' -f1)
				image="$vendor-$image"
				cve_file=$(readlink -f "tmp-oem/machines/$machine/deploy/images/${machine}/netfield-image-oem-${machine}.cve")
			else
				cve_file=$(readlink -f "${tmpdir:=tmp}/deploy/images/${machine}/${image}-${machine}.cve")
			fi

			cp ${cve_file} ${HILSCHER_DEPLOY_ROOT_DIR}/${machine}/${image}/${FIRMWARE_VERSION}/
			ln -sf $(basename ${cve_file}) ${HILSCHER_DEPLOY_ROOT_DIR}/${machine}/${image}/${FIRMWARE_VERSION}/${image}-${machine}.cve

			json_output="$(basename $cve_file).json"
			$SCRIPTDIR/processcves ${cve_file} --machine "${machine}" --format warnings-ng > \
				${HILSCHER_DEPLOY_ROOT_DIR}/${machine}/${image}/${FIRMWARE_VERSION}/${json_output}
			ln -sf ${json_output} ${HILSCHER_DEPLOY_ROOT_DIR}/${machine}/${image}/${FIRMWARE_VERSION}/${image}-${machine}.cve.json
		fi

		cd ..
	done
done
