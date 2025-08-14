DESCRIPTION = "Cockpit is a web-based graphical interface for servers, enabling administrators to manage and control their Linux systems. This includes setting network configurations, managing users, monitoring system performance, updating software, and more. Cockpit plugins extend the functionality of Cockpit, providing additional features and capabilities."

LICENSE = "CLOSED"

S = "${WORKDIR}"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

FILES:${PN} = "${datadir}/cockpit"

do_install() {
    install -dm755 ${D}${datadir}/cockpit

    for extension in "${EXTENSIONS}"; do
        cp -r ${WORKDIR}/${extension} ${D}${datadir}/cockpit/
    done
}

