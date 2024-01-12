DESCRIPTION = "Deploy scripts on host."
HOMEPAGE = "http://www.hilscher.com"
LICENSE = "CLOSED"

inherit hilscher-deploy native

PACKAGE_ARCH = "${MACHINE_ARCH}"

# generic platform specific setup
SRC_URI = "file://deploy-fastboot \
           file://deploy-wic-bz2 \
          "

hd_path = "${HDEPLOY_PATH_EXTRAS}/"

do_hilscher_deploy() {
	install -m 755 ${WORKDIR}/deploy-fastboot "${hd_path}/"
	install -m 755 ${WORKDIR}/deploy-wic-bz2 "${hd_path}/"
}
do_hilscher_deploy[cleandirs] = "${hd_path}/"
addtask hilscher_deploy before do_build after do_install
