DESCRIPTION = "Cockpit is a web-based graphical interface for servers, enabling administrators to manage and control their Linux systems. This includes setting network configurations, managing users, monitoring system performance, updating software, and more. Cockpit plugins extend the functionality of Cockpit, providing additional features and capabilities."

LICENSE = "CLOSED"

SRC_URI = " \
    file://${BPN}_${PV}.tar.gz \
"
SRC_URI[sha256sum] = "64a437c8e1c4ed32d36426f90c4752d36ee2ab5286b19c8f4b01f0c7c880b21e"

S = "${WORKDIR}"

EXTENSIONS = "certificate docker generalSettings iotedge-docker networkservices onboard swupdate"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

FILES:${PN} = "${datadir}/cockpit"

do_install() {
    install -dm755 ${D}${datadir}/cockpit

    for extension in "${EXTENSIONS}"; do
        cp -r ${WORKDIR}/${extension} ${D}${datadir}/cockpit/
    done
}
