FILESEXTRAPATHS_prepend := "${THISDIR}/${BPN}:"

# NOTE: libpam requires the pam-abl dependency since the configuration file common-auth of libpam
#       package refers pam-abl. Otherwise login will fail since authentication is not posssible.
RDEPENDS_${PN} += " pam-abl "
