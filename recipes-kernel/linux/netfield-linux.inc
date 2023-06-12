#include sstate-cache.inc

inherit sign-wrapper

DEPENDS += " u-boot-tools-native "

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# 3G
SRC_URI_append += "${@bb.utils.contains('MACHINE_FEATURES', '3g', 'file://3g.scc', '', d)}"
KERNEL_MODULE_AUTOLOAD_append += "${@bb.utils.contains('MACHINE_FEATURES', '3g', 'usbserial usb_wwan option qmi_wwan cdc_mbim cdc-wdm', '', d)}"

# rfkill
SRC_URI_append += "${@bb.utils.contains_any('MACHINE_FEATURES', ['3g', 'wifi'], 'file://rfkill.cfg', '', d)}"

# tun/tap (cifx0 ethernet i/f)
KERNEL_MODULE_AUTOLOAD_append += "tun"

# docker
SRC_URI_append += "file://docker.cfg"
# docker cgroup v2 support requires BPF_SYSCALL
KERNEL_FEATURES_append += "features/bpf/bpf.scc"

# Make sure ext4 extended attributes are enabled
KERNEL_FEATURES_append += "cfg/fs/ext4.scc cfg/fs/ext3.scc cfg/fs/ext2.scc"

# Security
SRC_URI_append += "${@bb.utils.contains('DISTRO_FEATURES', 'apparmor', 'file://enable_apparmor.cfg', '', d)}"
# meta-security (zeus) adds apparmor.scc which is missing in older kernel-caches
KERNEL_FEATURES_remove += "features/apparmor/apparmor.scc"

# Enable HIDRAW on customer request who is using a codesys dongle
SRC_URI_append += "file://enable_hidraw.cfg"

# Enable ZRAM to be used as swap
SRC_URI_append += "file://enable_zram.cfg"

# Enable cpu/memore pressure info to be used by user-space OOM killers
SRC_URI_append += "file://enable_pressure_info.cfg"

SRC_URI_append += "file://kernel_hardening.cfg \
                   file://netfilter_addon.cfg  \
                   file://nftables_addon.cfg"
KERNEL_FEATURES_append += "features/netfilter/netfilter.scc features/nf_tables/nf_tables.scc features/seccomp/seccomp.scc"
# libelf is required for CONFIG_STACK_VALIDATION=y
DEPENDS += "elfutils elfutils-native"

# NFS Server/Client support (base.scc contains nfs client stuff)
KERNEL_FEATURES_append += "features/nfsd/nfsd-enable.scc ktypes/base/base.scc"

# TPM
KERNEL_FEATURES_append += "${@bb.utils.contains_any('MACHINE_FEATURES', ['tpm','tpm2'], 'features/tpm/tpm.scc', '', d)}"
SRC_URI_append += "${@bb.utils.contains('MACHINE_FEATURES', 'tpm2', 'file://enable_tpm2_spi.cfg', '', d)}"

# Profiling
KERNEL_FEATURES_append += "features/lttng/lttng.scc cfg/tracing.scc"

# Task/IO Statistics
KERNEL_FEATURES_append += "features/taskstats/taskstats.scc"

# MTD support to avoid swupdate warning
KERNEL_FEATURES_append += "features/mtd/mtd.scc"

# btrfs
KERNEL_FEATURES_append += "cfg/fs/btrfs.scc"

# device mapper (LVM) support
SRC_URI_append += "file://enable_devmapper.cfg"

# iscsi support
SRC_URI_append += "file://enable_iscsi.cfg"

# Kernel module signing
SRC_URI_append += "${@bb.utils.contains('PLATFORM_SIGN', '1', 'file://enable_signed_modules.cfg', '', d)}"
SRC_URI_append += "${@bb.utils.contains('PLATFORM_SIGN', '1', 'file://0001-Add-support-for-module-signing-via-keyengine.patch', '', d)}"

INHIBIT_PACKAGE_STRIP="1"
EXTRA_OEMAKE_append += " INSTALL_MOD_STRIP=1 "
do_kernel_configme_append() {
	if [ "${PLATFORM_SIGN}" = "1" ]; then
		setup_sign_wrapper_env ${PLATFORM_KEYNAME}

		mkdir -p ${B}/certs
		if [ "${SIGN_WRAPPER_MODE}" = "file" ]; then
			cat ${PLATFORM_KEYDIR}/${PLATFORM_KEYNAME}.key > ${B}/certs/iotgw_signing_key.pem
			cat ${KEYS_IMAGE_SIGN_CERT} >> ${B}/certs/iotgw_signing_key.pem
		fi

		sign_wrapper_copy_certificate "${B}/certs/signing_key.x509"
	fi
}
do_kernel_configme[vardeps] += "PLATFORM_SIGN PLATFORM_KEYDIR PLATFORM_KEYNAME"

do_compile_prepend() {
	if [ "${PLATFORM_SIGN}" = "1" ]; then
		local signing_key=$(setup_sign_wrapper_env ${PLATFORM_KEYNAME})

		case "${SIGN_WRAPPER_MODE}" in
		file)
			sed -i 's/CONFIG_MODULE_SIG_KEY=.*/CONFIG_MODULE_SIG_KEY="certs\/iotgw_signing_key.pem"/g' ${B}/.config
			sed -i 's/CONFIG_MODULE_SIG_ENGINE=.*/CONFIG_MODULE_SIG_ENGINE=""/g' ${B}/.config
		;;
		pkcs11)
			#'"${PLATFORM_KEYNAME}"'
			sed -i 's@CONFIG_MODULE_SIG_KEY=.*@CONFIG_MODULE_SIG_KEY="'"$signing_key"'"@g' ${B}/.config
			sed -i 's@CONFIG_MODULE_SIG_ENGINE=.*@CONFIG_MODULE_SIG_ENGINE="pkcs11"@g' ${B}/.config
		;;
		esac
	fi
}

do_shared_workdir_append() {
	if [ "${PLATFORM_SIGN}" = "1" ]; then
		setup_sign_wrapper_env ${PLATFORM_KEYNAME}

		if [ "${SIGN_WRAPPER_MODE}" = "file" ]; then
			kerneldir=${STAGING_KERNEL_BUILDDIR}
			mkdir -p $kerneldir/certs
			cp ${KEYS_IMAGE_SIGN_PRIV} $kerneldir/certs/iotgw_signing_key.pem
		fi

		sign_wrapper_copy_certificate "$kerneldir/certs/signing_key.x509"
	fi
}

# Misc
SRC_URI_append += "file://enable_overlayfs.cfg \
                   file://enable_squashfs.cfg \
                   file://systemd_acls.cfg"

# led class and pattern support
SRC_URI_append += "file://led.cfg"

# Following CVEs are unspecific or false-positives (e.g. from RedHat 7.0 which is always higher than real kernel version) so whitelist them
CVE_CHECK_WHITELIST_append += "CVE-2007-2764 CVE-2014-2648 CVE-2016-0774 CVE-2016-3699"

# CVE-2017-1000377 is pax only, which is not available anyway
CVE_CHECK_WHITELIST_append += "CVE-2017-1000377"

# CVE-2017-1000255 is powerpc only and already fixed upstream
CVE_CHECK_WHITELIST_append += "CVE-2017-1000255"

# We don't use aufs (it's not even in mainline kernels)
CVE_CHECK_WHITELIST_append += "CVE-2015-7312 CVE-2016-2853 CVE-2016-2854"

# CVE-2017-5897 is fixed since 4.10 (we are using 4.14+)
CVE_CHECK_WHITELIST_append += "CVE-2017-5897"

kernel_sign_wrapper_init() {
	setup_sign_wrapper_env "${PLATFORM_KEYNAME}"
	sign_key=$(setup_sign_wrapper_env "${PLATFORM_KEYNAME}")

	case ${SIGN_WRAPPER_MODE} in
		file)   export UBOOT_MKIMAGE_PARAMS="-k ${UBOOT_SIGN_KEYDIR}"
			;;
		pkcs11) #u-boot mkimage expects URL without leading pkcs11:
			sign_key=$(echo $sign_key | sed -e 's/^pkcs11://')
			export UBOOT_MKIMAGE_PARAMS="-k ${sign_key} -N pkcs11"
			;;
	esac
}

do_assemble_fitimage_prepend() {
	kernel_sign_wrapper_init
}

do_assemble_fitimage_initramfs_prepend() {
	kernel_sign_wrapper_init
}

# verify if fitimage is correctly signed, use public key located in device tree
do_assemble_fitimage_append() {
	if [ "${PLATFORM_SIGN}" = "1" ]; then
		echo "Check signature of fitimage..."
		if [ -n "${EXTERNAL_KERNEL_DEVICETREE}" ]; then
			pubkey_dtb=$(ls -1 ${EXTERNAL_KERNEL_DEVICETREE}/*.dtb)
		else
			pubkey_dtb=$(ls -1 ${DEPLOY_DIR_IMAGE}/devicetree/*.dtb)
		fi
		fit_check_sign -f "${B}/arch/${ARCH}/boot/fitImage" -k "$pubkey_dtb"
	fi
}

do_assemble_fitimage_initramfs_append() {
	if [ "${PLATFORM_SIGN}" = "1" ]; then
		echo "Check signature of fitimage-initramfs..."
		if [ -n "${EXTERNAL_KERNEL_DEVICETREE}" ]; then
			pubkey_dtb=$(ls -1 ${EXTERNAL_KERNEL_DEVICETREE}/*.dtb)
		else
			pubkey_dtb=$(ls -1 ${DEPLOY_DIR_IMAGE}/devicetree/*.dtb)
		fi
		fit_check_sign -f "${B}/arch/${ARCH}/boot/fitImage-core-image-minimal-initramfs" -k "$pubkey_dtb"
	fi
}

do_shared_workdir_prepend() {
	setup_sign_wrapper_env "${PLATFORM_KEYNAME}"
}

inherit hilscher-deploy

hd_path = "${HDEPLOY_PATH_EXTRAS}/kernel"

do_hilscher_deploy() {
	kernel=$(find ${DEPLOYDIR} -type l -name "fitImage-core-image-minimal-initramfs-${MACHINE}-${MACHINE}*")
	cp -a $(readlink -f $kernel) "${hd_path}/"
}
do_hilscher_deploy[cleandirs] = "${hd_path}/"
addtask hilscher_deploy before do_build after do_deploy
