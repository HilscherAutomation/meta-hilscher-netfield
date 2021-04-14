SUMMARY = "netANALYZER backend library for netLOGGER"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

SRC_URI = "file://nasa-enable-cfg-mode \
           file://nasa-enable-op-mode \
           file://nasa-enable-docker-mode \
           file://nasa-get-mode \
           file://nasa-passive-mode \
           file://nasa-gen-op-mode-usecases \
           file://nasa-mode.conf \
           file://nasa-state-info.conf \
           file://standalone-args"

S = "${WORKDIR}"

DEST_DIR="/opt/nasa/scripts/"

do_install() {
    install -d ${D}/opt/nasa/scripts
    install ${S}/nasa-enable-cfg-mode ${D}${DEST_DIR}
    install ${S}/nasa-enable-op-mode ${D}${DEST_DIR}
    install ${S}/nasa-enable-docker-mode ${D}${DEST_DIR}
    install ${S}/nasa-get-mode ${D}${DEST_DIR}
    install ${S}/nasa-passive-mode ${D}${DEST_DIR}
    install ${S}/nasa-gen-op-mode-usecases ${D}${DEST_DIR}

    # config files 
    install -d ${D}/opt/nasa/config/operation-settings
    install ${S}/nasa-mode.conf ${D}/opt/nasa/config/operation-settings/
    install ${S}/standalone-args ${D}/opt/nasa/config/operation-settings/
    install ${S}/nasa-state-info.conf ${D}/opt/nasa/config/operation-settings/
}

RDEPENDS_${PN} = "nasa-standalone"

CONFFILES_${PN} += "${D}/opt/nasa/config/operation-settings/nasa-mode.conf"
CONFFILES_${PN} += "${D}/opt/nasa/config/operation-settings/standalone-args"
CONFFILES_${PN} += "${D}/opt/nasa/config/operation-settings/nasa-state-info.conf"

FILES_${PN} = "${DEST_DIR} \
               /opt/nasa/config/operation-settings/"
