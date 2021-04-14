SUMMARY = "netANALYZER stand-alone application for Hilscher netANALYZER devices"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

inherit autotools

SRC_URI = "svn://subversion01.hilscher.local/svn/Netzwerkanalyse/StandAlone/tags/;module=${PV};protocol=https;user=${HILSCHER_SVN_USER};pswd=${HILSCHER_SVN_PSWD} \
           file://${BPN}.service"
SRCREV="10076"

S = "${WORKDIR}/${PV}"

EXTRA_OECONF +="--enable-nocgos"
EXTRA_OECONF +="--enable-iotgw"

DEPENDS="libnetana"
RDEPENDS_${PN} = "libnetana (>= 1.0.4.0) \
                  zip unzip \
                  nasa-msg-sink-mod \
                  nasa-backend (>= 1.10.0.0) \
                  nasa-decoder-ethercat (>= 2.6.0.0) \
                  nasa-decoder-profinet (>= 2.7.0.0) \
                  nasa-frame-dec-mod (>= 1.9.0.0) \
                  nasa-eip-dec-mod (>= 3.1.0.0) \
                  nasa-gpio-dec-mod (>= 1.1.0.0) \
                  nasa-pcap-conv-mod (>= 2.3.0.0) \
                  nasa-quicktester-mod (>= 1.2.0.0) \
                  nasa-rate-mod (>= 1.2.0.0) \
                  nasa-ringbuffer (>= 2.12.0.0) \
                  nasa-timing-mod (>= 1.2.0.0) \
                  nasa-trigger-mod (>= 2.2.0.0) \
                  nasa-val-dec-mod (>= 1.1.0.0)"

do_install() {
    install -d ${D}/opt/nasa/standalone/
    install ${B}/StandAlone ${D}/opt/nasa/standalone/
    install ${B}/reset_backend_modules.json ${D}/opt/nasa/standalone/
    install ${B}/standalone_internal_cfg.json ${D}/opt/nasa/standalone/standalone_internal_cfg.json
    install ${B}/patchiotgwcfg.json ${D}/opt/nasa/standalone/
    install ${B}/SnapshotTemplate.nsprj ${D}/opt/nasa/standalone/

    # configu place
    install -d ${D}/opt/nasa/config/fbcfg/

    # register service
    if [ "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd', '', d)}" = "systemd" ]; then
        install -d ${D}${systemd_unitdir}/system/
        install -m 0644 ${WORKDIR}/nasa-standalone.service ${D}${systemd_unitdir}/system/

        # Exchange base directory in scripts (not implemented)
        #sed -i -e 's,@NASA_BASEDIR@,${NASA_BASEDIR},g' \
        #    ${D}${systemd_unitdir}/system/nasa-standalone.service
    fi
}

inherit systemd
SYSTEMD_SERVICE_${PN} = "${PN}.service"
SYSTEMD_AUTO_ENABLE = "disable"

FILES_${PN}="/opt/nasa/standalone \ 
             /opt/nasa/config \ 
             /opt/nasa/config/fbcfg"
