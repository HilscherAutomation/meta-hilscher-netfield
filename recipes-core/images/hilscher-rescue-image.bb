DESCRIPTION = "Hilscher rescue image."

require recipes-core/images/core-image-minimal.bb

IMAGE_FEATURES += "ssh-server-openssh"

IMAGE_INSTALL += "\
	packagegroup-hilscher-base \
"

#currently just needed for hostname
IMAGE_INSTALL += "initial-machine-setup"

#service patches swupdate environement to run service at port 80
IMAGE_INSTALL += "rescue-service"

IMAGE_INSTALL += "dhcp-client"

#currently for debugging purposes
IMAGE_INSTALL += "sudo"

#login
inherit extrausers
EXTRA_USERS_PARAMS += "groupadd -g 1000 admin;"
EXTRA_USERS_PARAMS += "useradd -c 'System Administrator' -u 1000 -P admin -G sudo -s /bin/sh admin;"

do_create_platform_dir() {
   install -d ${IMAGE_ROOTFS}/var/platform
   install -d ${IMAGE_ROOTFS}/usr/local
}
ROOTFS_POSTUNINSTALL_COMMAND_append += "${@bb.utils.contains('NETIOT_ROOT_OVERLAY', '1', '', 'do_create_platform_dir ; ', d)}"

do_install_manifest() {
   # Real firmware version is provided by meta-hilscher-distro
   ln -s firmware.version ${IMAGE_ROOTFS}/fw_version
}
ROOTFS_POSTUNINSTALL_COMMAND_append += " do_install_manifest ;"
