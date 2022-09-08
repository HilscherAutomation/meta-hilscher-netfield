inherit hilscher-images

FIRMWARE_VERSION ??= "0.0.0.0.testing"
PV="${FIRMWARE_VERSION}"

IMAGE_FEATURES += "ssh-server-openssh"
IMAGE_INSTALL  += "openssh-sftp-server"

#################
# Base system
#################

# Include service that unmounts overlays correctly on shutdown
IMAGE_INSTALL += "${@('unmount-overlays' if d.getVar('NETIOT_OVERLAY_DIRS')!='' else '')}"

# Include /etc/os-release in images
IMAGE_INSTALL += "os-release"

# Log rotation
IMAGE_INSTALL += "logrotate"

# Include syslog push daemon
IMAGE_INSTALL += "systemd-netlogd"

# Include zsh, which has superior features compare to bash3 (GPLv2)
IMAGE_INSTALL += "zsh docker-ce-cli-zsh-completion systemd-zsh-completion"

# AppArmor
IMAGE_INSTALL += "${@bb.utils.contains('DISTRO_FEATURES', 'apparmor', 'apparmor', '', d)}"

# Auditing
IMAGE_INSTALL += "auditd"

# Swap on ZRAM
IMAGE_INSTALL += "zram"

# Install OOM monitor, as kernel OOM might be too late
IMAGE_INSTALL += "earlyoom"

# TPM
IMAGE_INSTALL += "${@bb.utils.contains('MACHINE_FEATURES', 'tpm', 'tpm-tools trousers', '', d)}"
IMAGE_INSTALL += "packagegroup-security-tpm2 swtpm"

# zeroconf, netbios and upnp support
IMAGE_INSTALL += "avahi-daemon nbnsd"
IMAGE_INSTALL += "upnpd libupnp"

IMAGE_INSTALL += "kernel-modules"

# Timezones
IMAGE_INSTALL += "tzdata tzdata-misc tzdata-africa \
    tzdata-americas tzdata-antarctica tzdata-arctic tzdata-asia \
    tzdata-atlantic tzdata-australia tzdata-europe tzdata-pacific"

IMAGE_INSTALL += "nginx"
IMAGE_INSTALL += "ntp"
IMAGE_INSTALL += "hostapd iw wpa-supplicant crda bluez5"
IMAGE_INSTALL += "networkmanager networkmanager-openvpn"
IMAGE_INSTALL += "dosfstools e2fsprogs e2fsprogs-resize2fs btrfs-tools lvm2 iscsi-initiator-utils nfs-utils-client"
IMAGE_INSTALL += "fsarchiver fsarchiver-helpers"
IMAGE_INSTALL += "initial-machine-setup"

# 3G
IMAGE_INSTALL += "${@bb.utils.contains('MACHINE_FEATURES', '3g', 'modemmanager mobile-broadband-provider-info', '', d)}"

# CAN (busybox ip cannot setup CAN interface)
IMAGE_INSTALL += "iproute2"

# Parallel bzip2 support for faster backup, requires "real" tar (busybox does not work)
IMAGE_INSTALL += "pbzip2 tar"

IMAGE_INSTALL += "openssl-bin"
IMAGE_INSTALL += "packagegroup-hilscher-base"
IMAGE_INSTALL += "firewalld"

# netFIELD Specific stuff
IMAGE_INSTALL += "docker iotedge docker-compose"
IMAGE_INSTALL += "opa-docker-authz"

# Package management to /opt/apps
#IMAGE_INSTALL += "opkg"

# newer kernels block in early boot phase as random number generator is not yet fully initialized (CVE-2018-1108)
# rng-tools uses HW random generator whenever possible
IMAGE_INSTALL += "rng-tools"

# Administration tools
IMAGE_INSTALL += "cockpit cockpit-onboarding cockpit-docker cockpit-iotedge-docker cockpit-general-settings cockpit-terminal cockpit-branding-default"
IMAGE_INSTALL += "sudo"

# Tools / Addons
IMAGE_INSTALL += "tree"
IMAGE_INSTALL += "ca-certificates"
IMAGE_INSTALL += "rfkill"
IMAGE_INSTALL += "less"
# several tools like blkid,hexdump...
IMAGE_INSTALL += "util-linux"

IMAGE_INSTALL += "machine-state"

do_install_manifest() {
   # Real firmware version is provided by meta-hilscher-distro
   ln -s firmware.version ${IMAGE_ROOTFS}/fw_version
}
ROOTFS_POSTUNINSTALL_COMMAND:append = " do_install_manifest ;"

# Setup initial passwords
inherit extrausers
EXTRA_USERS_PARAMS += "usermod -s /sbin/nologin root;"
EXTRA_USERS_PARAMS += "groupadd -g 1000 admin;"
EXTRA_USERS_PARAMS += "useradd -c 'System Administrator' -u 1000 -p '$(openssl passwd admin)' -G sudo,docker -s /bin/zsh admin;"

# Make sure to not set PermitEmptyPasswords in sshd_config, which does not work with pam_abl
ssh_allow_empty_password () {
  :
}

do_force_admin_pw_change() {
  tmp1=$(cat ${IMAGE_ROOTFS}${sysconfdir}/shadow | grep "^admin" | cut -d ':' -f1-2)
  tmp2=$(cat ${IMAGE_ROOTFS}${sysconfdir}/shadow | grep "^admin" | cut -d ':' -f4-)
  sed -i -e "s@^admin:.*@$tmp1:0:$tmp2@" ${IMAGE_ROOTFS}${sysconfdir}/shadow
}

do_create_homes() {
  install -d -o 1000 -m 0700 ${IMAGE_ROOTFS}/home/admin
  touch ${IMAGE_ROOTFS}/home/admin/.zshrc
  chown 1000 ${IMAGE_ROOTFS}/home/admin/.zshrc
  chmod 0600 ${IMAGE_ROOTFS}/home/admin/.zshrc
}

do_create_audit_privileged_rules() {
  rule_file="${IMAGE_ROOTFS}/${datadir}/audit/sample-rules/31-privileged.rules"

  # Only create audit rules if audit sample file is installed.
  # It is usually filled by user and only contains comments how to generate it
  if [ -e "$rule_file" ]; then
    rm $rule_file
    for priv_dir in /bin /sbin /usr/bin /usr/sbin; do
      find ${IMAGE_ROOTFS}$priv_dir -type f -perm -04000 2>/dev/null | \
          sed "s@${IMAGE_ROOTFS}@@" | \
          awk '{ printf "-a always,exit -F path=%s -F perm=x -F auid>=1000 -F auid!=unset -F key=privileged\n", $1 }' >> $rule_file
    done

    for priv_dir in /bin /sbin /usr/bin /usr/sbin; do
      filecap ${IMAGE_ROOTFS}$priv_dir 2>/dev/null | \
          sed '1d' | sed "s@${IMAGE_ROOTFS}@@" | \
          awk '{ printf "-a always,exit -F path=%s -F perm=x -F auid>=1000 -F auid!=unset -F key=privileged\n", $2 }' >> $rule_file
    done
  fi
}

ROOTFS_POSTUNINSTALL_COMMAND:append = " do_create_homes ; do_force_admin_pw_change ;"
ROOTFS_POSTUNINSTALL_COMMAND:append = " ${@bb.utils.contains('DISTRO_FEATURES', 'audit', 'do_create_audit_privileged_rules ;', '', d)}"
