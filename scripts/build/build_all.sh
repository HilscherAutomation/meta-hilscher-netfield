#!/bin/bash -e

usage() {
cat <<EOF 1>&2
Usage: $0 [OPTION] ..."

By default, a default image will be build for a predefined list of machines(platforms).

  -b <build_dir>              Basename of build directory which will be extended by parts of machine layer. (default: "build")
  -c                          Enable CVE check
  -d <deploy_dir>             Deploy directory (default: "dist")
  -D                          Build a debug image
  -e <extra_image_features>   Add extra image features
  -f <fw_version>             Firmware version (default: "2.3.0.0")
  -i <image>                  Image name to build (default: "netfield-image", default(mc): "netfield-image-oem-all")
  -p <extra_image_packages>   Add extra image packages
  -P <machine[0..n]>          Space seperated list of machines/platforms to build
  -s <fw_suffix>              Suffix used for firmware version
  -t                          Enable testability

  Examples:
    PLATFORMS="niot-e-tijcx-gb hilscher-netfield-iolink-edge-gw-rev2" $0 -t -D
    $0 -t -D -P "niot-e-tijcx-gb hilscher-netfield-iolink-edge-gw-rev2"

  Note:
    Each machine declaration may optionally contain an IP address of DUT (e.g."hilscher-netfield-iolink-edge-gw-rev2:10.13.4.248").
    These addresses will be ignored by build process.

EOF
	exit 1
}

while getopts ":b:cd:De:f:i:p:P:s:t" o; do
	case "${o}" in
		b)
			build_dir="${OPTARG}"
			;;
		c)  cve_check_enabled="1"
			;;
		d)
			deploy_dir="${OPTARG}"
			;;
		D)
			debug_enable="1"
			;;
		e)
			extra_image_features="${OPTARG}"
			;;
		f)
			fw_version="${OPTARG}"
			;;
		i)
			image="${OPTARG}"
			;;
		p)
			extra_image_packages="${OPTARG}"
			;;
		P)
			platforms="${OPTARG}"
			;;
		s)
			fw_suffix="${OPTARG}"
			;;
		t)  # Include test configuration/data
			test_enabled="1"
			# Debug features are required for testing (root shell without password).
			debug_enable="1"
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

# Set default values
FW_VERSION="${fw_version:-"2.3.0.0"}"
FW_VERSION="$FW_VERSION${debug_enable:+".debug"}"
FW_VERSION="$FW_VERSION${fw_suffix:+".$fw_suffix"}"
BUILD_DIR="${build_dir:-"build"}"
DEPLOY_DIR="${deploy_dir:-"dist"}"
IMAGE="${image:-"netfield-image"}"
MCIMAGE="${image:-"netfield-image-oem-all"}"
EXTRA_IMAGE_FEATURES="${debug_enable:+"empty-root-password allow-empty-password debug-tweaks"}"
EXTRA_IMAGE_FEATURES="$EXTRA_IMAGE_FEATURES${extra_image_features:+" $extra_image_features"}"
EXTRA_IMAGE_PACKAGES="$EXTRA_IMAGE_PACKAGES${extra_image_packages:+" $extra_image_packages"}"


# Use PLATFORMS from command argument (preferred) or from environment variable.
PLATFORMS="${platforms:-$PLATFORMS}"
# If not set, use this default PLATFORMS for machines to be built.
if [ -z "${PLATFORMS}" ]; then
	# Default machines to build: Intel
	PLATFORMS="$PLATFORMS niot-e-tijcx-gb niot-e-vm-en"
	# Default machines to build: Raspberry
	PLATFORMS="$PLATFORMS niot-e-tpi51-en-re"
	# Default machines to build: imx8
	PLATFORMS="$PLATFORMS hilscher-netfield-iolink-edge-gw-rev2"
fi

# Make sure to share as much as possible between builds
SSTATE_DIR=$(pwd)/sstate-cache
DL_DIR=$(pwd)/downloads
if [ -d "/opt/shared/yocto" ]; then
	distro_version=$(grep "DISTRO_VERSION" meta-hilscher-netfield/conf/distro/netiot.conf | cut -d '=' -f2 | tr -d '" ')
	SSTATE_DIR=/opt/shared/yocto/sstate-cache/netiot/${distro_version}
	DL_DIR=/opt/shared/yocto/downloads
fi

SCRIPTDIR=$(readlink -f ${0})
SCRIPTDIR=$(dirname ${SCRIPTDIR})

# Relative path, convert to absolute path
[[ ! "$DEPLOY_DIR" = /* ]] && DEPLOY_DIR="${PWD}/$DEPLOY_DIR"
rm -rf $DEPLOY_DIR

for machine in $PLATFORMS; do
	# NOTE:
	# The machine format (machine="hilscher-netfield-iolink-edge-gw-rev2[:nt0001c027d617.local])
	# may contain an optional IP address of a DUT. Therefore the machine name must be
	# split from the address.
	dut="$(echo $machine: | cut -d: -f2)" # This variable is not required in this script!
	machine="$(echo $machine: | cut -d: -f1)"

	# Search machine/multiconfig configuration
	mconf="$(find meta-hilscher-netfield-*/conf/machine -name $machine.conf)"
	mcconf="$(find meta-hilscher-netfield-*/conf/multiconfig -name $machine.conf)"
	case $(echo $mcconf | wc -w) in
		0|1) ;;
		*) echo "Error: multiconfig: Multiple $mcmachine.conf files found!"; exit 1;;
	esac
	[ -z "$mconf" ] && mconf="$mcconf"
	[ -z "$mconf" ] && { echo "ERROR: $machine.conf not found! "; exit 1; }

	# Set machine meta layer
	mlayer=${mconf%%/*}

	# Set image name and bitbake target
	target="$IMAGE"
	if echo $mconf | grep -q "conf/multiconfig/"; then
		mcmachine="$machine"
		machine="$(grep "MACHINE *=" $mcconf | cut -d\" -f2)"
		image="$MCIMAGE"
		target="mc:$mcmachine:$image"
	fi

	# Initialize build directory
	build_dir_suffix="_${mlayer##*-}"
	TEMPLATECONF="../$mlayer/conf/samples"
	. poky/oe-init-build-env ${BUILD_DIR}${build_dir_suffix}

	# Complete build directory
	for f in $(find $(cat conf/templateconf.cfg) -name *.sample$!); do
		[ $(basename $f) == "bblayers.conf.sample" ] && continue # already done by poky/oe-init-build-env
		[ $(basename $f) == "local.conf.sample" ] && continue # already done by poky/oe-init-build-env
		[ -e conf/$(basename ${f%.*}) ] && diff -ua $f conf/$(basename ${f%.*}) || cp -i $f conf/$(basename ${f%.*})
	done
	if [ -e ../site.conf ]; then
		[ -e conf/site.conf ] && diff -ua ../site.conf conf/site.conf || cp -i ../site.conf conf/site.conf
	fi

	# Set build parameters
	if touch conf/local.overrides.conf; then
		# Remove old entry and append the new one
		sed -i "/FIRMWARE_VERSION = /,2d" conf/local.overrides.conf
		echo -e "FIRMWARE_VERSION = \"${FW_VERSION}\"\n" >> conf/local.overrides.conf

		# Remove old entries and append the new ones
		sed -i "/EXTRA_IMAGE_FEATURES = /,3d" conf/local.overrides.conf
		echo -e "EXTRA_IMAGE_FEATURES = \"$EXTRA_IMAGE_FEATURES\"" >> conf/local.overrides.conf
		echo -e "EXTRA_IMAGE_PACKAGES = \"$EXTRA_IMAGE_PACKAGES\"\n" >> conf/local.overrides.conf

		# Remove old entry and append the new one
		sed -i '/INHERIT += "cve-check"/,2d' conf/local.overrides.conf
		[ "${cve_check_enabled}" = "1" ] && echo -e "INHERIT += \"cve-check\"\n" >> conf/local.overrides.conf

		# Remove old entry and append the new one
		sed -i "/HILSCHER_DEPLOY_ROOT_DIR = /,2d" conf/local.overrides.conf
		echo -e "HILSCHER_DEPLOY_ROOT_DIR = \"$DEPLOY_DIR\"\n" >> conf/local.overrides.conf

		# Remove old entries and append the new ones
		sed -i "/DL_DIR ?= /,3d" conf/local.overrides.conf
		echo -e "DL_DIR ?= \"$DL_DIR\"" >> conf/local.overrides.conf
		echo -e "SSTATE_DIR ?= \"$SSTATE_DIR\"\n" >> conf/local.overrides.conf

		# Remove old entry and append the new one
		sed -i "/include local.overrides.test.conf/,2d" conf/local.overrides.conf
		[ "$test_enabled" = "1" ] && echo -e "include local.overrides.test.conf\n" >> conf/local.overrides.conf
	fi

	# Build target
	MACHINE="$machine" bitbake $target

	# Delete duplicate sstate cache entries to save space
	# sstate-cache-management.sh -d -y --cache-dir=sstate-cache
	# NOTE: sstate-cache-management does not clean TUNEARCHS automatically, so
	#       call it another time with possible tunearchs
	# sstate-cache-management.sh -d -y --cache-dir=sstate-cache --extra-arch=corei7-64-intel-common,corei7-64,cortexa7t2hf-neon-vfpv4,cortexa9hf-neon,aarch64-mx8mm,aarch64

	# Run CVE check
	if [ "$cve_check_enabled" = "1" ]; then
		if [ -n "$mcmachine" ]; then
			# Dist directory prepends vendor to IMAGE name
			vendor=$(echo $mcmachine | cut -d '-' -f1)
			image="$vendor-$image"
			cve_file=$(readlink -f "tmp-oem/machines/$machine/deploy/images/$machine/netfield-image-oem-$machine.cve")
		else
			cve_file=$(readlink -f "${tmpdir:=tmp}/deploy/images/$machine/$image-$machine.cve")
		fi

		cp $cve_file $DEPLOY_DIR/$machine/$image/$FW_VERSION/
		ln -sf $(basename $cve_file) $DEPLOY_DIR/$machine/$image/$FW_VERSION/$image-$machine.cve

		json_output="$(basename $cve_file).json"
		$SCRIPTDIR/processcves $cve_file --machine "$machine" --format warnings-ng > \
			$DEPLOY_DIR/$machine/$image/$FW_VERSION/$json_output
		ln -sf $json_output $DEPLOY_DIR/$machine/$image/$FW_VERSION/$image-$machine.cve.json
	fi

	cd ..
done
