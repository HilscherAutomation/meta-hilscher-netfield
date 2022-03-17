FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append += "file://enable_applets.cfg      \
                   file://enable_archivers.cfg    \
                   file://enable_diskhandling.cfg \
                   file://enable_hashes.cfg       \
                   file://enable_syslogd.cfg      \
                   file://enable_userhandling.cfg \
                   file://enable_verbose_usage.cfg  \
                   file://enable_tftp_blocksize.cfg \
                   file://enable_netcat110_support.cfg \
                   file://enable_wget_openssl.cfg \
"

# Make sure syslogd / klogd do not start automatically, we are relying on journald
SYSTEMD_AUTO_ENABLE = "disable"
