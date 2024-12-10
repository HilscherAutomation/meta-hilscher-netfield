SUMMARY = "Hilscher: netfield OEM base image."

require recipes-core/images/netfield-image.bb
require oem-base.inc

# NOTE: Used by cockpit for cloud connecting.
VENDOR_VARIANT_ID=""

IMAGE_INSTALL:append = " swupdate-oem upnpd-conf-oem"

inherit hilscher-deploy

# skip sstate creation since image size will blow up sstate very fast
SSTATE_SKIP_CREATION = "1"

hd_path = "${HDEPLOY_PATH_EXTRAS}/base_image"

do_hilscher_deploy() {
	for file in $(find ${IMGDEPLOYDIR} -type l -name "*.squashfs"); do
		cp -a $(readlink -f $file) ${hd_path}
		[ -e "${file}.sig" ] && cp -a $(readlink -f ${file}.sig) ${hd_path}/
	done
}
do_hilscher_deploy[cleandirs] = "${hd_path}/"
addtask hilscher_deploy before do_build after do_image_complete
