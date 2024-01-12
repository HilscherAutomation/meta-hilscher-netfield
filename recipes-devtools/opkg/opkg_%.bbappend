PACKAGECONFIG:append = " sha256"

OPKG_BASE_PATH ?= "/opt/apps"
OPKGLIBDIR      = "${OPKG_BASE_PATH}/lib"

do_install:append:class-target() {
    # Install to /opt/apps per default
    sed -i -e 's@dest root.*@dest root ${OPKG_BASE_PATH}@' ${D}${sysconfdir}/opkg/opkg.conf

    # Make sure our application path is included for libraries and applications
    install -d ${D}${sysconfdir}/profile.d
    cat <<EOF>${D}${sysconfdir}/profile.d/okpg.sh
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${OPKG_BASE_PATH}/usr/lib:${OPKG_BASE_PATH}/lib
export PATH=\$PATH:${OPKG_BASE_PATH}/usr/bin:${OPKG_BASE_PATH}/usr/sbin:${OPKG_BASE_PATH}/bin:${OPKG_BASE_PATH}/sbin
EOF
}
