FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://pam_abl.c;beginline=1;endline=18;md5=ea2bb433f2e547ec8ab4b1a832437107"

# NOTE: currently we use an archive from https://sourceforge.net/projects/pam-abl/. This is the
#       only version which seems to work correctly. Using the origin source from
#       https://github.com/deksai/pam_abl failed since versioning and source diverges more and less
#       in a way that it was impossible to find a (cross-)reference point.
SRC_URI = "file://pam-abl-${PV}.tar.gz;subdir=${BPN}-${PV} \
           file://pam_abl.conf \
           file://add_block_time_stamp.patch"

S = "${WORKDIR}/${PN}-${PV}"

inherit cmake

DEPENDS = "libpam db"

# set prefix to root otherwise all modules need to know user path
EXTRA_OECMAKE = "-DUSE_KC=off -DCMAKE_INSTALL_PREFIX=/"

do_install:append() {
	install -d "${D}/${sysconfdir}/security/"
	install -m 0744 "${WORKDIR}/pam_abl.conf" "${D}/${sysconfdir}/security"

	# db folder for runtime data
	install -d "${D}/${localstatedir}/lib/abl/"
}

FILES:${PN} = "${base_libdir}/* \
               ${base_bindir}/* \
               ${sysconfdir}/* \
               ${localstatedir}/lib/abl/"
