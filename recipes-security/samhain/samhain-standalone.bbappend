FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append += "file://samhainrc \
                   file://samhain_check_init \
                   file://samhain_update"

DEPENDS_append += "audit"

# path to samhain data base
DATABASE = "/var/lib/samhain/samhain_file"

# this file keeps the list (one each line) of files which need to be updated after reboot by default 
# maybe filled during runtime
UPDATE_FILE = "/etc/samhain_update"

do_compile_prepend() {
    cp ${WORKDIR}/samhainrc ${S}/samhainrc.linux
}

do_install_prepend() {
    mkdir -p ${D}/etc/
    install -m 764 ${WORKDIR}/samhain_check_init ${D}/etc/
    sed -i -e 's,@DATABASE_PATH@,${DATABASE},'  \
           -e 's,@UPDATE_FILE@,${UPDATE_FILE},' \
                               ${D}/etc/samhain_check_init

    install -m 640 -o root ${WORKDIR}/samhain_update ${D}/${UPDATE_FILE}

    mkdir -p ${D}${systemd_system_unitdir}/
    install ${WORKDIR}/samhain-init.service ${D}${systemd_system_unitdir}/
}

FILES_${PN} += "${systemd_system_unitdir}/samhain-init.service"
FILES_${PN} += "/etc/samhain_check_init"
FILES_${PN} += "${UPDATE_FILE}"
