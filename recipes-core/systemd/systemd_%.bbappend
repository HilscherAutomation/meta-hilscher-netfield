FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN}:append = " systemd-machine-units"

SRC_URI:append = " file://disable_predictable_network_names.patch \
    file://pass_unit_name_on_enable_disable.patch \
    file://allow_readlog_for_netadmin.patch \
"

# Default servers to add to initial configuration
EXTRA_OEMESON:append = " -Dntp-servers='0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org'"

PACKAGECONFIG:append = " ${@bb.utils.contains('DISTRO_FEATURES', 'apparmor', 'apparmor', '', d)}"
PACKAGECONFIG[apparmor] = "-Dapparmor=true,-Dapparmor=false,apparmor"
PACKAGECONFIG:append = " seccomp audit"
PACKAGECONFIG:append = " journal-upload"
PACKAGECONFIG:remove = "networkd"

# Use cgroups v2 per default
PACKAGECONFIG:append = " cgroupv2"

# Make sure journal-upload is not automatically started, as it requires a configuration
SYSTEMD_PACKAGES:remove = "${PN}-journal-upload"
SYSTEMD_SERVICE:${PN}-journal-upload = ""

inherit useradd
GROUPADD_PARAM:${PN}:append = ";-r -g 65533 nobody; -r wheel; -r kvm; -r render;"

do_install:append() {
    # Make journald capture /dev/log (syslog), which does not work if /dev/log is already existing
    sed -i -e 's@\[Socket\]@\[Socket\]\nExecStartPre=-/bin/rm -f /dev/log@g' ${D}${systemd_system_unitdir}/systemd-journald-dev-log.socket

    # Make sure journald exits before unmounting /var/log (as it holds a lock on /var/log/journald)
    sed -i -e 's@\(^DefaultDependencies=.*\)@\1\nRequiresMountsFor=/var/log@' ${D}${systemd_system_unitdir}/systemd-journald.service

    # Make sure udevd exists before unmouning /etc (as it holds a lock on /etc/hwdb.bin)
    sed -i -e 's@\(^DefaultDependencies=.*\)@\1\nRequiresMountsFor=/etc@' ${D}${systemd_system_unitdir}/systemd-udevd.service

    sed -i -e 's@#RuntimeMaxUse.*@RuntimeMaxUse=32M@g' ${D}${sysconfdir}/systemd/journald.conf
    sed -i -e 's@#RuntimeMaxFileSize.*@RuntimeMaxFileSize=8M@g' ${D}${sysconfdir}/systemd/journald.conf
    sed -i -e 's@#RuntimeMaxFiles.*@RuntimeMaxFiles=3@g' ${D}${sysconfdir}/systemd/journald.conf
    sed -i -e 's@#SystemMaxUse.*@SystemMaxUse=64M@g' ${D}${sysconfdir}/systemd/journald.conf

    # Make sure to always use systemd-timesyncd for ntp, otherwise cockpit does not work
    sed -i -e 's/\[Service\]/\[Service\]\nEnvironment="SYSTEMD_TIMEDATED_NTP_SERVICES=systemd-timesyncd.service"/g' \
              ${D}${systemd_system_unitdir}/systemd-timedated.service

    # Make sure vital services are not oom-killed
    for service in getty@.service console-getty.service container-getty@.service systemd-logind.service; do
        sed -i -e 's/\[Service\]/\[Service\]\nOOMScoreAdjust=-1000/g' \
              ${D}${systemd_system_unitdir}/$service
    done
}

# Don't rebuilt if os-release changes
RRECOMMMENDS:${PN}:remove = "os-release"
