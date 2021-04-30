inherit python3targetconfig

SYSTEMD_AUTO_ENABLE = "enable"

# xargs -d is used in scripts, thus we need full xargs not the busybox ones
# getconf is used in scripts thus we need libc6-utils
RDEPENDS_${PN}_append += "findutils glibc-utils"

do_install_append() {
    #
    # Some apparmor profiles don't match yocto filesystem layout, so adjust them here
    #
    # samba (logfiles may reside in /var/volatile/log instead of /var/log
    sed -i 's/\/var\/log\//\/var\/\{,volatile\/\}log\//' ${D}${sysconfdir}/apparmor.d/abstractions/samba
    # Allow logrotating (read from log)
    sed -i 's/\(log\.\*\s\+\)w,/\1rw,/' ${D}${sysconfdir}/apparmor.d/abstractions/samba

    # nmbd (pid file cannot be created under /run)
    echo "/run/nmbd.pid rwk," >> ${D}${sysconfdir}/apparmor.d/local/usr.sbin.nmbd

    # dnsmasq is installed in /usr/bin not /usr/sbin
    mv ${D}${sysconfdir}/apparmor.d/usr.sbin.dnsmasq ${D}${sysconfdir}/apparmor.d/usr.bin.dnsmasq
    mv ${D}${sysconfdir}/apparmor.d/local/usr.sbin.dnsmasq ${D}${sysconfdir}/apparmor.d/local/usr.bin.dnsmasq
    sed -i 's@<local/usr.sbin.dnsmasq>@<local/usr.bin.dnsmasq>@' ${D}${sysconfdir}/apparmor.d/usr.bin.dnsmasq
    sed -i 's/\/usr\/sbin\/dnsmasq/\/usr\/\bin\/dnsmasq/' ${D}${sysconfdir}/apparmor.d/usr.bin.dnsmasq

    echo "@{PROC}/@{pid}/fd/  r," >> ${D}${sysconfdir}/apparmor.d/local/usr.bin.dnsmasq
    echo "@{PROC}/@{pid}/fd/* r," >> ${D}${sysconfdir}/apparmor.d/local/usr.bin.dnsmasq

    # /usr/sbin/ntpd is a symlink to /usr/sbin/ntpd.ntp
    sed -i 's;/usr/sbin/ntpd;/usr/sbin/ntpd{,.ntp};' ${D}${sysconfdir}/apparmor.d/usr.sbin.ntpd

    # remove not required profiles (dovecot mailserver, apache2 webserver)
    rm ${D}${sysconfdir}/apparmor.d/*dovecot*
    rm ${D}${sysconfdir}/apparmor.d/local/*dovecot*

    rm -rf ${D}${sysconfdir}/apparmor.d/*apache2*
    rm ${D}${sysconfdir}/apparmor.d/local/*apache2*

    # syslog-ng brings it's own rules
    rm ${D}${sysconfdir}/apparmor.d/sbin.syslog-ng
    rm ${D}${sysconfdir}/apparmor.d/local/sbin.syslog-ng

    # we don't have perl binding, thus remove aa-notify/aa-exec script which requires perl
    rm ${D}${sbindir}/aa-notify

    # readonly rootfs requires attach_disconnected flags
    sed -i 's@\(^profile avahi-daemon.*\) {@\1 flags=(attach_disconnected) {@' ${D}${sysconfdir}/apparmor.d/usr.sbin.avahi-daemon

    # overlay of root results in process to use /rootfs mount (rw dir of overlay) in background, thus
    # apparmor is blocking access
    echo "alias / -> /rootfs/," >> ${D}/${sysconfdir}/apparmor.d/tunables/alias

    # Python is only included up to 3.6 but we are using 3.7, so patch rules
    sed -i -e 's;\[0-6\];\[0-7\];g' ${D}/${sysconfdir}/apparmor.d/abstractions/python

    # Enable caching per default
    sed -i -e 's/#write-cache/write-cache/g' ${D}/${sysconfdir}/apparmor/parser.conf
}
