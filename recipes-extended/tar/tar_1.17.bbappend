FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://tar-1.17-wildcards.patch \
                   file://tar-1.17-xattrs.patch \
                   file://CVE-2010-0624.patch \
                   file://CVE-2016-6321.patch \
                   file://CVE-2018-20482.patch \
                   file://CVE-2019-9923.patch \
                   file://ommit_timestamp_in_future.patch \
                   file://tar-1.22-fortifysourcessigabrt.patch \
                   file://tar-1.17-xattrs-restore.patch \
                   file://tar-1.17-acl-restore.patch \
    "

DEPENDS:append =" ${@bb.utils.contains('DISTRO_FEATURES', 'acl', 'acl', '', d)} "

PR="r4"
