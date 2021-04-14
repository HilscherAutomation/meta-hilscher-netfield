#!/bin/bash -e

if [ -z "${PLATFORMS}" ]; then
    PLATFORMS="meta-intel:niot-e-tijcx-gb,niot-e-vm-en meta-raspberrypi:niot-e-tpi51-en-re meta-freescale:niot-e-nfl90-q2n16-n-rev1:nt0001c0269cac.local,netfield-iolink-edge-gw-rev2:nt0001c027d617.local"
    # Dont build netx4000 per default as it is currently unused
    #meta-hilscher-netx4000:nxhx4000-jtag-plus-rev4,nanl-base-4000-re-rev2
fi

usage() {
  echo "Usage: $0 [-i <image>] [-b <build folder>]" 1>&2; exit 1;
}

image="netfield-image"
base_build_folder="build"

while getopts ":i:b" o; do
    case "${o}" in
        i)
            image=${OPTARG}
            ;;
        b)
            base_build_folder=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

for platform in $PLATFORMS; do
	layer=$(echo $platform | cut -d: -f1)
	machines=$(echo $platform | cut -d: -f2- | tr "," " ")

	build_folder=${base_build_folder}_$(echo $layer | sed 's,meta-,,')

	for machine in $machines; do
		if echo "$machine" | grep -q "^mc:"; then
			# NOTE:
			# The new machine format (machine="mc:hilscher-netfield-iolink-edge-gw-rev2:netfield-image-oem-hilscher[:nt0001c027d617.local])
			# may contain an optional IP address of a DUT. Therefore the machine name must be
			# split from the address.
			dut="$(echo $machine: | cut -d: -f4)"
			[ -z "$dut" ] && continue

			#mcimage=$(echo $machine | cut -d: -f-3) # This variable is not required in this script!
			mcmachine="$(echo $machine | cut -d: -f2)"
			mcdirs="$(find ./meta-* -name multiconfig -type d)"

			mcconf="$(find $mcdirs -name $mcmachine.conf)"
			case $(echo $mcconf | wc -w) in
				0) echo "Error: multiconfig: $mcmachine.conf not found!"; exit 1;;
				1) ;;
				*) echo "Error: multiconfig: Multiple $mcmachine.conf files found!"; exit 1;;
			esac
			image="$(echo $machine | cut -d: -f3 | sed 's,\(^.*oem\).*,\1,')" # oem base-image
			machine="$(grep "MACHINE *=" $mcconf | cut -d\" -f2)"

			# Remove old entry and append the new one.
			sed -i "/TEST_TARGET_IP_$machine =/d" ${build_folder}/conf/local.test.overrides.conf
			echo "TEST_TARGET_IP_$machine = \"$dut\"" >> ${build_folder}/conf/local.test.overrides.conf

			source ./poky/oe-init-build-env ${build_folder}
			# Note: Test the base oem-image.
			MACHINE="${machine}" bitbake mc:${machine}:${image} -c testimage
			cd ..
		else
			dut=$(echo $machine: | cut -d: -f2)
			[ -z "$dut" ] && continue

			machine="$(echo $machine: | cut -d: -f1)"

			# Remove old entry and append the new one.
			sed -i "/TEST_TARGET_IP_$machine =/d" ${build_folder}/conf/local.test.overrides.conf
			echo "TEST_TARGET_IP_$machine = \"$dut\"" >> ${build_folder}/conf/local.test.overrides.conf

			source ./poky/oe-init-build-env ${build_folder}
			MACHINE="${machine}" bitbake ${image} -c testimage
			cd ..
		fi
	done
done
