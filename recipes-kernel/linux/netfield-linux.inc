#TODO: Currently sstate-caching kernel compile step arises several different errors:
# - do_prepare_recipe_sysroot: The file /usr/lib/x86_64-poky-linux/9.3.0/crtfastmath.o is installed by both libgcc-initial and libgcc, aborting
# - /meta/recipes-kernel/make-mod-scripts/make-mod-scripts_1.0.bb:do_configure failed with exit code '1' : /tmp/work-shared/niot-e-tijcx-gb/kernel-source/Makefile:710: scripts/Makefile.kcov: No such file or directory
# Disable this step until the cause is clear
#include sstate-cache.inc

require fragattack.inc

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

# Make sure ext4 extended attributes are enabled
KERNEL_FEATURES_append += "cfg/fs/ext4.scc cfg/fs/ext3.scc cfg/fs/ext2.scc"

# Security
SRC_URI_append += "${@bb.utils.contains('DISTRO_FEATURES', 'apparmor', 'file://enable_apparmor.cfg', '', d)}"
# meta-security (zeus) adds apparmor.scc which is missing in older kernel-caches
KERNEL_FEATURES_remove += "features/apparmor/apparmor.scc"

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
SRC_URI_append += "file://enable_signed_modules.cfg"
INHIBIT_PACKAGE_STRIP="1"
EXTRA_OEMAKE_append += " INSTALL_MOD_STRIP=1 "
do_kernel_configme_prepend() {
  set -e
  mkdir -p ${B}/certs
  cat ${KEYS_IMAGE_SIGN_PRIV} > ${B}/certs/iotgw_signing_key.pem
  cat ${KEYS_IMAGE_SIGN_CERT} >> ${B}/certs/iotgw_signing_key.pem
}

do_shared_workdir_append() {
  kerneldir=${STAGING_KERNEL_BUILDDIR}
  mkdir -p $kerneldir/certs
  cp ${KEYS_IMAGE_SIGN_PRIV} $kerneldir/certs/iotgw_signing_key.pem
  cp ${KEYS_IMAGE_SIGN_CERT_DER} $kerneldir/certs/signing_key.x509
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
