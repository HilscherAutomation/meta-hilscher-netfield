#!/bin/bash -e

usage() {
cat <<EOF 1>&2
Usage: $0 [OPTION] ..."

  -b <build_dir>              Basename of build directory which will be extended by parts of machine layer. (default: "build")
  -i <image>                  Image name to test (default: "netfield-image", default(mc): "netfield-image-oem")
  -P <machine[0..n]>          Space seperated list of machines/platforms to test

  Examples:
    PLATFORMS="niot-e-tijcx-gb:10.13.4.246 hilscher-netfield-iolink-edge-gw-rev2:10.13.4.248" $0
    $0 -P "niot-e-tijcx-gb:10.13.4.246 hilscher-netfield-iolink-edge-gw-rev2:10.13.4.248"

  Note:
    Each machine declaration must contain an IP address of DUT (e.g."hilscher-netfield-iolink-edge-gw-rev2:10.13.4.248").

EOF
	exit 1
}

while getopts ":i:b:P:" o; do
	case "${o}" in
		b)
			build_dir="${OPTARG}"
			;;
		i)
			image="${OPTARG}"
			;;
		P)
			platforms="${OPTARG}"
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

# Set default values
BUILD_DIR="${build_dir:-"build"}"
IMAGE="${image:-"netfield-image"}"
MCIMAGE="${image:-"netfield-image-oem"}" # oem base-image

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

for machine in $PLATFORMS; do
	# NOTE:
	# The machine format (machine="hilscher-netfield-iolink-edge-gw-rev2[:nt0001c027d617.local])
	# may contain an optional IP address of a DUT. Therefore the machine name must be
	# split from the address.
	dut="$(echo $machine: | cut -d: -f2)"
	machine="$(echo $machine: | cut -d: -f1)"

	[ -z "$dut" ] && continue

	# Search machine/multiconfig configuration
	mconf="$(find meta-hilscher-netfield-*/conf/machine -name $machine.conf)"
	mcconf="$(find meta-hilscher-netfield-*/conf/multiconfig -name $machine.conf)"
	case $(echo $mcconf | wc -w) in
		0|1) ;;
		*) echo "Error: multiconfig: Multiple $mcmachine.conf files found!"; exit 1;;
	esac
	[ -n "$mcconf" ] && mconf="$mcconf"
	[ -z "$mconf" ] && { echo "ERROR: $machine.conf not found! "; exit 1; }

	# Set machine meta layer
	mlayer=${mconf%%/*}

	# Set image name and bitbake target
	target="$IMAGE"
	if echo $mconf | grep -q "conf/multiconfig/"; then
		mcmachine="$machine"
		machine="$(grep "MACHINE *=" $mcconf | cut -d\" -f2)"
		image="$MCIMAGE"
		target="mc:$machine:$image"
	fi

	# Initialize build directory
	build_dir_suffix="_${mlayer##*-}"
	TEMPLATECONF="../$mlayer/conf/samples"
	. poky/oe-init-build-env ${BUILD_DIR}${build_dir_suffix}

	# Remove old entry and append the new one.
	sed -i "/TEST_TARGET_IP_$machine =/d" conf/local.overrides.test.conf
	echo "TEST_TARGET_IP_$machine = \"$dut\"" >> conf/local.overrides.test.conf

	# Test target on DUT
	MACHINE="$machine" bitbake $target -c testimage

	cd ..
done
