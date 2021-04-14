FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append += "file://firewalld.conf       \
                   file://zones/default.xml    \
                   file://zones/drop.xml       \
                   file://zones/block.xml      \
                   file://zones/trusted.xml    \
                   file://zones/nat_drop.xml   \
                   file://zones/nat_trusted.xml\
                   file://disable_logfile.patch\
                   file://0001-This-patch-adds-all-enabled-input-ports-into-FWDI_-z.patch \
                   file://firewalld_setup_docker \
"

do_install_append() {
    install -m 0644 ${WORKDIR}/firewalld.conf ${D}${sysconfdir}/firewalld

    rm -f ${D}${nonarch_libdir}/firewalld/zones/*
    cp ${WORKDIR}/zones/* ${D}${nonarch_libdir}/firewalld/zones/

    # Setup direct docker chains
    install -d ${D}${sbindir}
    install ${WORKDIR}/firewalld_setup_docker ${D}${sbindir}/firewalld_setup_docker
    sed -e 's@\(ExecStart=.*\)@\1\nExecStartPre=/usr/sbin/firewalld_setup_docker@g' -i ${D}${systemd_system_unitdir}/firewalld.service
}
